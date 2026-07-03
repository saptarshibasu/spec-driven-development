#!/usr/bin/env pwsh
# mirror-agents.ps1 — Windows/PowerShell twin of mirror-agents.sh.
#
# Generates the per-tool agent file from each canonical definition in
# .agents/agents/<name>.md (YAML front-matter + Markdown body):
#   -> .claude/agents/<name>.md         Claude Code  (verbatim)
#   -> .github/agents/<name>.agent.md   Copilot      (name+description+model + body)
#   -> .codex/agents/<name>.toml        Codex        ([agent] table + instructions)
#
# Run after adding or editing an agent under .agents/agents/. Never hand-edit a
# generated file. Edit the canonical .md only (ADR-0001). CI re-runs this and
# fails if the committed files drift from a fresh generation.
#
# Fails loudly (throws) rather than emitting a subtly-wrong file: unknown tool
# names, front-matter it can't parse as single-line scalars, or a body that would
# break the Codex TOML string are all hard errors. See mirror-agents.sh.
#
# Usage:  pwsh ./scripts/mirror-agents.ps1   (or: powershell -File .\scripts\mirror-agents.ps1)

$ErrorActionPreference = 'Stop'

$root = (git rev-parse --show-toplevel 2>$null)
if (-not $root) { $root = (Get-Location).Path }
$canon = Join-Path $root '.agents/agents'

$srcs = Get-ChildItem $canon -Filter '*.md' -ErrorAction SilentlyContinue
if (-not $srcs) { throw "$canon has no *.md agents - nothing to mirror." }

$claudeDir  = Join-Path $root '.claude/agents'
$copilotDir = Join-Path $root '.github/agents'
$codexDir   = Join-Path $root '.codex/agents'
foreach ($d in @($claudeDir, $copilotDir, $codexDir)) {
  New-Item -ItemType Directory -Force -Path $d | Out-Null
  Get-ChildItem $d -File | Where-Object { $_.Name -ne '.gitkeep' -and ($_.Extension -in '.md', '.toml') } |
    Remove-Item -Force
}

function Convert-CodexTool($t) {
  switch ($t) {
    'Read'  { 'read' }   'Grep'  { 'grep' }  'Glob' { 'grep' }
    'Bash'  { 'shell' }  'Edit'  { 'edit' }  'Write' { 'write' }
    # Unknown names are a hard error so a typo or a new tool can't pass through mis-mapped.
    default { throw "unknown tool '$t' (add it to Convert-CodexTool in mirror-agents.{sh,ps1})" }
  }
}

function Convert-CopilotModel($m) {
  # Copilot doesn't understand Claude Code's tier aliases (opus/sonnet); it wants
  # model-picker names, and accepts an array tried in order until an available
  # model is found - so entries your org hasn't enabled degrade gracefully.
  # EDIT the values below to match your org's enabled models
  # (https://docs.github.com/en/copilot/reference/ai-models/supported-models).
  # Keep in sync with copilot_model() in mirror-agents.sh.
  switch ($m) {
    'opus'   { "['Claude Opus 4.8', 'Claude Sonnet 5']" }
    'sonnet' { "['Claude Sonnet 5', 'Claude Sonnet 4.6']" }
    'haiku'  { "['Claude Haiku 4.5', 'Claude Sonnet 5']" }
    default  { throw "unknown model tier '$m' (add it to Convert-CopilotModel in mirror-agents.{sh,ps1})" }
  }
}

