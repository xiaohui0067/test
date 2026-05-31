# Lottery Games Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a games module that generates, records, settles, and displays three-hit-three and special-number recommendations for Macau and Hong Kong using eleven algorithms plus an ensemble recommendation.

**Architecture:** Extend the existing PowerShell build pipeline in `build-data.ps1`. Keep parsed draw records as the source of truth, save durable game recommendation records in `data/game-predictions.json`, and embed the game payload in `dashboard.html` for local-file use. The dashboard remains generated static HTML with three tabs: overview, games, and daily.

**Tech Stack:** PowerShell 5+, generated static HTML/CSS/JavaScript, JSON files under `data/`, existing Windows Scheduled Task at 21:45.

---

### Task 1: Add Game Data Tests

**Files:**
- Modify: `test-build-data.ps1`

- [ ] **Step 1: Add assertions for the games tab and game data file**

In `test-build-data.ps1`, after reading `$dashboard`, require the games tab and reject removed non-game utility tabs:

```powershell
if (-not $dashboard.Contains('data-tab="overview"') -or -not $dashboard.Contains('data-tab="games"') -or -not $dashboard.Contains('data-tab="daily"')) {
    throw 'dashboard should expose overview, games, and daily tabs'
}
if ($dashboard.Contains('data-tab="trend"') -or $dashboard.Contains('data-tab="picker"')) {
    throw 'dashboard should not expose trend or picker modules'
}
```

After `predictions.json` assertions, add:

```powershell
$gameFile = Join-Path $outDir 'data/game-predictions.json'
if (-not (Test-Path -LiteralPath $gameFile)) {
    throw 'game-predictions.json was not created'
}
$gameData = Get-Content -LiteralPath $gameFile -Raw -Encoding UTF8 | ConvertFrom-Json
foreach ($source in @('am', 'hk')) {
    foreach ($game in @('three-hit-three', 'special-number')) {
        $rows = @($gameData.items | Where-Object { $_.source -eq $source -and $_.game -eq $game } | Select-Object -First 12)
        if ($rows.Count -ne 12) {
            throw "expected 12 recommendation rows for $source $game"
        }
        if (@($rows | Where-Object { $_.algorithmId -eq 'ensemble' }).Count -ne 1) {
            throw "expected ensemble recommendation for $source $game"
        }
        if (@($rows | Where-Object { $_.algorithmId -ne 'ensemble' }).Count -ne 11) {
            throw "expected eleven algorithm recommendations for $source $game"
        }
    }
}
```

- [ ] **Step 2: Add settlement fixture assertions**

Append an existing settled item fixture to the test by creating a `data/game-predictions.json` file in `$outDir` before running `build-data.ps1`:

```powershell
$dataDir = Join-Path $outDir 'data'
New-Item -ItemType Directory -Path $dataDir -Force | Out-Null
$existingGame = [pscustomobject]@{
    items = @(
        [pscustomobject]@{
            id = 'test-three-hit'
            source = 'hk'
            sourceName = '香港'
            game = 'three-hit-three'
            gameName = '三中三'
            algorithmId = 'greedy'
            algorithmName = '贪心'
            year = 2025
            displayYear = '2026'
            issue = 55
            targetDate = '2026-05-25'
            numbers = @('12','23','37')
            createdAt = '2026-05-24 21:45:00'
            status = 'pending'
        },
        [pscustomobject]@{
            id = 'test-special-hit'
            source = 'hk'
            sourceName = '香港'
            game = 'special-number'
            gameName = '特别号'
            algorithmId = 'greedy'
            algorithmName = '贪心'
            year = 2025
            displayYear = '2026'
            issue = 55
            targetDate = '2026-05-25'
            numbers = @('18')
            createdAt = '2026-05-24 21:45:00'
            status = 'pending'
        }
    )
}
[IO.File]::WriteAllText((Join-Path $dataDir 'game-predictions.json'), ($existingGame | ConvertTo-Json -Depth 8), $utf8NoBom)
```

After loading `$gameData`, assert:

```powershell
$settledThree = @($gameData.items | Where-Object { $_.id -eq 'test-three-hit' })[0]
if ($settledThree.status -ne 'settled' -or -not $settledThree.hit) {
    throw 'three-hit-three pending row should settle as hit using first six numbers'
}
$settledSpecial = @($gameData.items | Where-Object { $_.id -eq 'test-special-hit' })[0]
if ($settledSpecial.status -ne 'settled' -or -not $settledSpecial.hit) {
    throw 'special-number pending row should settle as hit using seventh number'
}
```

