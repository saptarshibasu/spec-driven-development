#!/usr/bin/env pwsh
# check-guardrails.ps1 — Windows/PowerShell twin of check-guardrails.sh.
#
# Drift sensor for the shared "Behavioral guardrails" block: compares the
# first three bullets of every .agents/agents/*.md and
# .agents/skills/*/SKILL.md "## Behavioral guardrails" section against the
# canonical GUARDRAILS:skill / GUARDRAILS:agent / GUARDRAILS:agent-readonly
# blocks delimited in docs/guardrails.md. See check-guardrails.sh for full
# rationale — both must agree on what counts as a match.
#
# Usage: pwsh ./scripts/check-guardrails.ps1

$ErrorActionPreference = 'Stop'

$root = (git rev-parse --show-toplevel 2>$null)
if (-not $root) { $root = (Get-Location).Path }
$canonDoc = Join-Path $root 'docs/guardrails.md'
$agentsDir = Join-Path $root '.agents/agents'
$skillsDir = Join-Path $root '.agents/skills'

if (-not (Test-Path $canonDoc)) {
  Write-Error "$canonDoc not found - nothing to check against."
}

function Get-CanonBlock([string]$variant) {
  $start = "<!-- GUARDRAILS:$variant -->"
  $end = "<!-- /GUARDRAILS:$variant -->"
  $lines = Get-Content $canonDoc
  $out = New-Object System.Collections.Generic.List[string]
  $in = $false
  foreach ($line in $lines) {
    if ($line -eq $end) { $in = $false; continue }
    if ($in) { $out.Add($line) }
    if ($line -eq $start) { $in = $true }
  }
  return $out
}

$variants = @('skill', 'agent', 'agent-readonly')
$canon = @{}
foreach ($v in $variants) {
  $block = Get-CanonBlock $v
  if ($block.Count -eq 0) {
    Write-Error "docs/guardrails.md has no (or an empty) GUARDRAILS:$v block."
  }
  $canon[$v] = $block
}

function Get-GuardrailSection([string]$file) {
  $lines = Get-Content $file
  $inSec = $false
  $bullets = 0
  $collected = New-Object System.Collections.Generic.List[string]
  foreach ($line in $lines) {
    if ($line -match '^## Behavioral guardrails') { $inSec = $true; continue }
    if ($inSec -and $line -match '^## ') { break }
    if ($inSec) {
      if ($line -match '^- \*\*') { $bullets++ }
      if ($bullets -gt 3) { break }
      if ($bullets -ge 1) { $collected.Add($line) }
    }
  }
  while ($collected.Count -gt 0 -and $collected[$collected.Count - 1].Trim() -eq '') {
    $collected.RemoveAt($collected.Count - 1)
  }
  return $collected
}

function Get-AgentTools([string]$file) {
  $lines = Get-Content $file
  $dashCount = 0
  foreach ($line in $lines) {
    if ($line -match '^---\s*$') {
      $dashCount++
      continue
    }
    if ($dashCount -eq 1 -and $line -match '^tools:\s*(.*)$') {
      return $Matches[1].Trim()
    }
  }
  return ''
}

$fail = $false

function Test-GuardrailFile([string]$file, [string]$variant, [string]$root) {
  $rel = $file.Substring($root.Length + 1)
  $content = Get-Content $file -Raw
  if ($content -notmatch '## Behavioral guardrails') {
    Write-Host "::error::$rel has no '## Behavioral guardrails' section."
    return $true
  }
  $got = Get-GuardrailSection $file
  $expected = $script:canon[$variant]
  if (($got -join "`n") -ne ($expected -join "`n")) {
    Write-Host "::error::$rel guardrails section doesn't match the canonical '$variant' block in docs/guardrails.md:"
    Write-Host "--- expected ($variant) ---"
    $expected | ForEach-Object { Write-Host $_ }
    Write-Host "--- got ---"
    $got | ForEach-Object { Write-Host $_ }
    return $true
  }
  return $false
}

Get-ChildItem (Join-Path $agentsDir '*.md') | ForEach-Object {
  $tools = Get-AgentTools $_.FullName
  $variant = if ($tools -match 'Write|Edit') { 'agent' } else { 'agent-readonly' }
  if (Test-GuardrailFile $_.FullName $variant $root) { $fail = $true }
}

Get-ChildItem (Join-Path $skillsDir '*/SKILL.md') | ForEach-Object {
  if (Test-GuardrailFile $_.FullName 'skill' $root) { $fail = $true }
}

if ($fail) {
  Write-Host "::error::Guardrail drift detected. Update docs/guardrails.md's canonical GUARDRAILS block first, then copy the exact wording into every file listed above (see docs/guardrails.md section Maintenance)."
  exit 1
}

Write-Host "All agent/skill guardrail sections match their canonical docs/guardrails.md block."
