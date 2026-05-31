param(
    [string]$TaskName = 'Fetch-AM-Lottery-Records',
    [string]$ScriptPath = 'C:\codex\test\am\fetch-am.ps1',
    [string]$RunAt = '21:45'
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $ScriptPath)) {
    throw "Script not found: $ScriptPath"
}

$wrapperPath = Join-Path (Split-Path -Parent $ScriptPath) 'run-hidden.vbs'
$escapedScriptPath = $ScriptPath.Replace('"', '""')
$vbs = @"
Set shell = CreateObject("WScript.Shell")
shell.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File ""$escapedScriptPath""", 0, False
"@
Set-Content -LiteralPath $wrapperPath -Value $vbs -Encoding ASCII

$action = New-ScheduledTaskAction `
    -Execute 'wscript.exe' `
    -Argument "`"$wrapperPath`""

$runTime = [datetime]::ParseExact($RunAt, 'HH:mm', [Globalization.CultureInfo]::InvariantCulture)
$trigger = New-ScheduledTaskTrigger -Daily -At ([datetime]::Today.Add($runTime.TimeOfDay))
$settings = New-ScheduledTaskSettingsSet `
    -StartWhenAvailable `
    -MultipleInstances IgnoreNew `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 10)

Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Description 'Fetch AM lottery records and save a local HTML copy.' `
    -Force | Out-Null

Write-Host "Installed scheduled task: $TaskName"
Write-Host "Run time: every day at $RunAt"
Write-Host "Script: $ScriptPath"
Write-Host "Hidden wrapper: $wrapperPath"