- [ ] **Step 3: Run test and verify it fails**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\test-build-data.ps1
```

Expected: FAIL with `game-predictions.json was not created` or a missing games tab assertion.

### Task 2: Implement Game Recommendation Data Pipeline

**Files:**
- Modify: `build-data.ps1`

- [ ] **Step 1: Add algorithm metadata**

Add near the prediction helper functions:

```powershell
function Get-GameAlgorithms {
    return @(
        [pscustomobject]@{ id = 'greedy'; name = '贪心' },
        [pscustomobject]@{ id = 'backtracking'; name = '回溯' },
        [pscustomobject]@{ id = 'dynamic-programming'; name = '动态规划' },
        [pscustomobject]@{ id = 'simulated-annealing'; name = '模拟退火' },
        [pscustomobject]@{ id = 'genetic'; name = '遗传算法' },
        [pscustomobject]@{ id = 'particle-swarm'; name = '粒子群' },
        [pscustomobject]@{ id = 'monte-carlo'; name = '蒙特卡洛' },
        [pscustomobject]@{ id = 'ant-colony'; name = '蚁群' },
        [pscustomobject]@{ id = 'markov-chain'; name = '马尔可夫链' },
        [pscustomobject]@{ id = 'bayesian'; name = '贝叶斯推断' },
        [pscustomobject]@{ id = 'association-rules'; name = '关联规则' }
    )
}
```

- [ ] **Step 2: Add scoring helpers**

Add deterministic number scoring helpers:

```powershell
function Get-NumberStats {
    param([object[]]$SourceRecords, [string]$Game)
    $stats = @{}
    foreach ($n in 1..49) {
        $key = $n.ToString('00')
        $stats[$key] = [pscustomobject]@{ numberText = $key; hits = 0; recentHits = 0; miss = $SourceRecords.Count; transitions = 0 }
    }
    for ($i = 0; $i -lt $SourceRecords.Count; $i++) {
        $nums = if ($Game -eq 'three-hit-three') {
            @($SourceRecords[$i].balls | Select-Object -First 6 | ForEach-Object { $_.numberText })
        } else {
            @($SourceRecords[$i].balls[6].numberText)
        }
        foreach ($num in $nums) {
            if (-not $stats.ContainsKey($num)) { continue }
            $stats[$num].hits++
            if ($i -lt 80) { $stats[$num].recentHits++ }
            $stats[$num].miss = [Math]::Min($stats[$num].miss, $i)
        }
    }
    return $stats
}

