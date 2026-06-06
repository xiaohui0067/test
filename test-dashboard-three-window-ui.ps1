$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$htmlPath = Join-Path $root 'index.html'

if (-not (Test-Path -LiteralPath $htmlPath)) {
    throw 'index.html was not generated'
}

$html = Get-Content -LiteralPath $htmlPath -Raw

if ($html -notmatch 'data-tab="betting"' -or $html -notmatch '&#19979;&#27880;&#25512;&#33616;') {
    throw 'expected dashboard to expose betting recommendation as the first tab'
}

if ($html -notmatch 'function bettingRecommendationAnalysis' -or $html -notmatch 'function renderBetting' -or $html -notmatch '&#29305;&#21035;&#21495;&#20027;&#25512;1&#30721;' -or $html -notmatch '&#38450;8&#30721;' -or $html -notmatch '&#19977;&#20013;&#19977;&#20027;&#25512;3&#30721;' -or $html -notmatch '&#38450;5&#30721;') {
    throw 'expected dashboard to render low-cost primary picks and guard pools'
}

if ($html -notmatch '&#19979;&#27880;' -or $html -notmatch '&#23567;&#27880;' -or $html -notmatch '&#35266;&#26395;' -or $html -notmatch '&#26242;&#20572;') {
    throw 'expected betting recommendations to include bet, small bet, observe, and pause levels'
}

if ($html -notmatch 'function bettingPoolReviewStats' -or $html -notmatch 'specialPoolReviewGroups' -or $html -notmatch 'threePoolReviewGroups') {
    throw 'expected betting review to recalculate hits from the displayed pools instead of old single-number recommendation rows'
}

if ($html -notmatch 'poolSnapshotForIssue' -or $html -notmatch 'currentHit' -or $html -notmatch '&#20027;&#25512;&#32467;&#26524;' -or $html -notmatch '&#38450;&#30721;&#32467;&#26524;') {
    throw 'expected betting pool review to separate primary and guard snapshot results'
}

if ($html -notmatch 'function bettingRecommendationSnapshot' -or $html -notmatch 'function settleBettingSnapshot' -or $html -notmatch 'bettingSnapshotReviewGroups') {
    throw 'expected betting recommendations to use immutable recommendation snapshots'
}

if ($html -notmatch 'snapshot\.primaryPool' -or $html -notmatch 'snapshot\.guardPool' -or $html -notmatch 'matched\.length >= 3' -or $html -notmatch '&#20027;&#25512;&#32467;&#26524;' -or $html -notmatch '&#38450;&#30721;&#32467;&#26524;') {
    throw 'expected betting settlement to use primary and guard snapshot pools'
}

if ($html -notmatch 'function bettingRiskGate' -or $html -notmatch 'snapshotReview' -or $html -notmatch 'insufficient-sample' -or $html -notmatch 'weak-snapshot-review') {
    throw 'expected betting recommendations to apply strict snapshot-based risk gates'
}

if ($html -notmatch 'function bettingDecisionScore' -or $html -notmatch 'singleDrawBaseline' -or $html -notmatch '&#20915;&#31574;&#20998;' -or $html -notmatch 'strongDecisionFloor') {
    throw 'expected betting recommendations to use calibrated decision scores instead of raw low observation scores'
}

if ($html -notmatch 'function ensureBettingSnapshots' -or $html -notmatch '__BETTING_SNAPSHOTS__' -or $html -notmatch 'persistedBettingSnapshotReviewGroups') {
    throw 'expected betting recommendations to load persisted snapshot ledger before rendering'
}

if ($html -notmatch 'function recentWindowStats') {
    throw 'expected dashboard to compute recent window stats when persisted recent fields are missing'
}

if ($html -notmatch 'function nextOpenWindowStart' -or $html -notmatch 'nextOpenWindowStart\(latestIssue, yearWindows\)' -or $html -notmatch 'nextOpenWindowStart\(latestIssue, yearWindows, 5\)') {
    throw 'expected five-issue windows to advance to the next open window after a completed window'
}

if ($html -notmatch 'threeWindowAnalysisCache') {
    throw 'expected dashboard to cache three-window analysis per source'
}

if ($html -notmatch 'threeWindowHtmlCache') {
    throw 'expected dashboard to cache rendered three-window HTML per source'
}

if ($html -match "recentCovered \?\? '-'") {
    throw 'expected dashboard to avoid placeholder recent window stats in three-compound tables'
}

$threeLoaderPattern = 'threeWindow5:\s*async\s*\(\)\s*=>\s*\{(?<body>[\s\S]*?)\n\s*\}'
$threeLoader = [regex]::Match($html, $threeLoaderPattern)
if (-not $threeLoader.Success) {
    throw 'expected dashboard to define a threeWindow5 tab loader'
}

