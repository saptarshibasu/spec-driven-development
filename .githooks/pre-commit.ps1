#!/usr/bin/env pwsh
# pre-commit.ps1 - Windows/PowerShell twin of the .githooks/pre-commit hook.
#
# Git for Windows runs the POSIX `pre-commit` hook through its bundled bash, so
# that file already works on Windows if Git Bash is present. This PowerShell
# equivalent is for setups that prefer a native hook (no Git Bash, or a
# PowerShell-based hook manager): point a one-line `.githooks/pre-commit` wrapper
# at it, or invoke it from your hook runner. Keep the two checks in sync.
# See docs/harness-engineering.md and docs/hooks.md.
#
# Everything between the KIT:BEGIN/KIT:END markers is kit-owned: `update-kit.ps1`
# replaces that block verbatim on update and leaves everything outside it
# (section 4) alone. See docs/KIT-MANIFEST.md. Don't remove or reorder the
# markers, and don't add stack-specific checks above KIT:END.

$ErrorActionPreference = 'Stop'
$fail = $false
$staged = @(git diff --cached --name-only --diff-filter=ACM) | Where-Object { $_ }

# === KIT:BEGIN ===
# ── 1. Block committed secrets ───────────────────────────────────────────────
# Coarse, high-signal patterns. A dedicated scanner (gitleaks, trufflehog) is
# stronger - wire it in here if you have one.
$secretRe = '(AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----|xox[baprs]-[0-9A-Za-z-]+|ghp_[0-9A-Za-z]{36}|(api[_-]?key|secret|password|token)["'' ]*[:=]["'' ]*[0-9A-Za-z/+]{16,})'
$ic = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
foreach ($f in $staged) {
  # examples/hooks and templates legitimately show patterns/placeholders;
  # docs/, AGENTS.md, specs/, and memory/ ARE scanned - real values get pasted
  # into project docs and conventions in practice, so a blanket exemption
  # there would defeat the point of the scan.
  if ($f -match '\.example$' -or $f -like '.githooks/*' -or $f -like 'templates/*' -or $f -eq 'README.md') { continue }
  $blob = (git show ":$f" 2>$null) -join "`n"
  if ($blob -and [regex]::IsMatch($blob, $secretRe, $ic)) {
    Write-Host "X Possible secret in $f - remove it or use an env var (constitution: no secrets in VCS)."
    $fail = $true
  }
}

# ── 2. Block unresolved spec ambiguity markers on Approved specs ─────────────
# A Draft spec is a work in progress - it's expected to carry open
# [NEEDS CLARIFICATION] markers and its decision-log should still be
# committable as an audit trail. Only an Approved spec must be fully resolved.
foreach ($f in $staged) {
  if ($f -like 'specs/*' -and $f -match '\.md$') {
    $blob = (git show ":$f" 2>$null) -join "`n"
    if ($blob -match '\*\*Status\*\*:\s*Approved') {
      if ($blob -match 'NEEDS CLARIFICATION') {
        Write-Host "X $f is Approved but still has a [NEEDS CLARIFICATION] marker - resolve it (run the clarify-spec skill) before committing."
        $fail = $true
      }
    }
  }
}

# ── 3. Keep tool instruction files thin (see ADR-0001) ───────────────────────
foreach ($f in 'CLAUDE.md', '.github/copilot-instructions.md') {
  if ($staged -contains $f) {
    $lines = @(git show ":$f" 2>$null) | Where-Object { $_ -notmatch '^\s*(<!--.*-->)?\s*$' }
    if ($lines.Count -gt 2) {
      Write-Host "X $f has grown beyond a pointer - conventions belong in AGENTS.md (ADR-0001)."
      $fail = $true
    }
  }
}
# ── 4. Catch mirror drift before it ever reaches CI ──────────────────────────
# Same drift guard CI runs (see .github/workflows/agent-harness.yml), but
# gated on whether .agents/ is actually part of this commit - the cheapest
# point to catch it is the moment the edit is staged, not a CI round-trip
# later. Scoped to the generated mirror dirs so unrelated dirty-tree files
# don't produce a false positive.
if ($staged | Where-Object { $_ -like '.agents/*' }) {
  Write-Host "Running mirror-skills.sh + mirror-agents.sh (staged .agents/ change)..."
  $mirrorDirs = '.claude/agents', '.claude/skills', '.github/agents', '.github/skills', '.codex/agents', '.codex/skills'
  bash scripts/mirror-skills.sh
  $mirrorOk = $LASTEXITCODE -eq 0
  if ($mirrorOk) {
    bash scripts/mirror-agents.sh
    $mirrorOk = $LASTEXITCODE -eq 0
  }
  if (-not $mirrorOk) {
    Write-Host "X Mirror generation failed - fix the error above."
    $fail = $true
  } else {
    # Compare the working tree to the INDEX (not HEAD): staged mirror
    # updates you already `git add`ed are expected to differ from HEAD, so
    # `git status --porcelain` would false-positive on those. `git diff`
    # (no --cached) flags mirror output the regeneration just changed on
    # disk that ISN'T what you staged; `ls-files --others` catches
    # brand-new generated files (e.g. a new agent) that are untracked and
    # so invisible to `git diff`.
    $unstagedDiff = @(git diff --name-only -- $mirrorDirs) | Where-Object { $_ }
    $untracked = @(git ls-files --others --exclude-standard -- $mirrorDirs) | Where-Object { $_ }
    if ($unstagedDiff -or $untracked) {
      Write-Host "X .agents/ changed but the mirrors are stale. Run:"
      Write-Host "    bash scripts/mirror-skills.sh && bash scripts/mirror-agents.sh"
      Write-Host "  then 'git add' the regenerated files and re-commit."
      $fail = $true
    }
  }
}
# === KIT:END ===

# ── 5. Your stack's lint + fast tests — UNCOMMENT and match AGENTS.md ─────────
# Use the SAME commands named in AGENTS.md's Commands section so local, hook,
# and CI enforcement are identical. Keep these fast; slow suites belong in CI.
# Route them through scripts/quiet.ps1: hook output is read by agents too, and
# a sensor that dumps hundreds of log lines pollutes the context it feeds —
# quiet.ps1 condenses it to pass/fail + the first relevant error, with the
# full log kept in a temp file (see docs/token-efficiency.md).
#
# pwsh scripts/quiet.ps1 <exact lint command from AGENTS.md>;       if ($LASTEXITCODE -ne 0) { $fail = $true }
# pwsh scripts/quiet.ps1 <exact fast-test command from AGENTS.md>;  if ($LASTEXITCODE -ne 0) { $fail = $true }

if ($fail) {
  Write-Host ''
  Write-Host 'Commit blocked by pre-commit checks. Fix the above, or override with'
  Write-Host '  git commit --no-verify   (only if you know what you are doing).'
  exit 1
}
exit 0
