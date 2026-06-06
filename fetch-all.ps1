param(
    [string]$AmSourceUrl = 'https://2025kj.zkclhb.com:2025/am.html',
    [string]$AmBaseUrl = '',
    [string]$HkSourceUrl = 'https://2025kj.zkclhb.com:2025/hk.html',
    [string]$HkBaseUrl = '',
    [string]$OutputDir = $PSScriptRoot,
    [switch]$SkipSnapshot
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($AmBaseUrl)) { $AmBaseUrl = $AmSourceUrl }
if ([string]::IsNullOrWhiteSpace($HkBaseUrl)) { $HkBaseUrl = $HkSourceUrl }

$fetchScript = Join-Path $PSScriptRoot 'fetch-am.ps1'
$buildScript = Join-Path $PSScriptRoot 'build-data.ps1'

if (-not (Test-Path -LiteralPath $fetchScript)) {
    throw "Fetch script not found: $fetchScript"
}
if (-not (Test-Path -LiteralPath $buildScript)) {
    throw "Build script not found: $buildScript"
}

& $fetchScript -SourceUrl $AmSourceUrl -BaseUrl $AmBaseUrl -RootPageName 'am.html' -OutputDir $OutputDir -SkipSnapshot:$SkipSnapshot -SkipBuild
& $fetchScript -SourceUrl $HkSourceUrl -BaseUrl $HkBaseUrl -RootPageName 'hk.html' -OutputDir $OutputDir -SkipSnapshot:$SkipSnapshot -SkipBuild
& $buildScript -RootDir $OutputDir | Out-Null

Write-Host "Fetched Macau and Hong Kong, then refreshed dashboard data."