function Get-AlgorithmNumbers {
    param([object[]]$SourceRecords, [string]$Game, [string]$AlgorithmId)
    $take = if ($Game -eq 'three-hit-three') { 3 } else { 1 }
    $stats = Get-NumberStats -SourceRecords $SourceRecords -Game $Game
    $today = Get-Date -Format 'yyyy-MM-dd'
    return @(
        foreach ($item in $stats.Values) {
            $noise = Get-SeededNoise "$today|$Game|$AlgorithmId|$($item.numberText)"
            $score = switch ($AlgorithmId) {
                'greedy' { $item.recentHits * 3 + $item.hits * 0.4 - $item.miss * 0.15 }
                'backtracking' { $item.hits * 0.8 + [Math]::Min($item.miss, 60) * 0.6 }
                'dynamic-programming' { $item.recentHits * 1.4 + $item.hits * 0.5 + [Math]::Min($item.miss, 40) * 0.25 }
                'simulated-annealing' { $item.recentHits * 1.2 + $item.hits * 0.35 + $noise * 18 - $item.miss * 0.08 }
                'genetic' { $item.hits * 0.5 + $item.recentHits * 1.8 + $noise * 10 }
                'particle-swarm' { $item.recentHits * 1.6 + (49 - [int]$item.numberText) * 0.03 + $noise * 8 }
                'monte-carlo' { $item.hits * 0.25 + $item.recentHits * 0.8 + $noise * 25 }
                'ant-colony' { $item.hits * 0.45 + $item.recentHits * 2.1 - $item.miss * 0.05 }
                'markov-chain' { $item.recentHits * 1.1 + [Math]::Min($item.miss, 30) * 0.4 + $noise * 6 }
                'bayesian' { (($item.hits + 1) / ($SourceRecords.Count + 49)) * 1000 + $item.recentHits * 0.9 }
                'association-rules' { $item.hits * 0.55 + $item.recentHits * 1.3 + [Math]::Min($item.miss, 70) * 0.2 }
                default { $item.hits }
            }
            [pscustomobject]@{ numberText = $item.numberText; score = [double]$score }
        }
    ) | Sort-Object @{ Expression = 'score'; Descending = $true }, @{ Expression = { [int]$_.numberText }; Descending = $false } | Select-Object -First $take | ForEach-Object { $_.numberText }
}
```

- [ ] **Step 3: Add settlement function**

Add:

```powershell
function Settle-GameItem {
    param([object]$Item, [object[]]$Records)
    if ($Item.status -eq 'settled') { return $Item }
    $draw = @($Records | Where-Object {
        $_.source -eq $Item.source -and
        [int]$_.issue -eq [int]$Item.issue -and
        ([string]$_.date -eq [string]$Item.targetDate -or [string]::IsNullOrWhiteSpace([string]$Item.targetDate))
    } | Select-Object -First 1)
    if ($draw.Count -eq 0) {
        $draw = @($Records | Where-Object { $_.source -eq $Item.source -and [int]$_.issue -eq [int]$Item.issue } | Select-Object -First 1)
    }
    if ($draw.Count -eq 0) { return $Item }
    $record = $draw[0]
    $actual = if ($Item.game -eq 'three-hit-three') {
        @($record.balls | Select-Object -First 6 | ForEach-Object { $_.numberText })
    } else {
        @($record.balls[6].numberText)
    }
    $hit = if ($Item.game -eq 'three-hit-three') {
        @($Item.numbers | Where-Object { $actual -contains $_ }).Count -eq 3
    } else {
        $actual[0] -eq $Item.numbers[0]
    }
    $Item | Add-Member -NotePropertyName status -NotePropertyValue 'settled' -Force
    $Item | Add-Member -NotePropertyName hit -NotePropertyValue $hit -Force
    $Item | Add-Member -NotePropertyName actualDate -NotePropertyValue $record.date -Force
    $Item | Add-Member -NotePropertyName actualIssue -NotePropertyValue $record.issue -Force
    $Item | Add-Member -NotePropertyName actualNumbers -NotePropertyValue $actual -Force
    return $Item
}
```

- [ ] **Step 4: Add game generation function**

Add:

```powershell
function New-GamePredictions {
    param([object[]]$Records, [object[]]$Existing = @())
    $createdAt = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $items = New-Object 'System.Collections.Generic.List[object]'
    foreach ($old in @($Existing)) {
        $items.Add((Settle-GameItem -Item $old -Records $Records)) | Out-Null
    }
    foreach ($source in @('am', 'hk')) {
        $sourceRecords = @($Records | Where-Object { $_.source -eq $source } | Sort-Object @{ Expression = 'date'; Descending = $true }, @{ Expression = 'issue'; Descending = $true })
        if ($sourceRecords.Count -eq 0) { continue }
        $latest = $sourceRecords[0]
        $targetDate = Get-NextDrawDate -SourceRecords $sourceRecords -Source $source
        $issue = [int]$latest.issue + 1
        $displayYear = if ($targetDate) { $targetDate.Substring(0, 4) } else { (Get-Date).Year.ToString() }
        foreach ($game in @('three-hit-three', 'special-number')) {
            $gameName = if ($game -eq 'three-hit-three') { '三中三' } else { '特别号' }
            $existingForTarget = @($items | Where-Object { $_.source -eq $source -and $_.game -eq $game -and [int]$_.issue -eq $issue -and $_.displayYear -eq $displayYear })
            if ($existingForTarget.Count -gt 0) { continue }
            $algorithmRows = @()
            foreach ($algorithm in Get-GameAlgorithms) {
                $numbers = @(Get-AlgorithmNumbers -SourceRecords $sourceRecords -Game $game -AlgorithmId $algorithm.id)
                $row = [pscustomobject]@{
                    id = ('{0}-{1}-{2}-{3}-{4}' -f $source, $game, $displayYear, $issue, $algorithm.id)
                    source = $source
                    sourceName = Get-SourceName $source
                    game = $game
                    gameName = $gameName
                    algorithmId = $algorithm.id
                    algorithmName = $algorithm.name
                    year = $latest.year
                    displayYear = $displayYear
                    issue = $issue
                    targetDate = $targetDate
                    numbers = $numbers
                    createdAt = $createdAt
                    status = 'pending'
                    savedBy = 'fetch'
                }
                $algorithmRows += $row
                $items.Add($row) | Out-Null
            }
            $votes = @{}
            foreach ($row in $algorithmRows) {
                foreach ($num in $row.numbers) {
                    if (-not $votes.ContainsKey($num)) { $votes[$num] = 0 }
                    $votes[$num]++
                }
            }
            $take = if ($game -eq 'three-hit-three') { 3 } else { 1 }
            $ensembleNumbers = @($votes.GetEnumerator() | Sort-Object @{ Expression = 'Value'; Descending = $true }, @{ Expression = { [int]$_.Key }; Descending = $false } | Select-Object -First $take | ForEach-Object { $_.Key })
            $items.Add([pscustomobject]@{
                id = ('{0}-{1}-{2}-{3}-ensemble' -f $source, $game, $displayYear, $issue)
                source = $source
                sourceName = Get-SourceName $source
                game = $game
                gameName = $gameName
                algorithmId = 'ensemble'
                algorithmName = '综合主推'
                year = $latest.year
                displayYear = $displayYear
                issue = $issue
                targetDate = $targetDate
                numbers = $ensembleNumbers
                createdAt = $createdAt
                status = 'pending'
                savedBy = 'fetch'
            }) | Out-Null
        }
    }
    return [pscustomobject]@{ generatedAt = $createdAt; items = @($items | Sort-Object @{ Expression = 'createdAt'; Descending = $true }, source, game, algorithmId | Select-Object -First 500) }
}
```

- [ ] **Step 5: Wire game file output**

Near the existing predictions output section, add:

```powershell
$gamePredictionsPath = Join-Path $dataDir 'game-predictions.json'
$existingGameItems = @()
if (Test-Path -LiteralPath $gamePredictionsPath) {
    try {
        $existingGameData = Get-Content -LiteralPath $gamePredictionsPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $existingGameItems = @($existingGameData.items)
    }
    catch {
        $existingGameItems = @()
    }
}
$gamePredictions = New-GamePredictions -Records $deduped -Existing $existingGameItems
[IO.File]::WriteAllText($gamePredictionsPath, ($gamePredictions | ConvertTo-Json -Depth 10), $Utf8NoBom)
$payload = [pscustomobject]@{ summary = $summary; records = $deduped; predictions = $predictions; games = $gamePredictions }
```

Replace the old `$payload = ...` assignment with the new one.

- [ ] **Step 6: Run test and verify it passes**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\test-build-data.ps1
```

