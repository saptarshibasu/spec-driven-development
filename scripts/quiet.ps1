#!/usr/bin/env pwsh
# quiet.ps1 — Windows/PowerShell twin of scripts/quiet.sh.
#
# Context-efficient backpressure: runs any command, swallows its output, and
# reports pass/fail + the first relevant error only. Full output is kept in a
# temp log for deeper investigation. Keep behavior in sync with quiet.sh.
#
# Usage:
#   pwsh scripts/quiet.ps1 <command> [args...]
#   pwsh scripts/quiet.ps1 npm test
#
# Tuning (env vars): QUIET_MAX_LINES (default 40), QUIET_ERR_RE.

param(
  [Parameter(Mandatory = $true, ValueFromRemainingArguments = $true)]
  [string[]]$Command
)

$max = if ($env:QUIET_MAX_LINES) { [int]$env:QUIET_MAX_LINES } else { 40 }
$errRe = if ($env:QUIET_ERR_RE) { $env:QUIET_ERR_RE } else {
  '(FAILED|FAILURES?|\d+ (failed|errors?)|error(\[[A-Za-z0-9]+\])?:|Error:|ERROR|Exception|Traceback|AssertionError|assert(ion)? ?fail|panic:|not ok|BUILD FAILED|Compilation failed|✖|✗)'
}

$log = Join-Path ([System.IO.Path]::GetTempPath()) ("quiet-" + [System.IO.Path]::GetRandomFileName() + ".log")
$cmdLine = $Command -join ' '

& $Command[0] @($Command | Select-Object -Skip 1) 2>&1 |
  ForEach-Object { "$_" } | Out-File -FilePath $log -Encoding utf8
$status = $LASTEXITCODE

$all = @(Get-Content $log)
$lines = $all.Count

if ($status -eq 0) {
  Write-Host "PASS: $cmdLine (exit 0, $lines output lines suppressed)"
  Remove-Item $log -ErrorAction SilentlyContinue
  exit 0
}

Write-Host "FAIL: $cmdLine (exit $status) - full output: $log"

$ic = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
$first = -1
for ($i = 0; $i -lt $lines; $i++) {
  if ([regex]::IsMatch($all[$i], $errRe, $ic)) { $first = $i; break }
}

if ($first -ge 0) {
  $last = [Math]::Min($first + $max - 1, $lines - 1)
  Write-Host ("-- first relevant error (line {0} of {1}; full log above) --" -f ($first + 1), $lines)
  $all[$first..$last] | ForEach-Object { Write-Host $_ }
  if ($last -lt ($lines - 1)) { Write-Host "-- truncated at $max lines --" }
}
else {
  Write-Host "-- no error pattern matched; last $max lines --"
  $all | Select-Object -Last $max | ForEach-Object { Write-Host $_ }
}

exit $status
