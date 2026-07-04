#!/usr/bin/env pwsh
# update-kit.ps1 - Windows/PowerShell twin of scripts/update-kit.sh.
#
# Pulls kit-owned changes from a newer kit checkout into this project without
# touching project-owned paths. See docs/KIT-MANIFEST.md (ADR-0007) for what
# "kit-owned" means. Keep this in lockstep with update-kit.sh - same
# KIT:BEGIN/KIT:END merge semantics. Neither script hand-maintains the
# kit-owned path list any more: both read it from .agents/kit-manifest.conf
# in the SOURCE checkout at run time, so a data edit can't introduce
# divergence between the two, and docs/KIT-MANIFEST.md's prose table is
# checked against the same conf file in CI.
#
# Atomicity: every partially kit-owned file (any `partial=` entry in
# kit-manifest.conf - none ship by default) has its KIT:BEGIN/KIT:END marker
# pair validated (both this project's copy and the source's copy) before
# step 1 writes anything at all - a corrupted marker aborts up front with
# nothing changed on disk. See update-kit.sh for the fuller rationale,
# including why .githooks/pre-commit(.ps1) and agent-harness.yml are no
# longer tracked here.
#
# Downgrade guard: KIT_VERSION is compared as semver (major.minor.patch), not
# string inequality - pointing this at an older kit checkout is refused
# unless -Force is passed.
#
# Usage:
#   pwsh scripts/update-kit.ps1 <path-to-newer-kit-checkout> [-DryRun] [-Yes] [-Force]

param(
  [Parameter(Mandatory = $true, Position = 0)]
  [string]$Source,

  [switch]$DryRun,
  [switch]$Yes,
  [switch]$Force
)

$ErrorActionPreference = 'Stop'

function Die($msg) { Write-Host "X $msg"; exit 1 }
function Info($msg) { Write-Host "  $msg" }
function Run([scriptblock]$block, [string]$label) {
  if ($DryRun) { Write-Host "  [dry-run] $label" }
  else { & $block }
}

$root = (git rev-parse --show-toplevel 2>$null)
if (-not $root) { $root = (Get-Location).Path }
Set-Location $root

if (-not (Test-Path $Source -PathType Container)) { Die "'$Source' is not a directory." }
$Source = (Resolve-Path $Source).Path

$srcVersionFile = Join-Path $Source 'KIT_VERSION'
if (-not (Test-Path $srcVersionFile)) { Die "'$Source' has no KIT_VERSION file - is it a kit checkout?" }
if (-not (Test-Path 'KIT_VERSION')) { Die "this project has no KIT_VERSION file yet. Copy '$srcVersionFile' in manually the first time (see docs/KIT-MANIFEST.md), then re-run." }

$curVersion = (Get-Content 'KIT_VERSION' -Raw).Trim()
$newVersion = (Get-Content $srcVersionFile -Raw).Trim()

if ($curVersion -eq $newVersion) {
  Write-Host "Already on kit version $curVersion - nothing to do."
  exit 0
}

# ── Semver comparison - refuse a silent downgrade ───────────────────────────
# Parses "MAJOR.MINOR.PATCH" (a leading 'v' and any -prerelease/+build suffix
# are tolerated and ignored); non-numeric components are treated as 0 rather
# than throwing, so a malformed KIT_VERSION fails safe rather than crashing
# the whole update.
function Get-VersionParts($v) {
  $v = $v -replace '^v', ''
  $v = ($v -split '[-+]')[0]
  $parts = $v -split '\.'
  $result = @(0, 0, 0)
  for ($i = 0; $i -lt 3; $i++) {
    if ($i -lt $parts.Length -and $parts[$i] -match '^\d+$') { $result[$i] = [int]$parts[$i] }
  }
  return $result
}

function Test-VersionLessThan($a, $b) {
  $pa = Get-VersionParts $a
  $pb = Get-VersionParts $b
  for ($i = 0; $i -lt 3; $i++) {
    if ($pa[$i] -ne $pb[$i]) { return $pa[$i] -lt $pb[$i] }
  }
  return $false
}

if (-not $Force -and (Test-VersionLessThan $newVersion $curVersion)) {
  Die "'$Source' is on kit version $newVersion, older than the installed $curVersion - refusing to downgrade. Pass -Force if this is intentional (e.g. deliberately reverting to a prior release)."
}

