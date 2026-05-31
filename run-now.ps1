$ErrorActionPreference = 'Stop'

$scriptPath = Join-Path $PSScriptRoot 'fetch-am.ps1'
& $scriptPath

Write-Host ''
Write-Host 'Open local file: C:\codex\test\am\index.html'
