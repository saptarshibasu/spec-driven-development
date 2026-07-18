#!/usr/bin/env pwsh
# update-kit.ps1 - Windows/PowerShell twin of scripts/update-kit.sh.
#
# Copies this kit's kit-owned files into a project. Run FROM this kit
# checkout (the script locates its own kit root); pass the target project's
# path as the argument. Keep this in lockstep with update-kit.sh - same
# copy semantics, same kit-owned path list. Neither script hand-maintains
# that list any more: both read it from .agents/kit-manifest.conf in THIS
# checkout at run time, so a data edit can't introduce divergence between
# the two.
#
# Most paths in the manifest (file=/dir=) are overwritten wholesale on every
# run. seed= paths are the exception: copied once, only if missing from the
# target, with no prompt - for org-owned data a project needs to run kit
# scripts but must be free to edit, like .agents/model-map.conf. Never
# overwritten once present, even if the kit's own copy changes upstream.
#
# There is no version tracking: this always copies the kit-owned paths as
# they stand in this checkout right now, skipping files whose content is
# already identical in the target. See update-kit.sh for the fuller
# rationale, including why this script, KIT_VERSION, and KIT-CHANGELOG.md
# are not themselves copied into a project.
#
# Usage (run from inside this kit checkout):
#   pwsh scripts/update-kit.ps1 <path-to-project> [-DryRun] [-Yes]

param(
  [Parameter(Mandatory = $true, Position = 0)]
  [string]$Dest,

  [switch]$DryRun,
  [switch]$Yes
)

$ErrorActionPreference = 'Stop'

function Die($msg) { Write-Host "X $msg"; exit 1 }
function Info($msg) { Write-Host "  $msg" }
function Run([scriptblock]$block, [string]$label) {
  if ($DryRun) { Write-Host "  [dry-run] $label" }
  else { & $block }
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$kitRoot = (Resolve-Path (Join-Path $scriptDir '..')).Path

if (-not (Test-Path $Dest -PathType Container)) { Die "'$Dest' is not a directory." }
$Dest = (Resolve-Path $Dest).Path
if ($kitRoot -eq $Dest) { Die "source and destination are the same directory ('$kitRoot') - pass the path to the project you want to copy the kit INTO, not the kit checkout itself." }

$kitManifestConf = Join-Path $kitRoot '.agents/kit-manifest.conf'
if (-not (Test-Path $kitManifestConf)) { Die "$kitManifestConf not found - is this script running from inside a kit checkout?" }

# Kit-owned path lists live in data (.agents/kit-manifest.conf), not code -
# see that file for the format.
$kitOwnedFiles = @()
$kitOwnedDirs = @()
$kitAdrDirs = @()
$kitSeedFiles = @()
foreach ($line in (Get-Content $kitManifestConf)) {
  $trimmed = $line.Trim()
  if (-not $trimmed -or $trimmed.StartsWith('#')) { continue }
  $parts = $trimmed.Split('=', 2)
  if ($parts.Length -ne 2) { continue }
  $ns = $parts[0].Trim()
  $path = $parts[1].Trim()
  if (-not $path) { continue }
  switch ($ns) {
    'file'    { $kitOwnedFiles += $path }
    'dir'     { $kitOwnedDirs += $path }
    'adr_dir' { $kitAdrDirs += $path }
    'seed'    { $kitSeedFiles += $path }
    default   { Die "${kitManifestConf}: unknown namespace '$ns' (expected file/dir/adr_dir/seed)" }
  }
}

Write-Host 'Copying kit-owned files'
Write-Host "  Kit checkout: $kitRoot"
Write-Host "  Target project: $Dest"
if ($DryRun) { Write-Host '(dry run - no files will be written)' }
Write-Host ''

if (-not $Yes -and -not $DryRun) {
  $reply = Read-Host "This overwrites kit-owned paths in '$Dest'. Continue? [y/N]"
  if ($reply -notmatch '^(y|yes)$') { Write-Host 'Aborted.'; exit 1 }
}

function Copy-IfChanged($rel) {
  $src = Join-Path $kitRoot $rel
  if (-not (Test-Path $src -PathType Leaf)) { return }
  $dst = Join-Path $Dest $rel
  $dstDir = Split-Path $dst -Parent
  if ($dstDir -and -not (Test-Path $dstDir)) { Run { New-Item -ItemType Directory -Force -Path $dstDir | Out-Null } "mkdir $dstDir" }
  if ((Test-Path $dst) -and ((Get-FileHash $src).Hash -eq (Get-FileHash $dst).Hash)) { return }
  Info $rel
  Run { Copy-Item -Force $src $dst } "cp $src $dst"
}

Write-Host '-- Kit-owned files'
foreach ($f in $kitOwnedFiles) { Copy-IfChanged $f }

Write-Host '-- Kit-owned directories (add/update only, nothing deleted)'
foreach ($d in $kitOwnedDirs) {
  $srcDir = Join-Path $kitRoot $d
  if (-not (Test-Path $srcDir -PathType Container)) { continue }
  $dstDir = Join-Path $Dest $d
  Info "$d/"
  Run { New-Item -ItemType Directory -Force -Path $dstDir | Out-Null } "mkdir $dstDir"
  Run { Copy-Item -Recurse -Force -Path (Join-Path $srcDir '*') -Destination $dstDir } "cp -R $srcDir/* $dstDir"
}

# The kit's own ADRs: any ADR filename present in the source is kit-owned and
# gets added/updated by filename; project-authored ADR filenames are untouched.
foreach ($adrDir in $kitAdrDirs) {
  $srcAdr = Join-Path $kitRoot $adrDir
  if (-not (Test-Path $srcAdr -PathType Container)) { continue }
  Write-Host "-- Kit's own ADRs ($adrDir/, matched by filename)"
  $dstAdr = Join-Path $Dest $adrDir
  Run { New-Item -ItemType Directory -Force -Path $dstAdr | Out-Null } "mkdir $dstAdr"
  Get-ChildItem -Path $srcAdr -Filter '*.md' | ForEach-Object {
    Copy-IfChanged ("$adrDir/" + $_.Name)
  }
}

Write-Host '-- Seed files (copied only if missing in the target, never overwritten)'
foreach ($f in $kitSeedFiles) {
  $src = Join-Path $kitRoot $f
  if (-not (Test-Path $src -PathType Leaf)) { continue }
  $dst = Join-Path $Dest $f
  if (Test-Path $dst) { continue }
  Info "$f (seeded)"
  $dstDir = Split-Path $dst -Parent
  Run { New-Item -ItemType Directory -Force -Path $dstDir | Out-Null } "mkdir $dstDir"
  Run { Copy-Item -Force $src $dst } "cp $src $dst"
}

Write-Host ''
if ($DryRun) {
  Write-Host 'Dry run complete. Re-run without -DryRun to apply.'
  exit 0
}

Write-Host '-- Regenerating .claude/.github/.codex mirrors in the target project'
Push-Location $Dest
try {
  pwsh scripts/mirror-agents.ps1
  pwsh scripts/mirror-skills.ps1
} finally {
  Pop-Location
}

Write-Host ''
Write-Host "Kit files copied into: $Dest"
Write-Host 'Next steps:'
Write-Host "  1. Review the diff: git -C '$Dest' status; git -C '$Dest' diff"
Write-Host "  2. Read this kit checkout's KIT-CHANGELOG.md for anything that needs"
Write-Host '     manual follow-up (e.g. a new required AGENTS.md section, a'
Write-Host '     template field you should backfill).'
Write-Host "  3. Run the project's test suite, then commit."
