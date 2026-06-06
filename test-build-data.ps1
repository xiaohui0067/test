$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$scriptPath = Join-Path $root 'build-data.ps1'
$outDir = Join-Path $root 'test-data-output'
$pagesDir = Join-Path $outDir 'pages'
$utf8NoBom = [Text.UTF8Encoding]::new($false)

$yang = [string][char]0x7F8A
$ji = [string][char]0x9E21
$tu = [string][char]0x5154
$zhu = [string][char]0x732A
$ma = [string][char]0x9A6C
$issueText = [string][char]0x671F
$openText = [string]::Concat(@([char]0x5F00, [char]0x5956, [char]0x65F6, [char]0x95F4))

if (Test-Path -LiteralPath $outDir) {
    Remove-Item -LiteralPath $outDir -Recurse -Force
}
New-Item -ItemType Directory -Path $pagesDir -Force | Out-Null

$sample = @"
<html><body>
<li>
  <dt><b>134</b>$issueText($openText`:2026-05-14)</dt>
  <dl>
    <div class="ball" data-name="$yang" data-index="0"><p><span class="red">24</span><b>$yang</b></p></div>
    <div class="ball" data-name="$ji" data-index="1"><p><span class="red">46</span><b>$ji</b></p></div>
    <div class="ball" data-name="$tu" data-index="2"><p><span class="red">40</span><b>$tu</b></p></div>
    <div class="ball" data-name="$zhu" data-index="3"><p><span class="green">44</span><b>$zhu</b></p></div>
    <div class="ball" data-name="$ji" data-index="4"><p><span class="green">22</span><b>$ji</b></p></div>
    <div class="ball" data-name="$ma" data-index="5"><p><span class="green">49</span><b>$ma</b></p></div>
    <div class="ball" data-name="$ma" data-index="6"><p><span class="blue">37</span><b>$ma</b></p></div>
  </dl>
</li>
</body></html>
"@

[IO.File]::WriteAllText((Join-Path $pagesDir 'am.html'), $sample, $utf8NoBom)

$oldAmSample = @"
<html><body>
<li>
  <dt><b>145</b>$issueText($openText`:2025-05-25)</dt>
  <dl>
    <div class="ball" data-name="$yang" data-index="0"><p><span class="red">30</span><b>$yang</b></p></div>
    <div class="ball" data-name="$ji" data-index="1"><p><span class="red">25</span><b>$ji</b></p></div>
    <div class="ball" data-name="$tu" data-index="2"><p><span class="red">29</span><b>$tu</b></p></div>
    <div class="ball" data-name="$zhu" data-index="3"><p><span class="green">28</span><b>$zhu</b></p></div>
    <div class="ball" data-name="$ji" data-index="4"><p><span class="green">27</span><b>$ji</b></p></div>
    <div class="ball" data-name="$ma" data-index="5"><p><span class="green">26</span><b>$ma</b></p></div>
    <div class="ball" data-name="$ma" data-index="6"><p><span class="blue">24</span><b>$ma</b></p></div>
  </dl>
</li>
</body></html>
"@

[IO.File]::WriteAllText((Join-Path $pagesDir '2025.html'), $oldAmSample, $utf8NoBom)

$hkSample = @"
<html><body>
<li>
  <dt><b>55</b>$issueText($openText`:2026-05-25)</dt>
  <dl>
    <div class="ball" data-name="$yang" data-index="0"><p><span class="red">12</span><b>$yang</b></p></div>
    <div class="ball" data-name="$ji" data-index="1"><p><span class="red">23</span><b>$ji</b></p></div>
    <div class="ball" data-name="$tu" data-index="2"><p><span class="red">37</span><b>$tu</b></p></div>
    <div class="ball" data-name="$zhu" data-index="3"><p><span class="green">06</span><b>$zhu</b></p></div>
    <div class="ball" data-name="$ji" data-index="4"><p><span class="green">09</span><b>$ji</b></p></div>
    <div class="ball" data-name="$ma" data-index="5"><p><span class="green">44</span><b>$ma</b></p></div>
    <div class="ball" data-name="$ma" data-index="6"><p><span class="blue">18</span><b>$ma</b></p></div>
  </dl>
</li>
<li>
  <dt><b>54</b>$issueText($openText`:2026-05-21)</dt>
  <dl>
    <div class="ball" data-name="$yang" data-index="0"><p><span class="red">01</span><b>$yang</b></p></div>
    <div class="ball" data-name="$ji" data-index="1"><p><span class="red">02</span><b>$ji</b></p></div>
    <div class="ball" data-name="$tu" data-index="2"><p><span class="red">03</span><b>$tu</b></p></div>
    <div class="ball" data-name="$zhu" data-index="3"><p><span class="green">04</span><b>$zhu</b></p></div>
    <div class="ball" data-name="$ji" data-index="4"><p><span class="green">05</span><b>$ji</b></p></div>
    <div class="ball" data-name="$ma" data-index="5"><p><span class="green">06</span><b>$ma</b></p></div>
    <div class="ball" data-name="$ma" data-index="6"><p><span class="blue">07</span><b>$ma</b></p></div>
  </dl>
</li>
</body></html>
"@

[IO.File]::WriteAllText((Join-Path $pagesDir 'hk.html'), $hkSample, $utf8NoBom)
[IO.File]::WriteAllText((Join-Path $outDir 'kjjl.html'), '<html><body>lottery records</body></html>', $utf8NoBom)