Write-Host "Updating kit: $curVersion -> $newVersion"
Write-Host "Source: $Source"
if ($DryRun) { Write-Host "(dry run - no files will be written)" }
Write-Host ''

# ── Kit-owned path lists live in data (.agents/kit-manifest.conf), not code
# - see that file for the format. Read from the SOURCE checkout: the newer
# kit version's manifest decides what this run pulls in, same as KIT_VERSION. ──
$kitManifestConf = Join-Path $Source '.agents/kit-manifest.conf'
if (-not (Test-Path $kitManifestConf)) { Die "$kitManifestConf not found - '$Source' predates the kit-manifest.conf convention, or isn't a kit checkout." }

$kitOwnedFiles = @()
$kitOwnedDirs = @()
$kitAdrDirs = @()
$kitPartialFiles = @()
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
    'partial' { $kitPartialFiles += $path }
    default   { Die "$kitManifestConf: unknown namespace '$ns' (expected file/dir/adr_dir/partial)" }
  }
}
# No assertion on $kitPartialFiles.Count - the partial= namespace is
# currently unused by default (see kit-manifest.conf's own note: a CI
# workflow isn't opt-in the way a git hook is, so .githooks/pre-commit(.ps1)
# and .github/workflows/agent-harness.yml were dropped from the manifest).
# An empty list just means the loops below do nothing.

# ── Validate every partially kit-owned marker pair BEFORE anything is
# written (see update-kit.sh for the rationale) ─────────────────────────────
function Test-KitMarkers($target, $source) {
  if (-not (Test-Path $source)) { return }
  if (-not (Test-Path $target)) { return }
  foreach ($f in @($target, $source)) {
    $lines = Get-Content $f
    $begins = ($lines | Select-String -Pattern 'KIT:BEGIN ===' -SimpleMatch:$false).Count
    $ends = ($lines | Select-String -Pattern 'KIT:END ===' -SimpleMatch:$false).Count
    if ($begins -ne 1 -or $ends -ne 1) {
      Die "$f: expected exactly one KIT:BEGIN/KIT:END marker pair, found $begins/$ends - resolve by hand (docs/KIT-MANIFEST.md), then re-run. Nothing has been written yet."
    }
  }
}

if ($kitPartialFiles.Count -gt 0) {
  Write-Host '-- Validating kit-owned markers (before writing anything)'
  foreach ($f in $kitPartialFiles) {
    Test-KitMarkers $f (Join-Path $Source $f)
  }
}

if (-not $Yes -and -not $DryRun) {
  $reply = Read-Host "This overwrites kit-owned paths (see docs/KIT-MANIFEST.md). Continue? [y/N]"
  if ($reply -notmatch '^(y|yes)$') { Write-Host 'Aborted.'; exit 1 }
}

function Copy-IfChanged($rel) {
  $src = Join-Path $Source $rel
  if (-not (Test-Path $src -PathType Leaf)) { return }
  $dstDir = Split-Path $rel -Parent
  if ($dstDir -and -not (Test-Path $dstDir)) { Run { New-Item -ItemType Directory -Force -Path $dstDir | Out-Null } "mkdir $dstDir" }
  if ((Test-Path $rel) -and ((Get-FileHash $src).Hash -eq (Get-FileHash $rel).Hash)) { return }
  Info $rel
  Run { Copy-Item -Force $src $rel } "cp $src $rel"
}

# ── 1. Whole-file kit-owned paths (added/updated) ───────────────────────────
Write-Host '-- Kit-owned files'
foreach ($f in $kitOwnedFiles) { Copy-IfChanged $f }

# ── 2. Whole-dir kit-owned paths (merge: add/update, never delete) ─────────
Write-Host '-- Kit-owned directories (add/update only, nothing deleted)'
foreach ($d in $kitOwnedDirs) {
  $srcDir = Join-Path $Source $d
  if (-not (Test-Path $srcDir -PathType Container)) { continue }
  Info "$d/"
  Run { New-Item -ItemType Directory -Force -Path $d | Out-Null } "mkdir $d"
  Run { Copy-Item -Recurse -Force -Path (Join-Path $srcDir '*') -Destination $d } "cp -R $srcDir/* $d"
}

