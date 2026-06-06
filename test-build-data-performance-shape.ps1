$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$scriptPath = Join-Path $root 'build-data.ps1'
$text = Get-Content -LiteralPath $scriptPath -Raw

if ($text.Contains('ConvertTo-Json -Depth 12')) {
    throw 'build-data.ps1 should not perform unused full payload ConvertTo-Json -Depth 12'
}

if (-not $text.Contains('ConvertTo-Json -Depth $Depth -Compress')) {
    throw 'external data json/js should be serialized in compact form'
}

if (-not $text.Contains('ConvertTo-Json -Depth 10 -Compress')) {
    throw 'large generated json payloads should use compact serialization'
}

if (-not $text.Contains("loadJsonOrScript('data/dashboard-summary.json'")) {
    throw 'dashboard should start from dashboard-summary.json'
}

if (-not $text.Contains('function loadScriptData')) {
    throw 'dashboard should define local script data fallback'
}

if (-not $text.Contains('function loadJsonOrScript')) {
    throw 'dashboard should load json with script fallback for file URLs'
}

if (-not $text.Contains('data/dashboard-summary.js')) {
    throw 'dashboard should reference dashboard-summary.js fallback'
}

if (-not $text.Contains('New-DashboardSummary')) {
    throw 'dashboard summary generator should exist'
}

if (-not $text.Contains('[switch]$Profile')) {
    throw 'build-data.ps1 should expose -Profile switch'
}

if (-not $text.Contains('function Invoke-Profiled')) {
    throw 'build-data.ps1 should define Invoke-Profiled'
}

foreach ($stage in @('parse-pages', 'generated-predictions', 'game-predictions', 'records-json-serialize', 'three-compound-python')) {
    if (-not $text.Contains("'$stage'")) {
        throw "build profile should include stage $stage"
    }
}

foreach ($stage in @('game-settle-existing', 'game-current-targets', 'game-sort-output')) {
    if (-not $text.Contains("'$stage'")) {
        throw "build profile should include game sub-stage $stage"
    }
}

foreach ($stage in @('dedupe-build-map', 'dedupe-sort-records', 'summary-counts')) {
    if (-not $text.Contains("'$stage'")) {
        throw "build profile should include dedupe sub-stage $stage"
    }
}

if (-not $text.Contains('function New-RecordLookup')) {
    throw 'build-data.ps1 should define indexed record lookup for repeated settlement'
}

if (-not $text.Contains('RecordLookup')) {
    throw 'game settlement should use record lookup instead of repeated full scans'
}

Write-Host 'build-data performance shape ok'
