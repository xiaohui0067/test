$ErrorActionPreference = 'Stop'

$scriptPath = Join-Path $PSScriptRoot 'fetch-am.ps1'
& $scriptPath -OutputDir $PSScriptRoot -SkipSnapshot

Write-Host ''
$dashboardPath = Join-Path $PSScriptRoot 'dashboard.html'
Write-Host "Open local file: $dashboardPath"
Start-Process -FilePath $dashboardPath
