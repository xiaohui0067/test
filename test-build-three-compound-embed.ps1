$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$scriptPath = Join-Path $root 'build-data.ps1'
$outDir = Join-Path $root 'test-three-compound-embed-output'
$pagesDir = Join-Path $outDir 'pages'
$utf8NoBom = [Text.UTF8Encoding]::new($false)

$issueText = [string][char]0x671F
$openText = [string]::Concat(@([char]0x5F00, [char]0x5956, [char]0x65F6, [char]0x95F4))

function New-RecordHtml {
    param([int]$Issue, [string]$Date, [int[]]$Numbers)

    $balls = for ($i = 0; $i -lt 7; $i++) {
        $n = $Numbers[$i].ToString('00')
        '<div class="ball" data-name="A" data-index="{0}"><p><span class="plain">{1}</span><b>A</b></p></div>' -f $i, $n
    }

    return @"
<li>
  <dt><b>$Issue</b>$issueText($openText`:$Date)</dt>
  <dl>
    $($balls -join "`n    ")
  </dl>
</li>
"@
}

if (Test-Path -LiteralPath $outDir) {
    Remove-Item -LiteralPath $outDir -Recurse -Force
}
New-Item -ItemType Directory -Path $pagesDir -Force | Out-Null

$records = @()
for ($i = 1; $i -le 15; $i++) {
    $records += New-RecordHtml -Issue $i -Date "2025-01-$($i.ToString('00'))" -Numbers @(1, 2, 3, 10, 11, 12, 49)
}
for ($i = 1; $i -le 15; $i++) {
    $records += New-RecordHtml -Issue $i -Date "2026-01-$($i.ToString('00'))" -Numbers @(4, 5, 6, 13, 14, 15, 48)
}

[IO.File]::WriteAllText((Join-Path $pagesDir 'am.html'), "<html><body>$($records -join "`n")</body></html>", $utf8NoBom)

try {
    & $scriptPath -RootDir $outDir | Out-Null

    $recordsPath = Join-Path $outDir 'data\records.json'
    $recordsScriptPath = Join-Path $outDir 'data\records.js'
    $summaryPath = Join-Path $outDir 'data\dashboard-summary.json'
    $summaryScriptPath = Join-Path $outDir 'data\dashboard-summary.js'
    $gamesScriptPath = Join-Path $outDir 'data\game-predictions.js'
    $window5ScriptPath = Join-Path $outDir 'data\window5-state.js'
    $statePath = Join-Path $outDir 'data\three-compound-state.json'
    $stateScriptPath = Join-Path $outDir 'data\three-compound-state.js'
    $indexPath = Join-Path $outDir 'index.html'

    if (-not (Test-Path -LiteralPath $recordsPath)) { throw 'records.json was not created' }
    if (-not (Test-Path -LiteralPath $recordsScriptPath)) { throw 'records.js was not created' }
    if (-not (Test-Path -LiteralPath $summaryPath)) { throw 'dashboard-summary.json was not created' }
    if (-not (Test-Path -LiteralPath $summaryScriptPath)) { throw 'dashboard-summary.js was not created' }
    if (-not (Test-Path -LiteralPath $gamesScriptPath)) { throw 'game-predictions.js was not created' }
    if (-not (Test-Path -LiteralPath $window5ScriptPath)) { throw 'window5-state.js was not created' }
    if (-not (Test-Path -LiteralPath $statePath)) { throw 'three-compound-state.json was not created' }
    if (-not (Test-Path -LiteralPath $stateScriptPath)) { throw 'three-compound-state.js was not created' }
    if (-not (Test-Path -LiteralPath $indexPath)) { throw 'index.html was not created' }

    $state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
    $am = @($state.items | Where-Object { $_.source -eq 'am' } | Select-Object -First 1)
    if (-not $am) { throw 'am three-compound state was not created' }
    if (@($am.crossYearPools).Count -ne 4) { throw "expected 4 crossYearPools, got $(@($am.crossYearPools).Count)" }

    $html = [IO.File]::ReadAllText($indexPath, [Text.Encoding]::UTF8)
    if ($html.Contains('embedded-records')) {
        throw 'dashboard should not embed records json'
    }
    if (-not $html.Contains("loadJsonOrScript('data/dashboard-summary.json'")) {
        throw 'dashboard should load dashboard summary first'
    }
    if (-not $html.Contains("loadJsonOrScript('data/dashboard-summary.json', 'data/dashboard-summary.js', '__DASHBOARD_SUMMARY__')")) {
        throw 'dashboard should use local script fallback for dashboard summary'
    }
    if (-not $html.Contains("loadJsonOrScript('data/records.json'")) {
        throw 'dashboard should still be able to load records json externally'
    }
    if (-not $html.Contains("loadJsonOrScript('data/records.json', 'data/records.js', '__RECORDS_DATA__')")) {
        throw 'dashboard should use local script fallback for records data'
    }
    if (-not $html.Contains("loadJsonOrScript('data/game-predictions.json'")) {
        throw 'dashboard should be able to load game predictions externally'
    }
    if (-not $html.Contains("loadJsonOrScript('data/game-predictions.json', 'data/game-predictions.js', '__GAME_PREDICTIONS__')")) {
        throw 'dashboard should use local script fallback for game predictions'
    }
    if (-not $html.Contains("loadJsonOrScript('data/three-compound-state.json'")) {
        throw 'dashboard should be able to load three-compound state externally'
    }
    if (-not $html.Contains("loadJsonOrScript('data/three-compound-state.json', 'data/three-compound-state.js', '__THREE_COMPOUND_STATE__')")) {
        throw 'dashboard should use local script fallback for three-compound state'
    }
    if (-not $html.Contains('async function ensureRecordsData()')) {
        throw 'dashboard should lazy load records data independently'
    }
    if (-not $html.Contains('async function ensureGamePredictionsData()')) {
        throw 'dashboard should lazy load game predictions independently'
    }
    if (-not $html.Contains('async function ensureWindow5Data()')) {
        throw 'dashboard should lazy load window5 state independently'
    }
    if (-not $html.Contains('async function ensureThreeCompoundData()')) {
        throw 'dashboard should lazy load three-compound state independently'
    }
    if (-not $html.Contains('const tabDataLoaders = {')) {
        throw 'dashboard should map tabs to minimal data loaders'
    }
    if ($html.Contains('fullDataPromise')) {
        throw 'dashboard should not load every full data file with one shared promise'
    }
    if (-not $html.Contains('threeCompoundState = await ensureThreeCompoundData()')) {
        throw 'dashboard should read lazy-loaded threeCompound state'
    }
    if (-not $html.Contains('threeCrossYearPoolTable')) {
        throw 'dashboard should include cross-year pool table renderer'
    }

    $summaryText = Get-Content -LiteralPath $summaryPath -Raw
    if (-not $summaryText.Contains('"summary"')) { throw 'dashboard summary should include summary' }
    if (-not $summaryText.Contains('"recentRecords"')) { throw 'dashboard summary should include recentRecords' }
    if ($summaryText.Contains('"threeCompound"')) { throw 'dashboard summary should not include threeCompound state' }
    if ($summaryText.Contains('"games"')) { throw 'dashboard summary should not include game predictions' }

    $summaryScriptText = Get-Content -LiteralPath $summaryScriptPath -Raw
    if (-not $summaryScriptText.Contains('window.__DASHBOARD_SUMMARY__ = ')) {
        throw 'dashboard summary script should assign expected global'
    }

    Write-Host 'build three-compound embed ok'
}
finally {
    if (Test-Path -LiteralPath $outDir) {
        Remove-Item -LiteralPath $outDir -Recurse -Force
    }
}