$dataDir = Join-Path $outDir 'data'
New-Item -ItemType Directory -Path $dataDir -Force | Out-Null
$existingGame = [pscustomobject]@{
    items = @(
        [pscustomobject]@{
            id = 'test-three-hit'
            source = 'hk'
            sourceName = 'hk'
            game = 'three-hit-three'
            gameName = 'three-hit-three'
            algorithmId = 'greedy'
            algorithmName = 'greedy'
            year = 2025
            displayYear = '2026'
            issue = 55
            targetDate = '2026-05-25'
            numbers = @('12', '23', '37')
            createdAt = '2026-05-24 21:45:00'
            status = 'pending'
        },
        [pscustomobject]@{
            id = 'test-special-hit'
            source = 'hk'
            sourceName = 'hk'
            game = 'special-number'
            gameName = 'special-number'
            algorithmId = 'greedy'
            algorithmName = 'greedy'
            year = 2025
            displayYear = '2026'
            issue = 55
            targetDate = '2026-05-25'
            numbers = @('18')
            createdAt = '2026-05-24 21:45:00'
            status = 'pending'
        },
        [pscustomobject]@{
            id = 'test-special-stale-wrong-hit'
            source = 'hk'
            sourceName = 'hk'
            game = 'special-number'
            gameName = 'special-number'
            algorithmId = 'backtracking'
            algorithmName = 'backtracking'
            year = 2025
            displayYear = '2026'
            issue = 55
            targetDate = '2026-05-25'
            numbers = @('03')
            createdAt = '2026-05-24 21:45:00'
            status = 'settled'
            hit = $true
            actualDate = '2026-05-25'
            actualIssue = 55
            actualNumbers = @('18')
        },
        [pscustomobject]@{
            id = 'test-hk-shifted-target-date'
            source = 'hk'
            sourceName = 'hk'
            game = 'special-number'
            gameName = 'special-number'
            algorithmId = 'monte-carlo'
            algorithmName = 'monte-carlo'
            year = 2025
            displayYear = '2026'
            issue = 55
            targetDate = '2026-05-26'
            numbers = @('18')
            createdAt = '2026-05-25 21:45:00'
            status = 'pending'
        },
        [pscustomobject]@{
            id = 'test-hk-future-issue-no-current-draw'
            source = 'hk'
            sourceName = 'hk'
            game = 'special-number'
            gameName = 'special-number'
            algorithmId = 'particle-swarm'
            algorithmName = 'particle-swarm'
            year = 2025
            displayYear = '2026'
            issue = 57
            targetDate = '2026-05-28'
            numbers = @('18')
            createdAt = '2026-05-26 21:45:00'
            status = 'pending'
        },
        [pscustomobject]@{
            id = 'partial-am-three-hit'
            source = 'am'
            sourceName = 'am'
            game = 'three-hit-three'
            gameName = 'three-hit-three'
            algorithmId = 'greedy'
            algorithmName = 'greedy'
            year = 2025
            displayYear = '2026'
            issue = 135
            targetDate = '2026-05-15'
            numbers = @('01', '02', '03')
            createdAt = '2026-05-14 21:45:00'
            status = 'pending'
        },
        [pscustomobject]@{
            id = 'test-future-am-three-hit'
            source = 'am'
            sourceName = 'am'
            game = 'three-hit-three'
            gameName = 'three-hit-three'
            algorithmId = 'ensemble'
            algorithmName = 'ensemble'
            year = 2025
            displayYear = '2026'
            issue = 145
            targetDate = '2026-05-25'
            numbers = @('01', '02', '03')
            createdAt = '2026-05-24 21:45:00'
            status = 'pending'
        }
    )
}
[IO.File]::WriteAllText((Join-Path $dataDir 'game-predictions.json'), ($existingGame | ConvertTo-Json -Depth 8), $utf8NoBom)