function Convert-CodexModel($m) {
  # Codex runs OpenAI models, so the tier's intent (strong reasoning vs fast
  # execution) maps to model choice + reasoning effort. EDIT to match the
  # models your Codex plan offers
  # (https://developers.openai.com/codex/config-reference). Keep in sync with
  # codex_model()/codex_effort() in mirror-agents.sh.
  switch ($m) {
    'opus'   { 'gpt-5.4' }
    'sonnet' { 'gpt-5.4' }
    'haiku'  { 'gpt-5.4-mini' }
    default  { throw "unknown model tier '$m' (add it to Convert-CodexModel in mirror-agents.{sh,ps1})" }
  }
}
function Convert-CodexEffort($m) {
  switch ($m) {
    'opus'   { 'high' }
    'sonnet' { 'medium' }
    'haiku'  { 'medium' }
    default  { throw "unknown model tier '$m' (add it to Convert-CodexEffort in mirror-agents.{sh,ps1})" }
  }
}

$q3 = "'''"
$count = 0
foreach ($src in $srcs) {
  $raw = Get-Content -Raw $src.FullName
  # Split front-matter (between the first two --- lines) from the body.
  if ($raw -notmatch '(?s)^---\r?\n(.*?)\r?\n---\r?\n(.*)$') {
    throw "$($src.Name) has no '---' front-matter block."
  }
  $fm = $Matches[1]; $body = $Matches[2]
  $fields = @{}
  foreach ($line in ($fm -split '\r?\n')) {
    if ($line -match '^\s*([A-Za-z_]+):\s*(.*?)\s*$') { $fields[$Matches[1]] = $Matches[2] }
  }
  $name = $fields['name']; $desc = $fields['description']
  $tools = $fields['tools']; $model = $fields['model']
  foreach ($k in 'name', 'description', 'tools', 'model') {
    if (-not $fields[$k]) { throw "$($src.Name): missing or empty '$k' (block-list YAML is unsupported - use 'tools: A, B')." }
  }
  if ($name -ne $src.BaseName) { throw "$($src.Name): front-matter name '$name' must match the filename." }
  if ($body.Contains($q3)) { throw "$($src.Name): body contains a triple single-quote, which would break the Codex TOML string." }

  # 1) Claude - verbatim copy.
  Copy-Item -Force $src.FullName (Join-Path $claudeDir "$name.md")

  # 2) Copilot - name + description + mapped model front-matter, then body.
  $copilot = "---`nname: $name`ndescription: $desc`nmodel: $(Convert-CopilotModel $model)`n---`n$body"
  Set-Content -NoNewline -Path (Join-Path $copilotDir "$name.agent.md") -Value $copilot

  # 3) Codex - TOML table; tools mapped + de-duplicated; body as instructions.
  $codexTools = @()
  foreach ($t in ($tools -split ',')) {
    $t = $t.Trim(); if (-not $t) { continue }
    $ct = Convert-CodexTool $t
    if ($codexTools -notcontains $ct) { $codexTools += $ct }
  }
  $toolsCsv = ($codexTools | ForEach-Object { "`"$_`"" }) -join ', '
  # YAML double-quoted scalar: strip the outer quotes - its \" and \\ escapes
  # are already valid TOML basic-string escapes, so the inner text passes
  # through verbatim. Plain (unquoted) scalar: escape it for TOML.
  if ($desc -match '^"(.*)"$') { $escDesc = $Matches[1] }
  else { $escDesc = $desc -replace '\\', '\\' -replace '"', '\"' }
  $toml = @"
# Codex custom agent - generated from .agents/agents/$($src.Name) by mirror-agents.
# Do not hand-edit; edit the canonical .md and re-run the mirror (ADR-0001).

[agent]
name = "$name"
description = "$escDesc"
# Mapped from canonical tier "$model" - adjust the tier mapping in scripts/mirror-agents.{sh,ps1}.
model = "$(Convert-CodexModel $model)"
model_reasoning_effort = "$(Convert-CodexEffort $model)"
tools = [$toolsCsv]

instructions = $q3
$body$q3
"@
  Set-Content -NoNewline -Path (Join-Path $codexDir "$name.toml") -Value $toml
  $count++
}

Write-Host "Mirrored $count agent(s) -> .claude (.md), .github (.agent.md), .codex (.toml)"
