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

$existingForecast = [pscustomobject]@{
    items = @(
        [pscustomobject]@{
            id = 'test-forecast-three-hit'
            source = 'hk'
            sourceName = 'hk'
            game = 'three-hit-three'
            gameName = 'three-hit-three'
            strategyId = 'vote-pool-v1'
            strategyName = 'vote-pool-v1'
            year = 2025
            displayYear = '2026'
            issue = 55
            targetDate = '2026-05-25'
            numbers = @(@('12', '23', '37'), @('01', '02', '03'))
            createdAt = '2026-05-24 21:45:00'
            status = 'pending'
        },
        [pscustomobject]@{
            id = 'test-forecast-special'
            source = 'hk'
            sourceName = 'hk'
            game = 'special-number'
            gameName = 'special-number'
            strategyId = 'vote-pool-v1'
            strategyName = 'vote-pool-v1'
            year = 2025
            displayYear = '2026'
            issue = 55
            targetDate = '2026-05-25'
            numbers = @('03', '18', '22', '27', '31', '44')
            createdAt = '2026-05-24 21:45:00'
            status = 'pending'
        }
    )
}
[IO.File]::WriteAllText((Join-Path $dataDir 'prediction-observations.json'), ($existingForecast | ConvertTo-Json -Depth 8), $utf8NoBom)