if ($threeLoader.Groups['body'].Value -match 'ensureRecordsData') {
    throw 'expected threeWindow5 tab to avoid loading full records data before first render'
}

$windowLoaderPattern = 'window5:\s*async\s*\(\)\s*=>\s*\{(?<body>[\s\S]*?)\n\s*\}'
$windowLoader = [regex]::Match($html, $windowLoaderPattern)
if (-not $windowLoader.Success) {
    throw 'expected dashboard to define a window5 tab loader'
}

if ($windowLoader.Groups['body'].Value -match 'ensureRecordsData') {
    throw 'expected window5 tab to avoid loading full records data before first render'
}

if ($html -notmatch 'window5-detail-toggle') {
    throw 'expected heavy window5 detail tables to render behind explicit toggles'
}

if ($html -notmatch 'latestYearPoolChange' -or $html -notmatch '&#26032;&#22686;&#65306;' -or $html -notmatch '&#31227;&#38500;&#65306;') {
    throw 'expected window5 current-year pool card to show latest added and removed numbers'
}

if ($html -notmatch 'poolSnapshotForWindow' -or $html -notmatch 'poolSnapshot' -or $html -notmatch '&#24403;&#26102;&#27744;') {
    throw 'expected window5 detail coverage to bind each window to its effective historical pool'
}

if ($html -notmatch 'threeCompoundWindowPoolSnapshot' -or $html -notmatch 'snapshotWindows') {
    throw 'expected three-compound windows to use effective pool snapshots instead of latest-pool backfills'
}

if ($html -notmatch 'threeCompoundChangeSummary' -or $html -notmatch '<details class="change-detail"' -or $html -notmatch '&#21464;&#21270;&#25688;&#35201;' -or $html -notmatch '&#26174;&#31034;&#20840;&#37096;&#35760;&#24405;') {
    throw 'expected three-compound change history to render compact summaries with expandable details'
}

$historyHeaderMatch = [regex]::Match($html, '&#19977;&#20013;&#19977;&#22797;&#24335;&#27744;&#21464;&#26356;&#35760;&#24405;[\s\S]{0,900}</thead>')
if ($historyHeaderMatch.Success -and ($historyHeaderMatch.Value -match '&#26087;&#27744;|&#26032;&#27744;|&#20445;&#30041;')) {
    throw 'expected three-compound change history table to avoid wide old/new/kept columns by default'
}

if ($html -notmatch 'class="table-scroll"') {
    throw 'expected wide three-window tables to render inside a horizontal scroll container'
}

if ($html -notmatch 'isFileDashboard') {
    throw 'expected local file dashboard to skip failing json fetch attempts'
}

if ($html -notmatch 'three-window-detail-toggle') {
    throw 'expected heavy three-window detail tables to render behind explicit toggles'
}

if ($html -notmatch 'cacheBustUrl') {
    throw 'expected local script data loads to include cache-busting urls'
}

if ($html -match 'dashboardCacheVersion = ''\$GeneratedAt''') {
    throw 'expected dashboard cache version to be a runtime value, not a literal template token'
}

if ($html -notmatch 'delete window\[globalName\]') {
    throw 'expected script data loads to clear stale global data before appending script tags'
}

if ($html -match 'if \(window5State\?\.items\) return window5State') {
    throw 'expected window5 state loader to load real data when initial items array is empty'
}

if ($html -match 'if \(threeCompoundState\?\.items\) return threeCompoundState') {
    throw 'expected three-compound state loader to load real data when initial items array is empty'
}

if ($html -notmatch 'function bindThreeWindowControls') {
    throw 'expected three-window cached html to re-bind detail button controls'
}

if ($html -match "threeWindowHtmlCache\.has\(htmlCacheKey\)[\s\S]{0,220}return;") {
    $cacheBranch = [regex]::Match($html, "threeWindowHtmlCache\.has\(htmlCacheKey\)[\s\S]{0,220}return;").Value
    if ($cacheBranch -notmatch 'bindThreeWindowControls') {
        throw 'expected cached three-window render path to bind detail button controls before returning'
    }
}

if ($html -notmatch 'localFetchCommand') {
    throw 'expected local manual fetch to provide a PowerShell fallback command'
}

if ($html -notmatch 'isFileDashboard[\s\S]*localFetchCommand') {
    throw 'expected manual fetch trigger to handle local file dashboard before calling Vercel API'
}

Write-Host 'dashboard three-window ui shape ok'