try {
    & $scriptPath -RootDir $outDir | Out-Null
    $firstWindowStatePath = Join-Path $dataDir 'window5-state.json'
    $firstWindowState = Get-Content -LiteralPath $firstWindowStatePath -Raw -Encoding UTF8 | ConvertFrom-Json
    $firstAmWindowState = @($firstWindowState.items | Where-Object { $_.source -eq 'am' } | Select-Object -First 1)[0]
    & $scriptPath -RootDir $outDir | Out-Null
    $secondWindowState = Get-Content -LiteralPath $firstWindowStatePath -Raw -Encoding UTF8 | ConvertFrom-Json
    $secondAmWindowState = @($secondWindowState.items | Where-Object { $_.source -eq 'am' } | Select-Object -First 1)[0]
    if ($firstAmWindowState.adjustmentStatus -eq 'changed' -and @($firstAmWindowState.yearPoolHistory).Count -gt 0 -and [int]$firstAmWindowState.yearPoolHistory[0].issue -eq 134 -and $secondAmWindowState.adjustmentStatus -ne 'changed') {
        throw 'window5 current-year pool should keep latest-issue changed status across repeated builds'
    }

    $jsonPath = Join-Path $outDir 'data/records.json'
    if (-not (Test-Path -LiteralPath $jsonPath)) {
        throw 'records.json was not created'
    }

    $data = Get-Content -LiteralPath $jsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($data.records.Count -ne 4) {
        throw 'record count mismatch'
    }
    $record = @($data.records | Where-Object { $_.source -eq 'am' })[0]
    if ($record.issue -ne 134) {
        throw 'issue was not parsed'
    }
    if ($record.date -ne '2026-05-14') {
        throw 'date was not parsed'
    }
    if ($record.source -ne 'am') {
        throw 'source was not detected'
    }
    if ($record.balls.Count -ne 7) {
        throw 'balls count mismatch'
    }
    if ($record.balls[0].number -ne 24 -or $record.balls[0].zodiac -ne $yang -or $record.balls[0].color -ne 'red') {
        throw 'ball fields were not parsed'
    }
    if ($data.summary.totalRecords -ne 4) {
        throw 'summary total mismatch'
    }
    if (-not (Test-Path -LiteralPath (Join-Path $outDir 'index.html'))) {
        throw 'index.html dashboard was not created'
    }
    if (-not (Test-Path -LiteralPath (Join-Path $outDir 'kjjl.html'))) {
        throw 'kjjl.html lottery records page was not created'
    }
    if (Test-Path -LiteralPath (Join-Path $outDir 'dashboard.html')) {
        throw 'dashboard.html should not be generated after renaming dashboard to index.html'
    }
    $dashboard = [IO.File]::ReadAllText((Join-Path $outDir 'index.html'), [Text.Encoding]::UTF8)
    if (-not $dashboard.Contains('href="kjjl.html"')) {
        throw 'dashboard should link back to kjjl.html'
    }
    $buildScript = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'build-data.ps1'), [Text.Encoding]::UTF8)
    if ($buildScript.Contains('C:\codex\test\am')) {
        throw 'build-data.ps1 should not use a machine-specific default path'
    }
    if (-not $dashboard.Contains('data-tab="betting"') -or -not $dashboard.Contains('data-tab="overview"') -or -not $dashboard.Contains('data-tab="games"') -or -not $dashboard.Contains('data-tab="daily"') -or -not $dashboard.Contains('data-tab="window5"') -or -not $dashboard.Contains('data-tab="threeWindow5"') -or -not $dashboard.Contains('data-tab="patternWatch"') -or -not $dashboard.Contains('data-tab="manualFetch"')) {
        throw 'dashboard should expose betting, overview, review, 5-window, three-hit 5-window, advanced analysis, manual fetch, and daily tabs'
    }
    if (-not $dashboard.Contains('function showLoading') -or -not $dashboard.Contains('setTimeout(async () =>') -or -not $dashboard.Contains('showLoading(tab)')) {
        throw 'dashboard tab switches should show loading before expensive renders'
    }
    if ($dashboard.Contains('data-tab="trend"') -or $dashboard.Contains('data-tab="picker"') -or $dashboard.Contains('data-tab="sandbox"') -or $dashboard.Contains('data-tab="forecast"')) {
        throw 'dashboard should not expose trend, picker, sandbox, or forecast modules'
    }
    if ($dashboard.Contains('function renderTrend') -or $dashboard.Contains('function renderPicker') -or $dashboard.Contains('function renderGame()') -or $dashboard.Contains('function renderSandbox()') -or $dashboard.Contains('function sandboxSection') -or $dashboard.Contains('function renderForecast()') -or $dashboard.Contains('function forecastSection')) {
        throw 'removed modules should not be emitted'
    }
    if ($dashboard.Contains('trend-source') -or $dashboard.Contains('pick-source') -or $dashboard.Contains('special-source')) {
        throw 'removed module controls should not be emitted'
    }
    if ($dashboard.Contains('function specialFixedPeriod8')) {
        throw 'special number anti-miss game should not be emitted'
    }
    if ($dashboard.Contains('game-board') -or $dashboard.Contains('game-new') -or $dashboard.Contains('function newGame') -or $dashboard.Contains('function checkGame')) {
        throw 'lottery record challenge game should not be emitted'
    }
    if ($dashboard.Contains('sanZhongSanSixRecommendations') -or $dashboard.Contains('sixRecs') -or $dashboard.Contains('sixCodeMetrics') -or $dashboard.Contains('6&#30721;&#26368;&#20339;') -or $dashboard.Contains('sixBest')) {
        throw 'sanzhong 6-number game should not be emitted'
    }
    if ($dashboard.Contains('sanZhongSanPortfolioMetrics') -or $dashboard.Contains('predictionModels') -or $dashboard.Contains('renderSanZhongSanResults')) {
        throw 'prediction and sanzhong modules should not be emitted'
    }
    if ($dashboard.Contains('sanzhong-pred-save') -or $dashboard.Contains('pred-save')) {
        throw 'manual prediction save buttons should not be emitted'
    }
    $dashboardSummaryFile = Join-Path $outDir 'data/dashboard-summary.json'
    $dashboardSummaryScript = Join-Path $outDir 'data/dashboard-summary.js'
    if (-not (Test-Path -LiteralPath $dashboardSummaryFile)) {
        throw 'dashboard-summary.json was not created'
    }
    if (-not (Test-Path -LiteralPath $dashboardSummaryScript)) {
        throw 'dashboard-summary.js was not created'
    }
    $dashboardSummaryText = Get-Content -LiteralPath $dashboardSummaryFile -Raw
    if (-not $dashboardSummaryText.Contains('"predictions"')) {
        throw 'collection-time predictions were not included in dashboard summary'
    }
    $dashboardSummaryScriptText = Get-Content -LiteralPath $dashboardSummaryScript -Raw
    if (-not $dashboardSummaryScriptText.Contains('window.__DASHBOARD_SUMMARY__ = ')) {
        throw 'dashboard summary script fallback was not generated'
    }
    $bettingSnapshotsFile = Join-Path $outDir 'data/betting-snapshots.json'
    $bettingSnapshotsScript = Join-Path $outDir 'data/betting-snapshots.js'
    if (-not (Test-Path -LiteralPath $bettingSnapshotsFile)) {
        throw 'betting-snapshots.json was not created'
    }
    if (-not (Test-Path -LiteralPath $bettingSnapshotsScript)) {
        throw 'betting-snapshots.js script fallback was not generated'
    }
    $bettingSnapshotData = Get-Content -LiteralPath $bettingSnapshotsFile -Raw -Encoding UTF8 | ConvertFrom-Json
    if (@($bettingSnapshotData.items).Count -lt 4) {
        throw 'betting snapshots should persist at least one special and one three-hit recommendation per source'
    }
    foreach ($source in @('am', 'hk')) {
        foreach ($game in @('special-number', 'three-hit-three')) {
            $snapshot = @($bettingSnapshotData.items | Where-Object { $_.source -eq $source -and $_.game -eq $game } | Select-Object -First 1)
            if ($snapshot.Count -eq 0 -or @($snapshot[0].pool).Count -eq 0 -or -not $snapshot[0].status) {
                throw "expected persisted betting snapshot for $source $game"
            }
            if ($game -eq 'special-number' -and (@($snapshot[0].primaryPool).Count -ne 1 -or @($snapshot[0].guardPool).Count -ne 8)) {
                throw "special-number betting snapshot should persist one primary number and eight guard numbers for $source"
            }
            if ($game -eq 'three-hit-three' -and (@($snapshot[0].primaryPool).Count -ne 3 -or @($snapshot[0].guardPool).Count -ne 5)) {
                throw "three-hit-three betting snapshot should persist three primary numbers and five guard numbers for $source"
            }
        }
    }
    $bettingSnapshotsScriptText = Get-Content -LiteralPath $bettingSnapshotsScript -Raw
    if (-not $bettingSnapshotsScriptText.Contains('window.__BETTING_SNAPSHOTS__ = ')) {
        throw 'betting snapshots script fallback should expose __BETTING_SNAPSHOTS__'
    }
    if (-not $dashboard.Contains('__BETTING_SNAPSHOTS__') -or -not $dashboard.Contains('ensureBettingSnapshots')) {
        throw 'dashboard should load persisted betting snapshots before rendering recommendations'
    }
    if ($dashboard.Contains('"forecasts":')) {
        throw 'prediction observation data should not be embedded'
    }
    if (-not $dashboard.Contains('function displayYear(record)')) {
        throw 'dashboard should display draw year from record date'
    }
    if ($dashboard.Contains('selectedSummary.latest.year') -or $dashboard.Contains('latest.year)}&#24180;')) {
        throw 'latest draw displays should not use parsed file year'
    }
    if ($dashboard.Contains('autoSaveNextPrediction') -or $dashboard.Contains('autoSaveSanZhongPrediction')) {
        throw 'prediction auto save should not run while opening or switching the dashboard'
    }
    if ($dashboard.Contains('dateMismatch')) {
        throw 'prediction evaluator should not settle by mismatched dates'
    }
    if (-not $dashboard.Contains('.compact-table')) {
        throw 'compact table styles should be emitted'
    }
    $predictionFile = Join-Path $outDir 'data/predictions.json'
    if (-not (Test-Path -LiteralPath $predictionFile)) {
        throw 'predictions.json was not created'
    }
    $predictions = Get-Content -LiteralPath $predictionFile -Raw -Encoding UTF8 | ConvertFrom-Json
    $hkNext = @($predictions.next | Where-Object { $_.source -eq 'hk' } | Select-Object -First 1)
    if ($hkNext.Count -gt 0 -and $hkNext[0].targetDate -eq '2026-05-26') {
        throw 'hk next draw date should not be generated as latest date plus one day'
    }
    $hkSanZhong = @($predictions.sanzhong | Where-Object { $_.source -eq 'hk' } | Select-Object -First 1)
    if ($hkSanZhong.Count -gt 0 -and $hkSanZhong[0].targetDate -eq '2026-05-26') {
        throw 'hk sanzhong target date should not be generated as latest date plus one day'
    }
    $nextKeys = @($predictions.next | ForEach-Object { '{0}|{1}|{2}' -f $_.source, $_.displayYear, $_.issue })
    if ($nextKeys.Count -ne @($nextKeys | Select-Object -Unique).Count) {
        throw 'next predictions should be unique by source/displayYear/issue'
    }
    $szKeys = @($predictions.sanzhong | ForEach-Object { '{0}|{1}|{2}' -f $_.source, $_.displayYear, $_.issue })
    if ($szKeys.Count -ne @($szKeys | Select-Object -Unique).Count) {
        throw 'sanzhong predictions should be unique by source/displayYear/issue'
    }
    $gameFile = Join-Path $outDir 'data/game-predictions.json'
    if (-not (Test-Path -LiteralPath $gameFile)) {
        throw 'game-predictions.json was not created'
    }
    $gameData = Get-Content -LiteralPath $gameFile -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach ($source in @('am', 'hk')) {
        foreach ($game in @('three-hit-three', 'special-number')) {
            $latestTarget = @($gameData.items |
                Where-Object { $_.source -eq $source -and $_.game -eq $game -and $_.id -notlike 'test-*' } |
                Sort-Object @{ Expression = 'targetDate'; Descending = $true }, @{ Expression = 'displayYear'; Descending = $true }, @{ Expression = 'issue'; Descending = $true } |
                Select-Object -First 1)
            if ($latestTarget.Count -eq 0) {
                throw "expected latest generated target for $source $game"
            }
            $rows = @($gameData.items | Where-Object {
                $_.source -eq $source -and
                $_.game -eq $game -and
                $_.targetDate -eq $latestTarget[0].targetDate -and
                $_.displayYear -eq $latestTarget[0].displayYear -and
                [int]$_.issue -eq [int]$latestTarget[0].issue
            })
            if ($rows.Count -ne 12) {
                throw "expected 12 recommendation rows for $source $game"
            }
            if (@($rows | Where-Object { $_.algorithmId -eq 'ensemble' }).Count -ne 1) {
                throw "expected ensemble recommendation for $source $game"
            }
            if (@($rows | Where-Object { $_.algorithmId -ne 'ensemble' }).Count -ne 11) {
                throw "expected eleven algorithm recommendations for $source $game"
            }
            if (@($rows | Where-Object { $_.algorithmId -eq 'mirofish-sandbox' }).Count -ne 0) {
                throw "MiroFish sandbox recommendations should not be generated for $source $game"
            }
        }
    }
    $settledThree = @($gameData.items | Where-Object { $_.id -eq 'test-three-hit' })[0]
    if ($settledThree.status -ne 'settled' -or -not $settledThree.hit) {
        throw 'three-hit-three pending row should settle as hit using first six numbers'
    }
    $settledSpecial = @($gameData.items | Where-Object { $_.id -eq 'test-special-hit' })[0]
    if ($settledSpecial.status -ne 'settled' -or -not $settledSpecial.hit) {
        throw 'special-number pending row should settle as hit using seventh number'
    }
    $staleSpecial = @($gameData.items | Where-Object { $_.id -eq 'test-special-stale-wrong-hit' })[0]
    if ($staleSpecial.status -ne 'settled' -or $staleSpecial.hit) {
        throw 'settled special-number rows should be recalculated when stored hit conflicts with actual special number'
    }
    $shiftedTarget = @($gameData.items | Where-Object { $_.id -eq 'test-hk-shifted-target-date' })[0]
    if ($shiftedTarget.status -ne 'settled' -or -not $shiftedTarget.hit -or $shiftedTarget.actualDate -ne '2026-05-25') {
        throw 'hk shifted target date should settle by issue and display year when exact target date is absent'
    }
    $futureHkIssue = @($gameData.items | Where-Object { $_.id -eq 'test-hk-future-issue-no-current-draw' })[0]
    if ($futureHkIssue.status -ne 'pending') {
        throw 'hk future issue should not settle against prior-year same issue'
    }
    $futureThree = @($gameData.items | Where-Object { $_.id -eq 'test-future-am-three-hit' })[0]
    if ($futureThree.status -ne 'pending') {
        throw 'future dated am 145 prediction should remain pending until exact target date is drawn'
    }
    if (Test-Path -LiteralPath (Join-Path $outDir 'data/prediction-observations.json')) {
        throw 'prediction-observations.json should not be generated after forecast removal'
    }
    if (Test-Path -LiteralPath (Join-Path $outDir 'data/forecast-evaluation.json')) {
        throw 'forecast-evaluation.json should not be generated after forecast removal'
    }
    if ($dashboard.Contains('pick-lines') -or $dashboard.Contains('pick-include') -or $dashboard.Contains('pick-exclude') -or $dashboard.Contains('pick-odd') -or $dashboard.Contains('maxAdjacentRun')) {
        throw 'picker controls should not be emitted'
    }
    if (-not $dashboard.Contains('function asArray(value)')) {
        throw 'dashboard should normalize scalar game numbers before rendering'
    }
    if (-not $dashboard.Contains('function normalizeNumberGroup(value)')) {
        throw 'dashboard should normalize PowerShell array wrapper objects before rendering numbers'
    }
    if (-not $dashboard.Contains('normalizeNumberGroup(nums).map')) {
        throw 'number chip renderer should use normalized number groups'
    }
    if (-not $dashboard.Contains('function recommendationSummary(rows)')) {
        throw 'dashboard should summarize duplicate algorithm recommendations'
    }
    if (-not $dashboard.Contains('&#25512;&#33616;&#27719;&#24635;')) {
        throw 'game sections should render recommendation summary'
    }
    if (-not $dashboard.Contains('sort((a, b) => Number(a) - Number(b))')) {
        throw 'recommendation summary should ignore number order'
    }
    if (-not $dashboard.Contains('function recommendationCopyText(summaryRows, game)')) {
        throw 'dashboard should build copy text for recommendation summary'
    }
    if (-not $dashboard.Contains("game === 'special-number'")) {
        throw 'special-number copy text should use comma separated single numbers'
    }
    if (-not $dashboard.Contains('api.qrserver.com/v1/create-qr-code')) {
        throw 'dashboard should render qr code for recommendation summary copy text'
    }
    if (-not $dashboard.Contains('&#24494;&#20449;&#25195;&#30721;&#22797;&#21046;')) {
        throw 'dashboard should label the WeChat scan copy area'
    }
    if (-not $dashboard.Contains('function recommendationHistoryHtml(rows)')) {
        throw 'dashboard should render grouped recommendation history'
    }
    if (-not $dashboard.Contains("const historyRows = rows.filter(row => row.algorithmId !== 'ensemble')")) {
        throw 'recommendation history should exclude ensemble rows before grouping'
    }
    if (-not $dashboard.Contains('<details class="history-group"')) {
        throw 'recommendation history should use collapsible groups'
    }
    if (-not $dashboard.Contains("groups.slice(0, 30).map")) {
        throw 'recommendation history should limit grouped history by issue group'
    }
    if (-not $dashboard.Contains('function historyGroupDate(group)')) {
        throw 'recommendation history should display actual draw date for settled groups'
    }
    if (-not $dashboard.Contains('&#32508;&#21512;&#20027;&#25512;&#25112;&#32489;')) {
        throw 'dashboard should label ensemble-only stats clearly'
    }
    if (-not $dashboard.Contains('11&#31639;&#27861;&#25972;&#20307;&#25112;&#32489;')) {
        throw 'dashboard should render aggregate stats for eleven algorithms'
    }
    if (-not $dashboard.Contains('function renderWindow5()')) {
        throw 'dashboard should expose a five-issue window coverage renderer'
    }
    if (-not $dashboard.Contains('function renderThreeWindow5()')) {
        throw 'dashboard should expose a three-hit five-issue window renderer'
    }
    if (-not $dashboard.Contains('function renderPatternWatch()')) {
        throw 'dashboard should expose a pattern watch renderer'
    }
    if (-not $dashboard.Contains('function renderManualFetch()')) {
        throw 'dashboard should expose a manual fetch renderer'
    }
    if (-not $dashboard.Contains('function triggerManualFetch()')) {
        throw 'dashboard should trigger manual fetch API'
    }
    if (-not $dashboard.Contains('/api/manual-fetch')) {
        throw 'manual fetch should call the Vercel API endpoint'
    }
    if (-not $dashboard.Contains('&#25163;&#21160;&#37319;&#38598;') -or -not $dashboard.Contains('&#37319;&#38598;&#32593;&#22336;') -or -not $dashboard.Contains('&#31435;&#21363;&#37319;&#38598;')) {
        throw 'dashboard should render manual fetch labels'
    }
    if (-not $dashboard.Contains('function patternWatchAnalysis(source)')) {
        throw 'dashboard should calculate pattern watch metrics'
    }
    if (-not $dashboard.Contains('function optimizedSpecialPool(rows, basePool, size)')) {
        throw 'pattern watch should calculate optimized special-number pools'
    }
    if (-not $buildScript.Contains('function Get-OptimizedStableWindow5Pool') -or -not $buildScript.Contains('function Compare-Window5PoolScore')) {
        throw 'build-data.ps1 should optimize stable five-window pools using the same server-side scoring direction'
    }
    if ($dashboard.Contains('&#19977;&#20013;&#19977;&#32452;&#21512;&#27744;') -or $dashboard.Contains('&#19977;&#20013;&#19977;12&#32452;&#20248;&#21270;')) {
        throw 'pattern watch should not render obsolete three-hit combo pool sections'
    }
    if (-not $dashboard.Contains('function optimizationCompareRow(name, original, optimized, baseline)')) {
        throw 'pattern watch should compare original and optimized pool performance'
    }
    if (-not $dashboard.Contains('function patternScoreItem(name, original, optimized, baseline, sizeLabel)')) {
        throw 'pattern watch should calculate score table rows'
    }
    if (-not $dashboard.Contains('function patternScoreTable(analysis)')) {
        throw 'pattern watch should render a score summary table'
    }
    if (-not $dashboard.Contains('function patternDiagnosticsTable(analysis)')) {
        throw 'pattern watch should render pattern diagnostics'
    }
    if (-not $dashboard.Contains('function windowRhythmStats(windows)')) {
        throw 'pattern watch should calculate window rhythm stats'
    }
    if (-not $dashboard.Contains('function windowRhythmTable(analysis)')) {
        throw 'pattern watch should render window rhythm observation'
    }
    if (-not $dashboard.Contains('function failureProfileForWindow(item, context)')) {
        throw 'pattern watch should classify missed windows'
    }
    if (-not $dashboard.Contains('function failureProfileTable(analysis)')) {
        throw 'pattern watch should render failure profile observation'
    }
    if (-not $dashboard.Contains('function poolRelationTable(analysis)')) {
        throw 'pattern watch should render pool relation observation'
    }
    if (-not $dashboard.Contains('function triggerDecisionItem(name, item, context)')) {
        throw 'pattern watch should calculate trigger decision items'
    }
    if (-not $dashboard.Contains('function triggerDecisionTable(analysis)')) {
        throw 'pattern watch should render trigger decision summary'
    }
    if (-not $dashboard.Contains('&#26465;&#20214;&#35302;&#21457;&#24635;&#34920;')) {
        throw 'pattern watch should render trigger decision summary section'
    }
    if (-not $dashboard.Contains('&#35302;&#21457;&#35780;&#20998;') -or -not $dashboard.Contains('&#20027;&#35201;&#21152;&#20998;') -or -not $dashboard.Contains('&#20027;&#35201;&#25187;&#20998;') -or -not $dashboard.Contains('&#24378;&#36319;&#36394;')) {
        throw 'trigger decision summary should include score, plus/minus factors, and strong tracking action'
    }
    if (-not $dashboard.Contains('function poolRelationStats(windows)')) {
        throw 'pattern watch should calculate pool relation stats'
    }
    if (-not $dashboard.Contains('&#27744;&#23376;&#20851;&#31995;&#35266;&#23519;')) {
        throw 'pattern watch should render pool relation section'
    }
    if (-not $dashboard.Contains('&#20132;&#38598;&#21306;') -or -not $dashboard.Contains('&#24403;&#24180;&#29420;&#26377;') -or -not $dashboard.Contains('&#31283;&#23450;&#29420;&#26377;')) {
        throw 'pool relation should include special-number intersection and unique pools'
    }
    if (-not $dashboard.Contains('&#22833;&#36133;&#30011;&#20687;&#35266;&#23519;')) {
        throw 'pattern watch should render failure profile section'
    }
    if (-not $dashboard.Contains('&#26368;&#36817;&#28431;&#31383;') -or -not $dashboard.Contains('&#22833;&#36133;&#26631;&#31614;') -or -not $dashboard.Contains('&#26368;&#22823;&#39118;&#38505;&#26631;&#31614;')) {
        throw 'failure profile should include missed windows, failure tags, and largest risk tag'
    }
    if (-not $dashboard.Contains('&#31383;&#21475;&#33410;&#22863;&#35266;&#23519;')) {
        throw 'pattern watch should render window rhythm section'
    }
    if (-not $dashboard.Contains('&#39318;&#23614;&#26399;&#33410;&#22863;') -or -not $dashboard.Contains('&#28431;&#31383;&#21518;&#21453;&#24377;') -or -not $dashboard.Contains('&#36830;&#32493;&#35206;&#30422;&#34928;&#20943;')) {
        throw 'window rhythm should include hit timing, miss rebound, and consecutive coverage decay'
    }
    if ($dashboard.Contains('&#243弱;')) {
        throw 'window rhythm copy should not contain mixed malformed entity text'
    }
    if (-not $dashboard.Contains('function rollingWindowCompare(originalWindows, optimizedWindows)')) {
        throw 'pattern diagnostics should compare recent original and optimized windows'
    }
    if (-not $dashboard.Contains('function structureHealthForPattern(type, analysisItem)')) {
        throw 'pattern diagnostics should calculate structure health'
    }
    if (-not $dashboard.Contains('&#35268;&#24459;&#35786;&#26029;')) {
        throw 'pattern watch should render diagnostics section'
    }
    if (-not $dashboard.Contains('&#32467;&#26500;&#20581;&#24247;') -or -not $dashboard.Contains('&#36817;10&#31383;&#21475;&#32988;&#29575;') -or -not $dashboard.Contains('&#28431;&#31383;&#24674;&#22797;')) {
        throw 'pattern diagnostics should include structure health, rolling win rate, and miss recovery'
    }
    if (-not $dashboard.Contains('&#35268;&#24459;&#35780;&#20998;&#24635;&#34920;')) {
        throw 'pattern watch should render the pattern score summary'
    }
    if (-not $dashboard.Contains('&#24314;&#35758;&#21160;&#20316;')) {
        throw 'pattern watch score table should include suggested action'
    }
    if (-not $dashboard.Contains('&#31561;&#24453;&#31383;&#21475;&#32467;&#26463;') -or -not $dashboard.Contains('&#20248;&#20808;&#35266;&#23519;&#20248;&#21270;&#27744;') -or -not $dashboard.Contains('&#26242;&#20572;&#35813;&#35268;&#24459;')) {
        throw 'pattern watch score table should include actionable status labels'
    }
    if (-not $dashboard.Contains('&#35268;&#24459;&#20248;&#21270;&#27744;')) {
        throw 'pattern watch should render the optimized pool section'
    }
    if (-not $dashboard.Contains('&#21407;&#27744;&#19981;&#21160;')) {
        throw 'pattern watch should state original pools remain unchanged'
    }
    if (-not $dashboard.Contains('&#19977;&#20013;&#19977;&#22797;&#24335;&#27744;&#34920;&#29616;') -or -not $dashboard.Contains('&#22797;&#24335;&#27744;')) {
        throw 'pattern watch should render three-hit compound pool performance instead of combo pools'
    }
    if (-not $dashboard.Contains('function threeCompoundHistoryTable(pools)') -or -not $dashboard.Contains('&#19977;&#20013;&#19977;&#22797;&#24335;&#27744;&#21464;&#26356;&#35760;&#24405;')) {
        throw 'three-hit five-issue window should render compound pool change history'
    }
    if (-not $dashboard.Contains('&#21464;&#21270;&#25688;&#35201;') -or -not $dashboard.Contains('<details class="change-detail"') -or -not $dashboard.Contains('&#20445;&#30041;') -or -not $dashboard.Contains('&#26032;&#22686;') -or -not $dashboard.Contains('&#31227;&#38500;') -or -not $dashboard.Contains('&#26174;&#31034;&#20840;&#37096;&#35760;&#24405;')) {
        throw 'three-hit compound change history should show compact summaries with expandable kept, added, and removed details'
    }
    if (-not $dashboard.Contains('function randomWindowBaseline(pickCount, totalCount, drawsPerWindow)')) {
        throw 'dashboard should calculate random window baselines'
    }
    if (-not $dashboard.Contains('function patternLevel(edge, currentMiss, maxMiss)')) {
        throw 'dashboard should classify pattern observation levels'
    }
    if (-not $dashboard.Contains('const completed = windows.filter(item => Number(item.count || 0) >= 5)')) {
        throw 'pattern watch stats should only count completed five-issue windows'
    }
    if (-not $dashboard.Contains('if (edge < 0 || (maxMiss > 0 && currentMiss > maxMiss))')) {
        throw 'pattern watch should only mark invalid when current miss exceeds historical max or underperforms baseline'
    }
    if (-not $dashboard.Contains('function threeWindowAnalysis(source)')) {
        throw 'dashboard should calculate three-hit five-issue window analysis'
    }
    if (-not $dashboard.Contains('function buildThreeHitCompoundPools(records)')) {
        throw 'dashboard should build three-hit compound pools'
    }
    if (-not $dashboard.Contains('function threeHitCompoundWindowCoverage(rows, pool)')) {
        throw 'dashboard should evaluate three-hit compound pools by five-issue window'
    }
    if (-not $dashboard.Contains('function seededShuffleNumbers(seed)') -or -not $dashboard.Contains('function improveThreeHitCompoundPool(rows, startPool)')) {
        throw 'three-hit compound pools should use seeded multi-start local search instead of plain greedy only'
    }
    if (-not $dashboard.Contains('three-compound-local-search') -or -not $dashboard.Contains('randomSeeds.forEach')) {
        throw 'three-hit compound pool search should include deterministic random seeds'
    }
    if (-not $dashboard.Contains('const completedWindows = yearWindows.filter(item => Number(item.count || 0) >= 5)')) {
        throw 'three-hit five-issue stats should only count completed five-issue windows'
    }
    if (-not $dashboard.Contains('const trainingRows = yearRows.filter') -or -not $dashboard.Contains('Number(row.issue || 0) < currentStart') -or -not $dashboard.Contains('Number(row.issue || 0) > currentEnd')) {
        throw 'three-hit five-issue analysis should build compatibility combos without using current-window draw results'
    }
    if (-not $dashboard.Contains('compoundPools') -or -not $dashboard.Contains('{poolSize: 5}') -or -not $dashboard.Contains('{poolSize: 6}') -or -not $dashboard.Contains('{poolSize: 7}') -or -not $dashboard.Contains('{poolSize: 8}')) {
        throw 'three-hit five-issue window should compare 5/6/7/8 number compound pools'
    }
    if (-not $dashboard.Contains('threeCompoundState') -or -not $dashboard.Contains('stateItem?.pools')) {
        throw 'three-hit compound pools should be loaded from persisted state'
    }
    if (-not (Test-Path -LiteralPath (Join-Path $root 'build-three-compound.py'))) {
        throw 'three-hit compound pool builder script should exist'
    }
    if (-not $dashboard.Contains('&#19977;&#20013;&#19977;&#22797;&#24335;&#27744;&#23545;&#27604;')) {
        throw 'three-hit five-issue window page should show compound pool comparison'
    }
    if (-not $dashboard.Contains('function fiveWindowAnalysis(source)')) {
        throw 'dashboard should calculate five-issue window coverage analysis'
    }
    if (-not $dashboard.Contains('function greedyFiveWindowPool(windows)')) {
        throw 'dashboard should automatically recalculate the current-year five-window pool'
    }
    if (-not $dashboard.Contains('const maxWindow5PoolSize = 8') -or -not $dashboard.Contains('const maxStableWindow5PoolSize = 15') -or -not $dashboard.Contains('selected.length >= maxWindow5PoolSize')) {
        throw 'five-issue window pools should expose current-year and stable caps in the dashboard'
    }
    if ($dashboard.Contains("yearPool: ['40','42','19','34','27']") -or $dashboard.Contains("yearPool: ['01','27','37','16','23','29','12','10']")) {
        throw 'five-issue window current-year pool should not be hard-coded'
    }
    if (-not $dashboard.Contains('currentWindow') -or -not $dashboard.Contains('stablePool') -or -not $dashboard.Contains('yearPool')) {
        throw 'five-issue window page should expose current window, stable pool, and year pool'
    }
    if (-not $dashboard.Contains('adjustmentStatus') -or -not $dashboard.Contains('adjustmentReason')) {
        throw 'five-issue window page should show recalculation status and reason'
    }
    if (-not $dashboard.Contains('changeTime')) {
        throw 'five-issue window page should show coverage pool change time'
    }
    if (-not $dashboard.Contains('yearPoolHistory') -or -not $dashboard.Contains('function yearPoolHistoryTable')) {
        throw 'five-issue window page should expose current-year coverage pool change history'
    }
    if (-not $dashboard.Contains('&#35206;&#30422;&#27744;&#21464;&#26356;&#26085;&#24535;')) {
        throw 'five-issue window page should show coverage pool change log'
    }
    if ($dashboard.Contains('&#24050;&#37325;&#26032;&#35745;&#31639;')) {
        throw 'five-issue window status should use no-change/changed wording instead of recalculated'
    }
    if (-not $dashboard.Contains('stablePoolStatus') -or -not $dashboard.Contains('stablePoolChangeTime') -or -not $dashboard.Contains('stablePoolNextRecalcIssue')) {
        throw 'five-issue window page should show stable pool update status, change time, and next recalculation issue'
    }
    $windowStateFile = Join-Path $outDir 'data/window5-state.json'
    if (-not (Test-Path -LiteralPath $windowStateFile)) {
        throw 'window5-state.json was not created'
    }
    $windowState = Get-Content -LiteralPath $windowStateFile -Raw -Encoding UTF8 | ConvertFrom-Json
    $threeCompoundFile = Join-Path $outDir 'data/three-compound-state.json'
    if (-not (Test-Path -LiteralPath $threeCompoundFile)) {
        throw 'three-compound-state.json was not created'
    }
    $threeCompoundState = Get-Content -LiteralPath $threeCompoundFile -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach ($item in @($threeCompoundState.items)) {
        if (@($item.pools).Count -ne 4) {
            throw 'three-compound-state should include 5/6/7/8 pools for each source'
        }
        foreach ($poolItem in @($item.pools)) {
            if ($null -eq $poolItem.poolSize -or $null -eq $poolItem.pool -or $null -eq $poolItem.covered -or $null -eq $poolItem.total -or $null -eq $poolItem.hitRate -or $null -eq $poolItem.status -or $null -eq $poolItem.recentHitRate -or $null -eq $poolItem.currentMiss -or $null -eq $poolItem.maxMiss -or $null -eq $poolItem.healthStatus -or $null -eq $poolItem.changeHistory) {
                throw 'three-compound pool state should include size, pool, coverage, total, hit rate, status, health metrics, and change history'
            }
            foreach ($win in @($poolItem.windows)) {
                if ($null -eq $win.poolSnapshot) {
                    throw 'three-compound pool windows should include the effective pool snapshot'
                }
            }
        }
        foreach ($poolItem in @($item.crossYearPools)) {
            foreach ($win in @($poolItem.yearWindows)) {
                if ($null -eq $win.poolSnapshot) {
                    throw 'three-compound cross-year windows should include the effective pool snapshot'
                }
            }
        }
    }
    $threeCompoundScript = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'build-three-compound.py'), [Text.Encoding]::UTF8)
    if (-not $threeCompoundScript.Contains('"kept"') -or -not $threeCompoundScript.Contains('"added"') -or -not $threeCompoundScript.Contains('"removed"') -or -not $threeCompoundScript.Contains('"changeLevel"')) {
        throw 'three-compound builder should persist kept, added, removed, and change level for pool changes'
    }
    if (-not $threeCompoundScript.Contains('"normal-observe"') -or -not $threeCompoundScript.Contains('"no-change"') -or $threeCompoundScript.Contains('"正常观察"') -or $threeCompoundScript.Contains('"无变更"')) {
        throw 'three-compound builder should store ASCII status codes instead of localized text'
    }
    foreach ($item in @($windowState.items)) {
        if ($null -eq $item.stablePool -or $null -eq $item.stablePoolStatus -or $null -eq $item.stablePoolChangeTime -or $null -eq $item.stablePoolNextRecalcIssue -or $null -eq $item.stablePoolOptimizationStatus -or $null -eq $item.stablePoolOptimizationReason) {
            throw 'window5-state item should include stable pool state and optimization fields'
        }
        if (@($item.yearPool).Count -gt 8) {
            throw 'window5 current-year pool should be capped at eight numbers'
        }
        if ($null -eq $item.yearPoolHistory) {
            throw 'window5 current-year pool should include change history'
        }
        foreach ($historyItem in @($item.yearPoolHistory)) {
            if ($null -eq $historyItem.changedAt -or $null -eq $historyItem.beforePool -or $null -eq $historyItem.afterPool -or $null -eq $historyItem.added -or $null -eq $historyItem.removed -or $null -eq $historyItem.issue) {
                throw 'window5 current-year pool history should include time, before/after pools, added/removed numbers, and trigger issue'
            }
        }
        if (@($item.stablePool).Count -gt 15) {
            throw 'window5 stable pool should be capped at fifteen numbers'
        }
        if (@($item.stablePool | ForEach-Object { [string]$_ }) -contains '00') {
            throw 'window5 stable pool should not contain placeholder 00'
        }
    }
    if (-not $buildScript.Contains('$oldStablePool.Count -lt 15')) {
        throw 'window5 stable pool should recalculate when an old pool has fewer than fifteen numbers'
    }
    if (-not $buildScript.Contains('yearPoolHistory') -or -not $buildScript.Contains('$addedPoolNumbers') -or -not $buildScript.Contains('$removedPoolNumbers')) {
        throw 'window5 state should append current-year coverage pool change history'
    }
    if ($dashboard.Contains('<h2>&#35206;&#30422;&#27744;&#29366;&#24577;</h2>')) {
        throw 'five-issue window status should be displayed under current-year pool, not as a separate card'
    }
    if ($dashboard.Contains('forecastPredictions = data.forecasts') -or $dashboard.Contains('function forecastBacktestHtml(row)') -or $dashboard.Contains('function forecastStrategyPoolHtml(row)')) {
        throw 'forecast page helpers should not be emitted'
    }
    $gameSectionBody = [regex]::Match($dashboard, 'function gameSection\(source, game, title\) \{[\s\S]*?function renderGames').Value
    if ($dashboard.Contains('mirofish-sandbox') -or $dashboard.Contains('MiroFish') -or $gameSectionBody.Contains('MiroFish &#27801;&#30424;&#25512;&#28436;')) {
        throw 'dashboard should not include MiroFish sandbox logic or data'
    }
    if (-not $dashboard.Contains("targetRows.filter(row => row.algorithmId !== 'ensemble')")) {
        throw 'dashboard should calculate eleven algorithm stats from non-ensemble rows'
    }
    if (-not $dashboard.Contains('function gameGroupStats(rows, historicalMaxMiss = null)')) {
        throw 'dashboard should calculate grouped stats for eleven algorithms'
    }
    if (-not $dashboard.Contains('function historicalMaxMissForRecommendations(source, game, recommendations)')) {
        throw 'dashboard should calculate historical max miss from all source records'
    }
    if (-not $dashboard.Contains("const ensembleHistoricalMaxMiss = historicalMaxMissForRecommendations(source, game, ensemble ? [ensemble] : [])")) {
        throw 'ensemble max miss should be backtested against all historical records'
    }
    if (-not $dashboard.Contains('const algorithmHistoricalMaxMiss = historicalMaxMissForRecommendations(source, game, algorithms)')) {
        throw 'algorithm max miss should be backtested against all historical records'
    }
    if (-not $dashboard.Contains("maxMiss: historicalMaxMiss ??")) {
        throw 'stats cards should use historical max miss when available'
    }
    if (-not $dashboard.Contains("const algorithmStats = gameGroupStats(rows.filter(row => row.algorithmId !== 'ensemble'), algorithmHistoricalMaxMiss)")) {
        throw 'algorithm aggregate stats should use issue-level grouped non-ensemble rows'
    }
    if (-not $dashboard.Contains('hit: group.some(row => row.hit)')) {
        throw 'grouped algorithm stats should count an issue as hit when any algorithm hits'
    }
    $apiPath = Join-Path $PSScriptRoot 'api/manual-fetch.js'
    if (-not (Test-Path -LiteralPath $apiPath)) {
        throw 'manual fetch API endpoint should exist'
    }
    $apiScript = [IO.File]::ReadAllText($apiPath, [Text.Encoding]::UTF8)
    if (-not $apiScript.Contains('GITHUB_TOKEN') -or -not $apiScript.Contains('workflow_dispatch') -or -not $apiScript.Contains('manual-fetch.yml') -or -not $apiScript.Contains('am_source_url') -or -not $apiScript.Contains('hk_source_url')) {
        throw 'manual fetch API should dispatch the GitHub manual fetch workflow'
    }
    $workflowPath = Join-Path $PSScriptRoot '.github/workflows/manual-fetch.yml'
    if (-not (Test-Path -LiteralPath $workflowPath)) {
        throw 'manual fetch workflow should exist'
    }
    $manualWorkflow = [IO.File]::ReadAllText($workflowPath, [Text.Encoding]::UTF8)
    if (-not $manualWorkflow.Contains('workflow_dispatch') -or -not $manualWorkflow.Contains('am_source_url') -or -not $manualWorkflow.Contains('hk_source_url') -or -not $manualWorkflow.Contains('fetch-all.ps1')) {
        throw 'manual fetch workflow should accept Macau/Hong Kong URLs and run the unified fetch script'
    }
    if (-not $manualWorkflow.Contains('VERCEL_DEPLOY_HOOK_URL') -or -not $manualWorkflow.Contains('Invoke-RestMethod -Method Post')) {
        throw 'manual fetch workflow should trigger a Vercel deploy hook after pushing generated data'
    }
    $dailyWorkflowPath = Join-Path $PSScriptRoot '.github/workflows/daily-fetch.yml'
    $dailyWorkflow = [IO.File]::ReadAllText($dailyWorkflowPath, [Text.Encoding]::UTF8)
    if (-not $dailyWorkflow.Contains('fetch-all.ps1') -or $dailyWorkflow.Contains('-File .\build-data.ps1')) {
        throw 'daily fetch workflow should fetch both sources before rebuilding data'
    }
    if (-not $dailyWorkflow.Contains('VERCEL_DEPLOY_HOOK_URL') -or -not $dailyWorkflow.Contains('Invoke-RestMethod -Method Post')) {
        throw 'daily fetch workflow should trigger a Vercel deploy hook after pushing generated data'
    }
    $vercelConfigPath = Join-Path $PSScriptRoot 'vercel.json'
    $vercelConfig = Get-Content -LiteralPath $vercelConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if (@($vercelConfig.crons).Count -gt 1) {
        throw 'vercel.json should keep at most one cron schedule for Vercel Hobby deployments'
    }
    $fetchAllPath = Join-Path $PSScriptRoot 'fetch-all.ps1'
    if (-not (Test-Path -LiteralPath $fetchAllPath)) {
        throw 'unified fetch-all.ps1 script should exist'
    }
    $fetchAllScript = [IO.File]::ReadAllText($fetchAllPath, [Text.Encoding]::UTF8)
    if (-not $fetchAllScript.Contains('am.html') -or -not $fetchAllScript.Contains('hk.html') -or -not $fetchAllScript.Contains('build-data.ps1')) {
        throw 'fetch-all.ps1 should fetch Macau and Hong Kong then rebuild data once'
    }
    $fetchScript = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'fetch-am.ps1'), [Text.Encoding]::UTF8)
    if (-not $fetchScript.Contains('[switch]$SkipBuild')) {
        throw 'fetch-am.ps1 should support skipping build so fetch-all can rebuild once'
    }
    $installTaskScript = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'install-task.ps1'), [Text.Encoding]::UTF8)
    if (-not $installTaskScript.Contains('fetch-all.ps1')) {
        throw 'local scheduled task should run the unified fetch-all script'
    }
    $mojibakeMarker = [string][char]0x951F
    if ($dashboard.Contains($mojibakeMarker)) {
        throw 'dashboard contains mojibake marker'
    }
    if ($dashboard.Contains('&amp;#30721;') -or $dashboard.Contains('&amp;#32452;') -or $dashboard.Contains('&amp;#22855;') -or $dashboard.Contains('&amp;#20598;')) {
        throw 'pattern watch should not double-escape size or structure labels'
    }
    $runtimeCheck = @'
