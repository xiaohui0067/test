$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$vercelPath = Join-Path $root 'vercel.json'
$cronPath = Join-Path $root 'api/manual-fetch.js'
$obsoleteCronPath = Join-Path $root 'api/cron-fetch.js'

if (-not (Test-Path -LiteralPath $vercelPath)) {
    throw 'vercel.json should configure Vercel cron jobs'
}

$vercel = Get-Content -LiteralPath $vercelPath -Raw | ConvertFrom-Json
$cron = @($vercel.crons | Where-Object { [string]$_.path -like '/api/manual-fetch*' } | Select-Object -First 1)
if ($cron.Count -eq 0) {
    throw 'vercel.json should schedule /api/manual-fetch'
}

if ([string]::IsNullOrWhiteSpace([string]$cron[0].schedule)) {
    throw 'cron schedule should not be empty'
}

if (-not (Test-Path -LiteralPath $cronPath)) {
    throw 'api/manual-fetch.js should exist'
}

if (Test-Path -LiteralPath $obsoleteCronPath) {
    throw 'api/cron-fetch.js should not remain after cron was routed through manual-fetch'
}

$script = [IO.File]::ReadAllText($cronPath, [Text.Encoding]::UTF8)
foreach ($marker in @('CRON_SECRET', 'GITHUB_TOKEN', 'manual-fetch.yml', 'workflow_dispatch', 'am_source_url', 'hk_source_url')) {
    if (-not $script.Contains($marker)) {
        throw "cron fetch api should contain $marker"
    }
}

if (-not $script.Contains('manualFetchVersion')) {
    throw 'manual fetch api should expose a deployment version marker'
}

if (-not $script.Contains("req.headers['authorization']") -or -not $script.Contains('Bearer')) {
    throw 'manual fetch cron mode should validate bearer authorization'
}

if (-not $script.Contains('2025kj.zkclhb.com:2025/am.html') -or -not $script.Contains('2025kj.zkclhb.com:2025/hk.html')) {
    throw 'cron fetch api should dispatch default Macau and Hong Kong collection URLs'
}

Write-Host 'vercel cron fetch shape ok'
