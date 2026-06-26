#!/usr/bin/env pwsh
# pre-commit.ps1 — Windows/PowerShell twin of the .githooks/pre-commit hook.
#
# Git for Windows runs the POSIX `pre-commit` hook through its bundled bash, so
# that file already works on Windows if Git Bash is present. This PowerShell
# equivalent is for setups that prefer a native hook (no Git Bash, or a
# PowerShell-based hook manager): point a one-line `.githooks/pre-commit` wrapper
# at it, or invoke it from your hook runner. Keep the two checks in sync.
# See docs/harness-engineering.md and docs/hooks.md.

$ErrorActionPreference = 'Stop'
$fail = $false
$staged = @(git diff --cached --name-only --diff-filter=ACM) | Where-Object { $_ }

# ── 1. Block committed secrets ───────────────────────────────────────────────
# Coarse, high-signal patterns. A dedicated scanner (gitleaks, trufflehog) is
# stronger — wire it in here if you have one.
$secretRe = '(AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----|xox[baprs]-[0-9A-Za-z-]+|ghp_[0-9A-Za-z]{36}|(api[_-]?key|secret|password|token)["'' ]*[:=]["'' ]*[0-9A-Za-z/+]{16,})'
$ic = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
foreach ($f in $staged) {
  if ($f -match '\.example$' -or $f -match '\.md$' -or $f -like '.githooks/*') { continue }  # examples/docs may show placeholder patterns
  $blob = (git show ":$f" 2>$null) -join "`n"
  if ($blob -and [regex]::IsMatch($blob, $secretRe, $ic)) {
    Write-Host "X Possible secret in $f - remove it or use an env var (constitution: no secrets in VCS)."
    $fail = $true
  }
}

# ── 2. Block unresolved spec ambiguity markers ───────────────────────────────
foreach ($f in $staged) {
  if ($f -like 'specs/*' -and $f -match '\.md$') {
    $blob = (git show ":$f" 2>$null) -join "`n"
    if ($blob -match 'NEEDS CLARIFICATION') {
      Write-Host "X $f still has a [NEEDS CLARIFICATION] marker - resolve it (run the clarify skill) before committing."
      $fail = $true
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

# ── 4. Your stack's lint + fast tests — UNCOMMENT and match AGENTS.md ─────────
# Use the SAME commands named in AGENTS.md's Commands section so local, hook,
# and CI enforcement are identical. Keep these fast; slow suites belong in CI.
#
# & <exact lint command from AGENTS.md>;       if ($LASTEXITCODE -ne 0) { $fail = $true }
# & <exact fast-test command from AGENTS.md>;  if ($LASTEXITCODE -ne 0) { $fail = $true }

if ($fail) {
  Write-Host ''
  Write-Host 'Commit blocked by pre-commit checks. Fix the above, or override with'
  Write-Host '  git commit --no-verify   (only if you know what you are doing).'
  exit 1
}
exit 0