const fs = require('fs');
const html = fs.readFileSync(process.argv[2], 'utf8');
const json = JSON.parse(fs.readFileSync(process.argv[3], 'utf8'));
const script = html.match(/<script>\s*([\s\S]*?)\s*<\/script>\s*<\/body>/)[1]
  .replace(/const app = document.getElementById\('app'\);/, "const app = {innerHTML:''};")
  .replace(/const tabs = document.querySelectorAll\('\.tabs button'\);/, "const tabs = [];")
  .replace(/loadDashboardData\(\)\.then\([\s\S]*?\.catch\(err => \{\s*app\.innerHTML = `<section class="panel"><h2>&#25968;&#25454;&#21152;&#36733;&#22833;&#36133;<\/h2><p>\$\{esc\(err\.message\)\}<\/p><\/section>`;\s*\}\);/, "recentRecords = (__DATA__.records || []); summary = __DATA__.summary || {}; generatedPredictions = __DATA__.predictions || {next: [], sanzhong: []};")
  .replace(/document.getElementById\('overview-source'\)\.addEventListener\('change', renderOverview\);/g, '')
  .replace(/document.getElementById\('window5-source'\)\.addEventListener\('change', renderWindow5\);/g, '')
  .replace(/document.getElementById\('three-window5-source'\)\.addEventListener\('change', renderThreeWindow5\);/g, '')
  .replace(/document.getElementById\('pattern-source'\)\.addEventListener\('change', renderPatternWatch\);/g, '')
  .replace(/document.getElementById\('daily-source'\)\.addEventListener\('change', renderDaily\);/g, '')
  .replace(/document.getElementById\('game-source'\)\.addEventListener\('change', renderGames\);/g, '')
  .replace(/renderOverview\(\);/, "renderOverview(); fiveWindowAnalysis('am'); fiveWindowAnalysis('hk');");
global.__DATA__ = json;
global.location = { protocol: 'file:' };
global.document = { getElementById: () => ({ value: 'am', addEventListener() {}, textContent: JSON.stringify(json) }), querySelectorAll: () => [] };
new Function(script)();
console.log('RUNTIME_OK');
'@
    $runtimeOutput = $runtimeCheck | node - (Join-Path $outDir 'index.html') (Join-Path $outDir 'data/records.json')
    if ($LASTEXITCODE -ne 0 -or ($runtimeOutput -join "`n") -notmatch 'RUNTIME_OK') {
        throw "dashboard runtime check failed: $($runtimeOutput -join ' ')"
    }

    Write-Host 'PASS'
}
finally {
    if (Test-Path -LiteralPath $outDir) {
        Remove-Item -LiteralPath $outDir -Recurse -Force
    }
}