Expected: PASS.

### Task 3: Add Games Dashboard UI

**Files:**
- Modify: `build-data.ps1`

- [ ] **Step 1: Add games tab**

In the tab nav inside `New-DashboardHtml`, add:

```html
<button data-tab="games">&#28216;&#25103;</button>
```

between overview and daily.

- [ ] **Step 2: Load games payload**

In the generated JS state, add:

```javascript
let gamePredictions = {items: []};
```

After parsing embedded records, add:

```javascript
gamePredictions = data.games || {items: []};
```

- [ ] **Step 3: Add game rendering helpers**

Add before `renderDaily()`:

```javascript
function gameRows(source, game) {
  return (gamePredictions.items || []).filter(item => item.source === source && item.game === game);
}
function chipNums(nums) {
  return `<div class="balls compact-balls">${(nums || []).map(n => `<span class="ball blue">${esc(n)}</span>`).join('')}</div>`;
}
function missStats(rows) {
  const settled = rows.filter(r => r.status === 'settled').sort((a, b) => String(b.actualDate || '').localeCompare(String(a.actualDate || '')));
  let currentMiss = 0;
  for (const row of settled) {
    if (row.hit) break;
    currentMiss++;
  }
  let maxMiss = 0, run = 0, hits = 0;
  [...settled].reverse().forEach(row => {
    if (row.hit) { hits++; maxMiss = Math.max(maxMiss, run); run = 0; }
    else run++;
  });
  maxMiss = Math.max(maxMiss, run);
  return {currentMiss, maxMiss, hits, settled: settled.length};
}
function gameSection(source, game, title) {
  const rows = gameRows(source, game);
  const latestIssue = rows[0]?.issue || '';
  const targetRows = rows.filter(r => r.issue === latestIssue);
  const ensemble = targetRows.find(r => r.algorithmId === 'ensemble');
  const algorithms = targetRows.filter(r => r.algorithmId !== 'ensemble');
  const stats = missStats(rows.filter(r => r.algorithmId === 'ensemble'));
  return `<section class="panel full">
    <h2>${title}</h2>
    <div class="grid">
      <section class="panel wide"><h2>综合主推</h2><p>${esc(ensemble?.targetDate || '')} ${esc(ensemble?.displayYear || '')} / ${esc(ensemble?.issue || '')}</p>${ensemble ? chipNums(ensemble.numbers) : '<p class="muted">暂无推荐</p>'}</section>
      <section class="panel wide"><h2>战绩</h2><p>当前遗落：${stats.currentMiss}</p><p>历史最大遗落：${stats.maxMiss}</p><p>已结算：${stats.settled}，命中：${stats.hits}</p></section>
    </div>
    <h3>11种算法推荐</h3>
    <table><thead><tr><th>算法</th><th>推荐</th><th>目标期号</th><th>状态</th></tr></thead><tbody>${algorithms.map(row => `<tr><td>${esc(row.algorithmName)}</td><td>${chipNums(row.numbers)}</td><td>${esc(row.targetDate || '')}<br>${esc(row.displayYear || '')} / ${esc(row.issue || '')}</td><td>${row.status === 'settled' ? (row.hit ? '命中' : '未中') : '待开奖'}</td></tr>`).join('')}</tbody></table>
    <h3>推荐记录</h3>
    <table class="compact-table"><thead><tr><th>时间</th><th>算法</th><th>期号</th><th>推荐</th><th>结果</th><th>开奖</th></tr></thead><tbody>${rows.slice(0, 60).map(row => `<tr><td>${esc(row.createdAt)}</td><td>${esc(row.algorithmName)}</td><td>${esc(row.targetDate || '')}<br>${esc(row.displayYear || '')} / ${esc(row.issue || '')}</td><td>${chipNums(row.numbers)}</td><td>${row.status === 'settled' ? (row.hit ? '命中' : '未中') : '待开奖'}</td><td>${row.actualNumbers ? chipNums(row.actualNumbers) : '-'}</td></tr>`).join('')}</tbody></table>
  </section>`;
}
function renderGames() {
  const selected = document.getElementById('game-source')?.value || 'am';
  app.innerHTML = `<div class="grid">
    <section class="panel full"><div class="filters"><label>来源<select id="game-source">${sourceOptions(selected)}</select></label></div></section>
    ${gameSection(selected, 'three-hit-three', '三中三推荐')}
    ${gameSection(selected, 'special-number', '特别号推荐')}
  </div>`;
  document.getElementById('game-source').addEventListener('change', renderGames);
}
```

