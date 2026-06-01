$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$workflowPath = Join-Path $root '.github/workflows/fetch-data.yml'
$installTaskPath = Join-Path $root 'install-task.ps1'
$wrapperPath = Join-Path $root 'run-hidden.vbs'
$runNowPath = Join-Path $root 'run-now.ps1'

$workflow = [IO.File]::ReadAllText($workflowPath, [Text.Encoding]::UTF8)
if ($workflow -notmatch '21:45 / 21:55 / 22:05 Beijing time') {
    throw 'workflow comment does not document the Beijing fallback schedules'
}
if ($workflow -notmatch 'cron:\s*"45 13 \* \* \*"') {
    throw 'workflow cron is not 13:45 UTC / 21:45 Beijing time'
}
if ($workflow -notmatch 'cron:\s*"55 13 \* \* \*"') {
    throw 'workflow cron is not 13:55 UTC / 21:55 Beijing time'
}
if ($workflow -notmatch 'cron:\s*"5 14 \* \* \*"') {
    throw 'workflow cron is not 14:05 UTC / 22:05 Beijing time'
}

$installTask = [IO.File]::ReadAllText($installTaskPath, [Text.Encoding]::UTF8)
if ($installTask -notmatch "\[string\]\`$BeijingRunAt = '21:45'") {
    throw 'scheduled task default BeijingRunAt is not 21:45'
}
if ($installTask -match [regex]::Escape('C:\codex\test\am')) {
    throw 'install-task.ps1 still contains the old C:\codex\test\am path'
}
if ($installTask -notmatch '-OutputDir') {
    throw 'scheduled task wrapper does not pass OutputDir'
}

$wrapper = [IO.File]::ReadAllText($wrapperPath, [Text.Encoding]::ASCII)
if ($wrapper -match [regex]::Escape('C:\codex\test\am')) {
    throw 'run-hidden.vbs still contains the old C:\codex\test\am path'
}
if ($wrapper -notmatch [regex]::Escape($root)) {
    throw 'run-hidden.vbs does not point at this repository'
}
if ($wrapper -notmatch '-OutputDir') {
    throw 'run-hidden.vbs does not pass OutputDir'
}

$runNow = [IO.File]::ReadAllText($runNowPath, [Text.Encoding]::UTF8)
if ($runNow -match [regex]::Escape('C:\codex\test\am')) {
    throw 'run-now.ps1 still contains the old C:\codex\test\am path'
}
if ($runNow -notmatch 'dashboard\.html') {
    throw 'run-now.ps1 does not default to dashboard.html'
}
if ($runNow -notmatch 'Start-Process\s+-FilePath\s+\$dashboardPath') {
    throw 'run-now.ps1 does not open dashboard.html'
}

if ($workflow -notmatch 'concurrency:') {
    throw 'fetch workflow does not define concurrency'
}
if ($workflow -notmatch 'git rebase origin/main') {
    throw 'fetch workflow does not rebase before pushing generated data'
}
if ($workflow -notmatch 'kjjl\.html') {
    throw 'fetch workflow does not commit kjjl.html'
}

Write-Host 'PASS'