try {
    & $scriptPath -RootDir $outDir | Out-Null

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
    if (-not (Test-Path -LiteralPath (Join-Path $outDir 'dashboard.html'))) {
        throw 'dashboard.html was not created'
    }
    if (Test-Path -LiteralPath (Join-Path $outDir 'pattern-analysis.html')) {
        throw 'pattern analysis should stay inside dashboard instead of creating a standalone html file'
    }
    $dashboard = [IO.File]::ReadAllText((Join-Path $outDir 'dashboard.html'), [Text.Encoding]::UTF8)
    $indexHtml = [IO.File]::ReadAllText((Join-Path $outDir 'index.html'), [Text.Encoding]::UTF8)
    if (-not $indexHtml.Contains('data-tab="overview"') -or -not $indexHtml.Contains('id="manual-collect"')) {
        throw 'index.html should be the dashboard entry for root directory access'
    }
    if ($indexHtml -ne $dashboard) {
        throw 'index.html should match dashboard.html'
    }
    if (-not (Test-Path -LiteralPath (Join-Path $outDir 'kjjl.html'))) {
        throw 'kjjl.html lottery records page should be preserved'
    }
    if (-not $dashboard.Contains('href="kjjl.html"')) {
        throw 'dashboard should link back to kjjl.html'
    }
    if (-not $dashboard.Contains('data-tab="overview"') -or -not $dashboard.Contains('data-tab="games"') -or -not $dashboard.Contains('data-tab="daily"') -or -not $dashboard.Contains('data-tab="forecast"') -or -not $dashboard.Contains('data-tab="window5"') -or -not $dashboard.Contains('data-tab="threeWindow5"') -or -not $dashboard.Contains('data-tab="patternWatch"') -or -not $dashboard.Contains('data-tab="patternAnalysis"')) {
        throw 'dashboard should expose overview, games, forecast, 5-window, three-hit 5-window, coworker pattern watch, new pattern analysis, and daily tabs'
    }
    if (-not $dashboard.Contains('id="manual-collect"')) {
        throw 'dashboard should render manual collect button'
    }
    if (-not $dashboard.Contains("fetch('/api/collect'")) {
        throw 'dashboard should call collect API'
    }
    if (-not $dashboard.Contains("fetch('/api/data'")) {
        throw 'dashboard should load online data API when hosted'
    }
    $collectingText = '\u91c7\u96c6\u4e2d...'
    $collectDoneText = '\u91c7\u96c6\u5b8c\u6210\uff1a'
    $collectFailedText = '\u91c7\u96c6\u5931\u8d25\uff1a'
    if (-not $dashboard.Contains($collectingText) -or -not $dashboard.Contains($collectDoneText) -or -not $dashboard.Contains($collectFailedText)) {
        throw 'manual collect status should use readable Chinese text'
    }
    $badSingleQuoteEntity = 'status.textContent = ' + [char]39 + '&#'
    $badTemplateEntity = 'status.textContent = ' + [char]96 + '&#'
    if ($dashboard.Contains($badSingleQuoteEntity) -or $dashboard.Contains($badTemplateEntity)) {
        throw 'manual collect status should not display HTML entities as text'
    }
    if ($dashboard.Contains('data-tab="trend"') -or $dashboard.Contains('data-tab="picker"') -or $dashboard.Contains('data-tab="sandbox"')) {
        throw 'dashboard should not expose trend, picker, or sandbox modules'
    }
    if ($dashboard.Contains('function renderTrend') -or $dashboard.Contains('function renderPicker') -or $dashboard.Contains('function renderGame()') -or $dashboard.Contains('function renderSandbox()') -or $dashboard.Contains('function sandboxSection')) {
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
    if (-not $dashboard.Contains('"predictions":')) {
        throw 'collection-time predictions were not embedded'
    }
    if (-not $dashboard.Contains('"forecasts":')) {
        throw 'prediction observation data should be embedded'
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
            if ($rows.Count -ne 13) {
                throw "expected 13 recommendation rows for $source $game"
            }
            if (@($rows | Where-Object { $_.algorithmId -eq 'ensemble' }).Count -ne 1) {
                throw "expected ensemble recommendation for $source $game"
            }
            if (@($rows | Where-Object { $_.algorithmId -ne 'ensemble' -and $_.algorithmId -ne 'mirofish-sandbox' }).Count -ne 11) {
                throw "expected eleven algorithm recommendations for $source $game"
            }
            $miroFishRows = @($rows | Where-Object { $_.algorithmId -eq 'mirofish-sandbox' })
            if ($miroFishRows.Count -ne 1) {
                throw "expected one MiroFish sandbox recommendation for $source $game"
            }
            $expectedMiroFishCount = if ($game -eq 'three-hit-three') { 3 } else { 1 }
            if (@($miroFishRows[0].numbers).Count -ne $expectedMiroFishCount) {
                throw "unexpected MiroFish recommendation number count for $source $game"
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
    $forecastFile = Join-Path $outDir 'data/prediction-observations.json'
    if (-not (Test-Path -LiteralPath $forecastFile)) {
        throw 'prediction-observations.json was not created'
    }
    $forecastData = Get-Content -LiteralPath $forecastFile -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach ($source in @('am', 'hk')) {
        foreach ($game in @('three-hit-three', 'special-number')) {
            $latestForecast = @($forecastData.items |
                Where-Object { $_.source -eq $source -and $_.game -eq $game -and $_.id -notlike 'test-*' } |
                Sort-Object @{ Expression = 'targetDate'; Descending = $true }, @{ Expression = 'displayYear'; Descending = $true }, @{ Expression = 'issue'; Descending = $true } |
                Select-Object -First 1)
            if ($latestForecast.Count -eq 0) {
                throw "expected generated forecast for $source $game"
            }
            if ($game -eq 'three-hit-three' -and @($latestForecast[0].numbers).Count -ne 6) {
                throw "three-hit-three forecast should emit six groups for $source"
            }
            if ($game -eq 'three-hit-three') {
                foreach ($group in @($latestForecast[0].numbers)) {
                    $values = if ($null -ne $group.value) { @($group.value) } else { @($group) }
                    if (@($values).Count -ne 3) {
                        throw "three-hit-three forecast groups should contain three numbers for $source"
                    }
                }
            }
            if ($game -eq 'special-number' -and @($latestForecast[0].numbers).Count -ne 6) {
                throw "special-number forecast should emit six numbers for $source"
            }
            if ($game -eq 'special-number') {
                $sourceRecords = @($data.records | Where-Object { $_.source -eq $source } | Sort-Object @{ Expression = 'date'; Descending = $true }, @{ Expression = 'issue'; Descending = $true })
                $recentSpecials = @($sourceRecords | Select-Object -First 6 | ForEach-Object { ([int]$_.balls[6].numberText).ToString('00') })
                $forecastSpecials = @($latestForecast[0].numbers | ForEach-Object { ([int]$_).ToString('00') })
                if (($forecastSpecials -join ',') -eq ($recentSpecials -join ',')) {
                    throw "special-number forecast should not copy the latest six special results for $source"
                }
            }
            if ([string]::IsNullOrWhiteSpace([string]$latestForecast[0].selectedStrategy)) {
                throw "forecast should record selected strategy for $source $game"
            }
            if (@($latestForecast[0].strategyPool).Count -lt 5) {
                throw "forecast should evaluate a strategy pool for $source $game"
            }
            if ($null -eq $latestForecast[0].backtest -or [int]$latestForecast[0].backtest.tested -le 0) {
                throw "forecast should include rolling backtest for $source $game"
            }
            if ($null -eq $latestForecast[0].randomBaseline -or [int]$latestForecast[0].randomBaseline.tested -le 0) {
                throw "forecast should include random baseline for $source $game"
            }
            if ($null -eq $latestForecast[0].backtest.edgeVsRandom) {
                throw "forecast should include edge versus random baseline for $source $game"
            }
            $expectedOdds = if ($game -eq 'three-hit-three') { 650 } else { 47 }
            if ([int]$latestForecast[0].odds -ne $expectedOdds) {
                throw "forecast should record configured odds for $source $game"
            }
            if ($null -eq $latestForecast[0].backtest.netProfit -or $null -eq $latestForecast[0].backtest.roi -or $null -eq $latestForecast[0].backtest.totalStake -or $null -eq $latestForecast[0].backtest.totalPayout) {
                throw "forecast backtest should include stake, payout, net profit, and ROI for $source $game"
            }
            if ($null -eq $latestForecast[0].randomBaseline.netProfit -or $null -eq $latestForecast[0].randomBaseline.roi) {
                throw "forecast random baseline should include net profit and ROI for $source $game"
            }
            if ($null -eq $latestForecast[0].backtest.roiVsRandom) {
                throw "forecast should include ROI versus random for $source $game"
            }
            if ($null -eq $latestForecast[0].weekBacktest -or $null -eq $latestForecast[0].weekBacktest.netProfit -or $null -eq $latestForecast[0].weekBacktest.roi) {
                throw "forecast should include natural-week profitability backtest for $source $game"
            }
            if ([string]$latestForecast[0].weekBacktest.mode -ne 'natural-week-current-picks' -or [string]::IsNullOrWhiteSpace([string]$latestForecast[0].weekBacktest.weekStart) -or [string]::IsNullOrWhiteSpace([string]$latestForecast[0].weekBacktest.weekEnd)) {
                throw "forecast weekly gate should use natural week boundaries for $source $game"
            }
            if ($null -eq $latestForecast[0].walkForwardBacktest -or $null -eq $latestForecast[0].walkForwardBacktest.netProfit -or $null -eq $latestForecast[0].walkForwardBacktest.roi) {
                throw "forecast should include walk-forward profitability backtest for $source $game"
            }
            if ($null -eq $latestForecast[0].weeklyProfitGate -or [string]::IsNullOrWhiteSpace([string]$latestForecast[0].recommendationStatus)) {
                throw "forecast should include weekly profit gate and recommendation status for $source $game"
            }
            if ($latestForecast[0].weeklyProfitGate -and [int]$latestForecast[0].weekBacktest.netProfit -le 0) {
                throw "weekly profit gate should only pass when natural-week net profit is positive for $source $game"
            }
            if ($latestForecast[0].weeklyProfitGate -and [int]$latestForecast[0].walkForwardBacktest.netProfit -le 0) {
                throw "weekly profit gate should only pass when walk-forward net profit is positive for $source $game"
            }
            if (-not (@($latestForecast[0].strategyPool | ForEach-Object { $_.id }) -contains 'weekly-profit-guard')) {
                throw "forecast should evaluate weekly-profit-guard strategy for $source $game"
            }
            if ($null -eq $latestForecast[0].qualityScore -or [string]::IsNullOrWhiteSpace([string]$latestForecast[0].qualityLevel)) {
                throw "forecast should include quality score and level for $source $game"
            }
        }
    }
    $settledForecastThree = @($forecastData.items | Where-Object { $_.id -eq 'test-forecast-three-hit' })[0]
    if ($settledForecastThree.status -ne 'settled' -or -not $settledForecastThree.hit) {
        throw 'three-hit-three forecast should settle as hit when any observed group hits'
    }
    $settledForecastSpecial = @($forecastData.items | Where-Object { $_.id -eq 'test-forecast-special' })[0]
    if ($settledForecastSpecial.status -ne 'settled' -or -not $settledForecastSpecial.hit) {
        throw 'special-number forecast should settle as hit when any observed number hits'
    }
    foreach ($game in @('three-hit-three', 'special-number')) {
        $settled = @($forecastData.items | Where-Object { $_.source -eq 'hk' -and $_.game -eq $game -and $_.status -eq 'settled' -and [int]$_.actualIssue -eq 55 })
        $nextPending = @($forecastData.items | Where-Object { $_.source -eq 'hk' -and $_.game -eq $game -and $_.status -eq 'pending' -and [int]$_.issue -gt 55 } | Select-Object -First 1)
        if ($settled.Count -eq 0 -or $nextPending.Count -eq 0) {
            throw "forecast should settle opened issue and generate a new pending recommendation after draw for hk $game"
        }
    }
    $forecastEvalFile = Join-Path $outDir 'data/forecast-evaluation.json'
    if (-not (Test-Path -LiteralPath $forecastEvalFile)) {
        throw 'forecast-evaluation.json was not created'
    }
    $forecastEval = Get-Content -LiteralPath $forecastEvalFile -Raw -Encoding UTF8 | ConvertFrom-Json
    if (@($forecastEval.items).Count -ne 4) {
        throw 'forecast evaluation should summarize four source/game chains'
    }
    foreach ($item in @($forecastEval.items)) {
        if ([string]::IsNullOrWhiteSpace([string]$item.selectedStrategy) -or $null -eq $item.backtest -or $null -eq $item.randomBaseline -or $null -eq $item.edgeVsRandom) {
            throw 'forecast evaluation item should include selected strategy, backtest, random baseline, and edge'
        }
        if ($null -eq $item.odds -or $null -eq $item.backtest.roi -or $null -eq $item.roiVsRandom -or $null -eq $item.weekBacktest -or $null -eq $item.walkForwardBacktest -or $null -eq $item.qualityScore) {
            throw 'forecast evaluation item should include odds, weekly profit, walk-forward, quality, and ROI metrics'
        }
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
    if (-not $dashboard.Contains('normalizeNumberGroup(group).map')) {
        throw 'forecast copy text should use normalized number groups'
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
    if (-not $dashboard.Contains("const historyRows = rows.filter(row => row.algorithmId !== 'ensemble' && row.algorithmId !== 'mirofish-sandbox')")) {
        throw 'recommendation history should exclude ensemble and MiroFish rows before grouping'
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
    if (-not $dashboard.Contains('function renderForecast()')) {
        throw 'dashboard should expose a dedicated forecast renderer'
    }
    if (-not $dashboard.Contains('function renderWindow5()')) {
        throw 'dashboard should expose a five-issue window coverage renderer'
    }
    if (-not $dashboard.Contains('data-tab="threeWindow5"')) {
        throw 'dashboard should expose a three-hit-three five-issue window tab'
    }
    if (-not $dashboard.Contains('function renderThreeWindow5()')) {
        throw 'dashboard should expose a three-hit-three five-issue window renderer'
    }
    if (-not $dashboard.Contains('function renderPatternWatch()')) {
        throw 'dashboard should expose a pattern watch renderer'
    }
    if (-not $dashboard.Contains('function renderPatternAnalysis()')) {
        throw 'dashboard should expose the new pattern analysis renderer'
    }
    if (-not $dashboard.Contains('function qualityLevel(item)') -or -not $dashboard.Contains('function riskStatus(item)')) {
        throw 'new pattern analysis should separate long-term quality from current risk'
    }
    if (-not $dashboard.Contains('function patternRiskStats(windows)') -or -not $dashboard.Contains('previousMaxMiss')) {
        throw 'new pattern analysis should compare current miss against previous historical max miss'
    }
    if (-not $dashboard.Contains('const completed = windows.filter(item => Number(item.count || 0) >= 5)')) {
        throw 'pattern stats should only count completed five-issue windows'
    }
    if (-not $dashboard.Contains('&#38271;&#26399;&#36136;&#37327;') -or -not $dashboard.Contains('&#24403;&#21069;&#29366;&#24577;')) {
        throw 'new pattern analysis should expose long-term quality and current status columns'
    }
    $patternAnalysisBody = [regex]::Match($dashboard, 'function renderPatternAnalysis\(\) \{[\s\S]*?function renderDaily').Value
    if (-not $patternAnalysisBody.Contains('analysis.special.structure.colors') -or -not $patternAnalysisBody.Contains('analysis.special.structure.tails') -or -not $patternAnalysisBody.Contains('analysis.three.structure.spans') -or -not $patternAnalysisBody.Contains('analysis.three.structure.parity')) {
        throw 'new pattern analysis should include structure stats copied from pattern watch'
    }
    if (-not $patternAnalysisBody.Contains('&#29305;&#21035;&#21495;&#39068;&#33394;&#32467;&#26500;') -or -not $patternAnalysisBody.Contains('&#29305;&#21035;&#21495;&#23614;&#25968;&#32467;&#26500;') -or -not $patternAnalysisBody.Contains('&#19977;&#20013;&#19977;&#36328;&#24230;&#32467;&#26500;') -or -not $patternAnalysisBody.Contains('&#19977;&#20013;&#19977;&#22855;&#20598;&#32467;&#26500;')) {
        throw 'new pattern analysis should render the copied structure statistic sections'
    }
    if (-not $dashboard.Contains('function patternWatchAnalysis(source)')) {
        throw 'dashboard should calculate pattern watch metrics'
    }
    if (-not $dashboard.Contains('if (edge < 0 || (maxMiss > 0 && currentMiss > maxMiss))')) {
        throw 'pattern watch should only mark invalid when current miss exceeds historical max or underperforms baseline'
    }
    if (-not $dashboard.Contains('function optimizedSpecialPool(rows, basePool, size)')) {
        throw 'pattern watch should calculate optimized special-number pools'
    }
    if (-not $dashboard.Contains('function optimizedThreeCombos(rows, baseCombos, size)')) {
        throw 'pattern watch should calculate optimized three-hit combo pools'
    }
    if (-not $dashboard.Contains('function optimizationCompareRow(name, original, optimized, baseline)')) {
        throw 'pattern watch should compare original and optimized pool performance'
    }
    if (-not $dashboard.Contains('&#35268;&#24459;&#20248;&#21270;&#27744;') -or -not $dashboard.Contains('&#21407;&#27744;&#19981;&#21160;')) {
        throw 'pattern watch should render optimized pool comparison without changing original pools'
    }
    if (-not $dashboard.Contains('function randomWindowBaseline(pickCount, totalCount, drawsPerWindow)')) {
        throw 'dashboard should calculate random window baselines'
    }
    if (-not $dashboard.Contains('function patternLevel(edge, currentMiss, maxMiss)')) {
        throw 'dashboard should classify pattern observation levels'
    }
    if (-not $dashboard.Contains('function threeWindowAnalysis(source)')) {
        throw 'dashboard should calculate three-hit-three five-issue window analysis'
    }
    if (-not $dashboard.Contains('function buildThreeHitCombos(records)')) {
        throw 'dashboard should build ranked three-hit-three combinations'
    }
    if (-not $dashboard.Contains('function threeHitWindowCoverage(rows, combos)')) {
        throw 'dashboard should evaluate three-hit-three five-issue window coverage'
    }
    if (-not $dashboard.Contains('function fiveWindowAnalysis(source)')) {
        throw 'dashboard should calculate five-issue window coverage analysis'
    }
    if (-not $dashboard.Contains('function greedyFiveWindowPool(windows)')) {
        throw 'dashboard should automatically recalculate the current-year five-window pool'
    }
    if (-not $dashboard.Contains('const maxWindow5PoolSize = 8') -or -not $dashboard.Contains('const maxStableWindow5PoolSize = 15') -or -not $dashboard.Contains('selected.length >= maxWindow5PoolSize')) {
        throw 'five-issue window pools should be capped in dashboard logic'
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
    foreach ($item in @($windowState.items)) {
        if ($null -eq $item.stablePool -or $null -eq $item.stablePoolStatus -or $null -eq $item.stablePoolChangeTime -or $null -eq $item.stablePoolNextRecalcIssue) {
            throw 'window5-state item should include stable pool state fields'
        }
        if (@($item.yearPool).Count -gt 8) {
            throw 'window5 year pool should be capped at eight numbers'
        }
        if (@($item.stablePool).Count -gt 15) {
            throw 'window5 stable pool should be capped at fifteen numbers'
        }
        if (@($item.stablePool | ForEach-Object { [string]$_ }) -contains '00') {
            throw 'window5 stable pool should not contain placeholder 00'
        }
    }
    $buildScriptText = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'build-data.ps1'), [Text.Encoding]::UTF8)
    if (-not $buildScriptText.Contains('$oldStablePool.Count -lt 15')) {
        throw 'window5 stable pool should recalculate when an old pool has fewer than fifteen numbers'
    }
    if ($dashboard.Contains('<h2>&#35206;&#30422;&#27744;&#29366;&#24577;</h2>')) {
        throw 'five-issue window status should be displayed under current-year pool, not as a separate card'
    }
    if (-not $dashboard.Contains('function forecastSection(source, game, title)')) {
        throw 'dashboard should render forecast observations in a dedicated tab'
    }
    if (-not $dashboard.Contains('forecastPredictions = data.forecasts')) {
        throw 'dashboard should load forecast observations separately from games'
    }
    if (-not $dashboard.Contains('function forecastBacktestHtml(row)')) {
        throw 'forecast page should render backtest metrics'
    }
    if (-not $dashboard.Contains('function forecastStrategyPoolHtml(row)')) {
        throw 'forecast page should render evaluated strategy pool'
    }
    if (-not $dashboard.Contains('edgeVsRandom')) {
        throw 'forecast page should expose edge versus random baseline'
    }
    if (-not $dashboard.Contains('roiVsRandom') -or -not $dashboard.Contains('netProfit') -or -not $dashboard.Contains('totalPayout')) {
        throw 'forecast page should expose payout, net profit, ROI, and ROI versus random'
    }
    if (-not $dashboard.Contains('weeklyProfitGate') -or -not $dashboard.Contains('qualityScore') -or -not $dashboard.Contains('recommendationStatus')) {
        throw 'forecast page should expose weekly profit gate, quality score, and recommendation status'
    }
    $gameSectionBody = [regex]::Match($dashboard, 'function gameSection\(source, game, title\) \{[\s\S]*?function renderGames').Value
    if ($gameSectionBody.Contains('MiroFish &#27801;&#30424;&#25512;&#28436;')) {
        throw 'game module should not render MiroFish prediction cards'
    }
    if (-not $dashboard.Contains("targetRows.filter(row => row.algorithmId !== 'ensemble' && row.algorithmId !== 'mirofish-sandbox')")) {
        throw 'dashboard should exclude MiroFish from eleven algorithm stats'
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
    if (-not $dashboard.Contains("const algorithmStats = gameGroupStats(rows.filter(row => row.algorithmId !== 'ensemble' && row.algorithmId !== 'mirofish-sandbox'), algorithmHistoricalMaxMiss)")) {
        throw 'algorithm aggregate stats should use issue-level grouped non-ensemble rows'
    }
    if (-not $dashboard.Contains('hit: group.some(row => row.hit)')) {
        throw 'grouped algorithm stats should count an issue as hit when any algorithm hits'
    }
    $mojibakeMarker = [string][char]0x951F
    if ($dashboard.Contains($mojibakeMarker)) {
        throw 'dashboard contains mojibake marker'
    }
    if ($dashboard.Contains('&amp;#30721;') -or $dashboard.Contains('&amp;#32452;') -or $dashboard.Contains('&amp;#22855;') -or $dashboard.Contains('&amp;#20598;')) {
        throw 'pattern watch should not double-escape size or structure labels'
    }

    Write-Host 'PASS'
}
finally {
    if (Test-Path -LiteralPath $outDir) {
        Remove-Item -LiteralPath $outDir -Recurse -Force
    }
}