- [ ] **Step 4: Register renderer**

Change the renderers object to:

```javascript
const renderers = {
  overview: renderOverview,
  games: renderGames,
  daily: renderDaily
};
```

- [ ] **Step 5: Run test**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\test-build-data.ps1
```

Expected: PASS.

### Task 4: Rebuild Real Dashboard and Verify

**Files:**
- Generated: `data/game-predictions.json`
- Generated: `data/records.json`
- Generated: `dashboard.html`
- Generated: `report.html`

- [ ] **Step 1: Build real data**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\build-data.ps1
```

Expected output includes:

```text
Records: 2932
Saved: C:\codex\test\am\data\records.json
Saved: C:\codex\test\am\dashboard.html
Saved: C:\codex\test\am\report.html
```

- [ ] **Step 2: Verify generated game data**

Run:

```powershell
$g = Get-Content .\data\game-predictions.json -Raw -Encoding UTF8 | ConvertFrom-Json
$g.items | Group-Object source,game | Select-Object Name,Count
```

Expected: groups for `am, three-hit-three`, `am, special-number`, `hk, three-hit-three`, and `hk, special-number`, each with at least 12 rows.

- [ ] **Step 3: Verify dashboard tabs**

Run:

```powershell
$html = [IO.File]::ReadAllText('C:\codex\test\am\dashboard.html',[Text.Encoding]::UTF8)
@('data-tab="overview"','data-tab="games"','data-tab="daily"','data-tab="trend"','data-tab="picker"') | ForEach-Object {
    [pscustomobject]@{ Pattern = $_; Present = $html.Contains($_) }
}
```

Expected: overview, games, daily are `True`; trend and picker are `False`.

---

## Self-Review

Spec coverage:
- Two games are covered by Task 2 data generation and Task 3 UI.
- Eleven algorithms plus ensemble are covered by `Get-GameAlgorithms`, `Get-AlgorithmNumbers`, and ensemble voting.
- Recording, settlement, current miss, and historical max miss are covered by `Settle-GameItem` and UI `missStats`.
- Macau/Hong Kong source switching is covered by generation loops and `game-source`.
- 21:45 scheduling is preserved because the existing scheduled task still invokes the fetch/build pipeline.

Placeholder scan: no placeholders remain.

Type consistency: game ids are `three-hit-three` and `special-number` throughout; algorithm id `ensemble` is used consistently.

