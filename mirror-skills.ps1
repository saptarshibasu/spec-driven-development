#!/usr/bin/env pwsh
# mirror-skills.ps1 — Windows/PowerShell twin of mirror-skills.sh.
#
# Propagates canonical skills (.agents/skills) into the .claude, .github, and
# .codex mirror dirs (ADR-0001). Run after adding or editing a skill under
# .agents/skills/. Never hand-edit a mirror. See mirror-skills.sh for rationale.
#
# Usage:  pwsh ./mirror-skills.ps1   (or, on Windows PowerShell: powershell -File .\mirror-skills.ps1)

$ErrorActionPreference = 'Stop'

$root = (git rev-parse --show-toplevel 2>$null)
if (-not $root) { $root = (Get-Location).Path }
$canon = Join-Path $root '.agents/skills'

if (-not (Test-Path $canon) -or -not (Get-ChildItem $canon -Directory -ErrorAction SilentlyContinue)) {
  Write-Error "$canon is empty or missing - nothing to mirror. Copy this kit's .agents/skills/ in first."
}

foreach ($tool in @('.claude/skills', '.github/skills', '.codex/skills')) {
  $dest = Join-Path $root $tool
  New-Item -ItemType Directory -Force -Path $dest | Out-Null
  foreach ($skill in Get-ChildItem $canon -Directory) {
    $target = Join-Path $dest $skill.Name
    if (Test-Path $target) { Remove-Item -Recurse -Force $target }
    Copy-Item -Recurse -Force $skill.FullName $target
  }
}

$count = (Get-ChildItem $canon -Directory).Count
Write-Host "Mirrored $count skill(s) -> .claude, .github, .codex"
