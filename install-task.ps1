param(
    [string]$TaskName = 'Fetch-AM-Lottery-Records',
    [string]$ScriptPath = (Join-Path $PSScriptRoot 'fetch-am.ps1'),
    [string]$OutputDir = $PSScriptRoot,
    [string]$BeijingRunAt = '21:45'
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $ScriptPath)) {
    throw "Script not found: $ScriptPath"
}

$wrapperPath = Join-Path (Split-Path -Parent $ScriptPath) 'run-hidden.vbs'
$escapedScriptPath = $ScriptPath.Replace('"', '""')
$escapedOutputDir = $OutputDir.Replace('"', '""')
$vbs = @"
Set shell = CreateObject("WScript.Shell")
shell.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File ""$escapedScriptPath"" -OutputDir ""$escapedOutputDir"" -SkipSnapshot", 0, False
"@
Set-Content -LiteralPath $wrapperPath -Value $vbs -Encoding ASCII

$action = New-ScheduledTaskAction `
    -Execute 'wscript.exe' `
    -Argument "`"$wrapperPath`""

$beijingZone = [TimeZoneInfo]::FindSystemTimeZoneById('China Standard Time')
$localZone = [TimeZoneInfo]::Local
$beijingTime = [datetime]::ParseExact($BeijingRunAt, 'HH:mm', [Globalization.CultureInfo]::InvariantCulture)
$beijingRunDate = [datetime]::SpecifyKind([datetime]::Today.Add($beijingTime.TimeOfDay), [DateTimeKind]::Unspecified)
$localRunTime = [TimeZoneInfo]::ConvertTime($beijingRunDate, $beijingZone, $localZone)
$trigger = New-ScheduledTaskTrigger -Daily -At $localRunTime
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
Write-Host "Run time: every day at $BeijingRunAt Beijing time ($($localRunTime.ToString('HH:mm')) local time)"
Write-Host "Script: $ScriptPath"
Write-Host "Output directory: $OutputDir"
Write-Host "Hidden wrapper: $wrapperPath"