# The kit's own ADRs: any ADR filename present in the source is kit-owned and
# gets added/updated by filename; project-authored ADR filenames are untouched.
foreach ($adrDir in $kitAdrDirs) {
  $srcAdr = Join-Path $Source $adrDir
  if (-not (Test-Path $srcAdr -PathType Container)) { continue }
  Write-Host "-- Kit's own ADRs ($adrDir/, matched by filename)"
  Run { New-Item -ItemType Directory -Force -Path $adrDir | Out-Null } "mkdir $adrDir"
  Get-ChildItem -Path $srcAdr -Filter '*.md' | ForEach-Object {
    Copy-IfChanged ("$adrDir/" + $_.Name)
  }
}

# ── 3. Partially kit-owned files: replace only the KIT:BEGIN..KIT:END block ─
# Markers were already validated (both sides) before step 1 ran, above - this
# re-check is just cheap defense against the files changing out from under us
# mid-run; it should never actually trigger.
function Merge-KitSection($target, $source) {
  if (-not (Test-Path $source)) { Info "(skip $target - not present in source)"; return }
  if (-not (Test-Path $target)) { Info "$target (new file from kit)"; Run { Copy-Item -Force $source $target } "cp $source $target"; return }

  foreach ($f in @($target, $source)) {
    $lines = Get-Content $f
    $begins = ($lines | Select-String -Pattern 'KIT:BEGIN ===' -SimpleMatch:$false).Count
    $ends = ($lines | Select-String -Pattern 'KIT:END ===' -SimpleMatch:$false).Count
    if ($begins -ne 1 -or $ends -ne 1) {
      Die "$f: expected exactly one KIT:BEGIN/KIT:END marker pair, found $begins/$ends - resolve by hand (docs/KIT-MANIFEST.md), then re-run."
    }
  }

  $targetLines = Get-Content $target
  $sourceLines = Get-Content $source

  $tBegin = ($targetLines | Select-String -Pattern 'KIT:BEGIN ===').LineNumber[0]
  $tEnd   = ($targetLines | Select-String -Pattern 'KIT:END ===').LineNumber[0]
  $sBegin = ($sourceLines | Select-String -Pattern 'KIT:BEGIN ===').LineNumber[0]
  $sEnd   = ($sourceLines | Select-String -Pattern 'KIT:END ===').LineNumber[0]

  $prefix = $targetLines[0..($tBegin - 1)]                 # through target's BEGIN line
  $middle = $sourceLines[($sBegin - 1)..($sEnd - 1)]        # source's BEGIN..END lines
  $suffix = if ($tEnd -lt $targetLines.Count) { $targetLines[$tEnd..($targetLines.Count - 1)] } else { @() }

  $merged = @($prefix + $middle + $suffix)
  $mergedText = ($merged -join "`n")
  $currentText = (Get-Content $target -Raw)
  if ($mergedText -eq $currentText.TrimEnd("`r", "`n")) { return }

  Info "$target (kit-owned section updated, your stack section preserved)"
  if (-not $DryRun) {
    Set-Content -Path $target -Value $merged -NoNewline:$false
  }
}

if ($kitPartialFiles.Count -gt 0) {
  Write-Host '-- Partially kit-owned hook/CI files'
  foreach ($f in $kitPartialFiles) {
    Merge-KitSection $f (Join-Path $Source $f)
  }
}

Write-Host ''
if ($DryRun) {
  Write-Host 'Dry run complete. Re-run without -DryRun to apply.'
  exit 0
}

# ── 4. Regenerate generated mirrors from the updated .agents/ ──────────────
Write-Host '-- Regenerating .claude/.github/.codex mirrors'
pwsh scripts/mirror-agents.ps1
pwsh scripts/mirror-skills.ps1

Write-Host ''
Write-Host "Kit updated: $curVersion -> $newVersion"
Write-Host 'Next steps:'
Write-Host '  1. Review the diff: git status; git diff'
Write-Host "  2. Read KIT-CHANGELOG.md's new entries for anything that needs manual follow-up"
Write-Host '     (e.g. a new required AGENTS.md section, a template field you should backfill).'
Write-Host '  3. Run your test suite, then commit.'
