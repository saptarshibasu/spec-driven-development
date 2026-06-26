#!/usr/bin/env pwsh
# mirror-agents.ps1 — Windows/PowerShell twin of mirror-agents.sh.
#
# Generates the per-tool agent file from each canonical definition in
# .agents/agents/<name>.md (YAML front-matter + Markdown body):
#   -> .claude/agents/<name>.md         Claude Code  (verbatim)
#   -> .github/agents/<name>.agent.md   Copilot      (name+description + body)
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
# Usage:  pwsh ./mirror-agents.ps1   (or: powershell -File .\mirror-agents.ps1)

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

  # 2) Copilot - name + description front-matter, then body.
  $copilot = "---`nname: $name`ndescription: $desc`n---`n$body"
  Set-Content -NoNewline -Path (Join-Path $copilotDir "$name.agent.md") -Value $copilot

  # 3) Codex - TOML table; tools mapped + de-duplicated; body as instructions.
  $codexTools = @()
  foreach ($t in ($tools -split ',')) {
    $t = $t.Trim(); if (-not $t) { continue }
    $ct = Convert-CodexTool $t
    if ($codexTools -notcontains $ct) { $codexTools += $ct }
  }
  $toolsCsv = ($codexTools | ForEach-Object { "`"$_`"" }) -join ', '
  $escDesc = $desc -replace '\\', '\\' -replace '"', '\"'
  $toml = @"
# Codex custom agent - generated from .agents/agents/$($src.Name) by mirror-agents.
# Do not hand-edit; edit the canonical .md and re-run the mirror (ADR-0001).

[agent]
name = "$name"
description = "$escDesc"
# Canonical model tier "$model" - set to your Codex model name.
model = "$model"
tools = [$toolsCsv]

instructions = $q3
$body$q3
"@
  Set-Content -NoNewline -Path (Join-Path $codexDir "$name.toml") -Value $toml
  $count++
}

Write-Host "Mirrored $count agent(s) -> .claude (.md), .github (.agent.md), .codex (.toml)"
