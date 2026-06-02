param(
    [string]$RootDir = $PSScriptRoot
)

$ErrorActionPreference = 'Stop'
$Utf8NoBom = [Text.UTF8Encoding]::new($false)

function U {
    param([int[]]$Codes)
    return [string]::Concat(($Codes | ForEach-Object { [char]$_ }))
}

function Get-SourceKind {
    param([string]$FileName)
    if ($FileName -match '^hk|^\d{4}1\.html$') { return 'hk' }
    return 'am'
}

function Get-SourceName {
    param([string]$Source)
    if ($Source -eq 'hk') { return (U @(0x9999, 0x6E2F)) }
    return (U @(0x6FB3, 0x95E8))
}

function Get-YearFromFile {
    param(
        [string]$FileName,
        [string]$Html
    )

    if ($FileName -match '^(\d{4})1?\.html$') { return [int]$Matches[1] }
    if ($Html -match '(\d{4})&#24180;' -or $Html -match '(\d{4})\p{IsCJKUnifiedIdeographs}') { return [int]$Matches[1] }
    return $null
}

function Convert-ColorName {
    param([string]$Color)
    switch ($Color) {
        'red' { return (U @(0x7EA2)) }
        'green' { return (U @(0x7EFF)) }
        'blue' { return (U @(0x84DD)) }
        default { return $Color }
    }
}

function Normalize-Zodiac {
    param([string]$Value)

    $decoded = [System.Net.WebUtility]::HtmlDecode($Value.Trim())
    $zodiacs = @(
        (U @(0x9F20)), (U @(0x725B)), (U @(0x864E)), (U @(0x5154)),
        (U @(0x9F99)), (U @(0x86C7)), (U @(0x9A6C)), (U @(0x7F8A)),
        (U @(0x7334)), (U @(0x9E21)), (U @(0x72D7)), (U @(0x732A))
    )
    foreach ($zodiac in $zodiacs) {
        if ($decoded.StartsWith($zodiac)) {
            return $zodiac
        }
    }
    return $decoded
}

function Parse-RecordBlocks {
    param(
        [string]$Html,
        [string]$Source,
        [Nullable[int]]$Year,
        [string]$FileName
    )

    $records = New-Object 'System.Collections.Generic.List[object]'
    $issueText = [regex]::Escape((U @(0x671F)))
    $openText = [regex]::Escape((U @(0x5F00, 0x5956, 0x65F6, 0x95F4)))
    $pattern = '(?is)<li>\s*<dt><b>(\d+)</b>' + $issueText + '\(' + $openText + ':(\d{4}-\d{2}-\d{2})\)</dt>\s*<dl>(.*?)</dl>\s*</li>'

    foreach ($recordMatch in [regex]::Matches($Html, $pattern)) {
        $ballsHtml = $recordMatch.Groups[3].Value
        $balls = New-Object 'System.Collections.Generic.List[object]'
        $ballPattern = '(?is)<div\s+class="ball"[^>]*data-name="([^"]+)"[^>]*data-index="(\d+)"[^>]*>\s*<p>\s*<span\s+class="([^"]+)">(\d+)</span>\s*<b>([^<]+)</b>\s*</p>\s*</div>'

        foreach ($ballMatch in [regex]::Matches($ballsHtml, $ballPattern)) {
            $balls.Add([pscustomobject]@{
                index = [int]$ballMatch.Groups[2].Value
                number = [int]$ballMatch.Groups[4].Value
                numberText = $ballMatch.Groups[4].Value
                color = $ballMatch.Groups[3].Value
                colorName = Convert-ColorName $ballMatch.Groups[3].Value
                zodiac = Normalize-Zodiac $ballMatch.Groups[5].Value
            }) | Out-Null
        }

        if ($balls.Count -eq 7) {
            $records.Add([pscustomobject]@{
                id = ('{0}-{1}-{2}' -f $Source, $recordMatch.Groups[2].Value, $recordMatch.Groups[1].Value)
                source = $Source
                sourceName = Get-SourceName $Source
                year = $Year
                issue = [int]$recordMatch.Groups[1].Value
                date = $recordMatch.Groups[2].Value
                file = $FileName
                balls = @($balls | Sort-Object index)
            }) | Out-Null
        }
    }

    return $records
}

function Get-Counts {
    param(
        [object[]]$Items,
        [scriptblock]$Selector
    )

    $counts = @{}
    foreach ($item in $Items) {
        $key = & $Selector $item
        if ([string]::IsNullOrWhiteSpace([string]$key)) { continue }
        if (-not $counts.ContainsKey($key)) { $counts[$key] = 0 }
        $counts[$key]++
    }

    return @(
        foreach ($key in $counts.Keys) {
            [pscustomobject]@{ name = $key; count = $counts[$key] }
        }
    ) | Sort-Object -Property @{ Expression = 'count'; Descending = $true }, @{ Expression = 'name'; Descending = $false }
}

function Get-Summary {
    param([object[]]$Records)

    $allBalls = @($Records | ForEach-Object { $_.balls })
    $latest = @($Records | Sort-Object @{ Expression = 'date'; Descending = $true }, @{ Expression = 'issue'; Descending = $true } | Select-Object -First 1)
    $bySource = @{}
    foreach ($source in @('am', 'hk')) {
        $sourceRecords = @($Records | Where-Object { $_.source -eq $source })
        $sourceBalls = @($sourceRecords | ForEach-Object { $_.balls })
        $sourceLatest = @($sourceRecords | Sort-Object @{ Expression = 'date'; Descending = $true }, @{ Expression = 'issue'; Descending = $true } | Select-Object -First 1)
        $bySource[$source] = [pscustomobject]@{
            source = $source
            sourceName = Get-SourceName $source
            totalRecords = $sourceRecords.Count
            totalBalls = $sourceBalls.Count
            years = Get-Counts $sourceRecords { param($r) [string]$r.year }
            numbers = Get-Counts $sourceBalls { param($b) $b.numberText }
            zodiacs = Get-Counts $sourceBalls { param($b) $b.zodiac }
            colors = Get-Counts $sourceBalls { param($b) $b.colorName }
            latest = if ($sourceLatest.Count -gt 0) { $sourceLatest[0] } else { $null }
        }
    }

    return [pscustomobject]@{
        generatedAt = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
        totalRecords = $Records.Count
        totalBalls = $allBalls.Count
        bySource = $bySource
        sources = Get-Counts $Records { param($r) $r.sourceName }
        years = Get-Counts $Records { param($r) [string]$r.year }
        numbers = Get-Counts $allBalls { param($b) $b.numberText }
        zodiacs = Get-Counts $allBalls { param($b) $b.zodiac }
        colors = Get-Counts $allBalls { param($b) $b.colorName }
        latest = if ($latest.Count -gt 0) { $latest[0] } else { $null }
    }
}

function Get-LatestRecord {
    param([object[]]$Records, [string]$Source)
    return @($Records | Where-Object { $_.source -eq $Source } | Sort-Object @{ Expression = 'date'; Descending = $true }, @{ Expression = 'issue'; Descending = $true } | Select-Object -First 1)[0]
}

function Get-NextDrawDate {
    param([object[]]$SourceRecords, [string]$Source)

    $latest = @($SourceRecords | Sort-Object @{ Expression = 'date'; Descending = $true }, @{ Expression = 'issue'; Descending = $true } | Select-Object -First 1)
    if ($latest.Count -eq 0 -or [string]::IsNullOrWhiteSpace($latest[0].date)) { return '' }

    $latestDate = [datetime]::ParseExact($latest[0].date, 'yyyy-MM-dd', $null)
    if ($Source -ne 'hk') {
        return $latestDate.AddDays(1).ToString('yyyy-MM-dd')
    }

    $recentDates = @(
        $SourceRecords |
            Sort-Object @{ Expression = 'date'; Descending = $true }, @{ Expression = 'issue'; Descending = $true } |
            Select-Object -First 30 |
            ForEach-Object {
                if (-not [string]::IsNullOrWhiteSpace($_.date)) {
                    [datetime]::ParseExact($_.date, 'yyyy-MM-dd', $null)
                }
            } |
            Sort-Object
    )
    $intervalCounts = @{}
    for ($i = 1; $i -lt $recentDates.Count; $i++) {
        $days = [int]($recentDates[$i] - $recentDates[$i - 1]).TotalDays
        if ($days -ge 2 -and $days -le 10) {
            if (-not $intervalCounts.ContainsKey($days)) { $intervalCounts[$days] = 0 }
            $intervalCounts[$days]++
        }
    }
    if ($intervalCounts.Count -eq 0) { return '' }

    $interval = @($intervalCounts.GetEnumerator() | Sort-Object @{ Expression = 'Value'; Descending = $true }, @{ Expression = { [int]$_.Key }; Descending = $false } | Select-Object -First 1)[0].Key
    return $latestDate.AddDays([int]$interval).ToString('yyyy-MM-dd')
}

function Get-ComboKey {
    param([string[]]$Nums)
    return (($Nums | ForEach-Object { ([int]$_).ToString('00') } | Sort-Object { [int]$_ }) -join '-')
}

function Get-Choose3 {
    param([string[]]$Nums)
    $out = [System.Collections.ArrayList]::new()
    for ($i = 0; $i -lt $Nums.Count - 2; $i++) {
        for ($j = $i + 1; $j -lt $Nums.Count - 1; $j++) {
            for ($k = $j + 1; $k -lt $Nums.Count; $k++) {
                [void]$out.Add([string[]]@($Nums[$i], $Nums[$j], $Nums[$k]))
            }
        }
    }
    return @($out)
}

function Get-SeededNoise {
    param([string]$Text)
    $hash = [uint32]2166136261
    foreach ($ch in $Text.ToCharArray()) {
        $hash = $hash -bxor [uint32][int][char]$ch
        $hash = [uint32](([uint64]$hash * 16777619) % 4294967296)
    }
    return [double]$hash / 4294967295
}

function Get-RecordIdentity {
    param([object]$Record)
    if ($null -eq $Record) { return '' }
    return '{0}|{1}|{2}|{3}' -f $Record.source, $Record.year, $Record.issue, $Record.date
}

function Get-TargetIdentity {
    param([string]$Source, [object]$Latest, [int]$Issue, [string]$TargetDate, [string]$DisplayYear)
    $anchor = if (-not [string]::IsNullOrWhiteSpace($TargetDate)) { $TargetDate } elseif (-not [string]::IsNullOrWhiteSpace($DisplayYear)) { $DisplayYear } else { Get-RecordIdentity $Latest }
    return '{0}|{1}|{2}|latest:{3}' -f $Source, $Issue, $anchor, (Get-RecordIdentity $Latest)
}

function Test-DateWithinDays {
    param([string]$A, [string]$B, [int]$Days)
    if ([string]::IsNullOrWhiteSpace($A) -or [string]::IsNullOrWhiteSpace($B)) { return $false }
    try {
        $dateA = [datetime]::ParseExact($A, 'yyyy-MM-dd', $null)
        $dateB = [datetime]::ParseExact($B, 'yyyy-MM-dd', $null)
        return [Math]::Abs(($dateA - $dateB).TotalDays) -le $Days
    }
    catch {
        return $false
    }
}

function Get-DisplayYearForTarget {
    param([string]$TargetDate, [object]$Latest)
    if (-not [string]::IsNullOrWhiteSpace($TargetDate) -and $TargetDate.Length -ge 4) { return $TargetDate.Substring(0, 4) }
    if ($null -ne $Latest -and -not [string]::IsNullOrWhiteSpace([string]$Latest.date) -and ([string]$Latest.date).Length -ge 4) { return ([string]$Latest.date).Substring(0, 4) }
    if ($null -ne $Latest -and -not [string]::IsNullOrWhiteSpace([string]$Latest.year)) { return [string]$Latest.year }
    return ''
}

function Test-RecordMatchesGameItemYear {
    param([object]$Record, [object]$Item)

    if ($null -eq $Record -or $null -eq $Item) { return $false }

    $itemYear = [string]$Item.year
    if (-not [string]::IsNullOrWhiteSpace($itemYear) -and -not [string]::IsNullOrWhiteSpace([string]$Record.year) -and [int]$Record.year -eq [int]$itemYear) {
        return $true
    }

    $displayYear = [string]$Item.displayYear
    if (-not [string]::IsNullOrWhiteSpace($displayYear) -and -not [string]::IsNullOrWhiteSpace([string]$Record.date) -and ([string]$Record.date).Length -ge 4 -and ([string]$Record.date).Substring(0, 4) -eq $displayYear) {
        return $true
    }

    return $false
}

function Get-ModelPickFromHistory {
    param([object[]]$History, [hashtable]$Model, [int]$Limit = 7)

    $stats = @{}
    foreach ($n in 1..49) {
        $key = $n.ToString('00')
        $stats[$key] = [pscustomobject]@{ numberText = $key; hits = 0; recentHits = 0; miss = $History.Count }
    }
    $recentAvoid = @{}
    foreach ($record in @($History | Select-Object -First 5)) {
        foreach ($ball in $record.balls) { $recentAvoid[$ball.numberText] = $true }
    }
    for ($order = 0; $order -lt $History.Count; $order++) {
        foreach ($ball in $History[$order].balls) {
            $item = $stats[$ball.numberText]
            if ($null -eq $item) { continue }
            $item.hits++
            $item.miss = [Math]::Min($item.miss, $order)
            if ($order -lt 60) { $item.recentHits++ }
        }
    }
    return @(
        foreach ($item in $stats.Values) {
            $avoid = if ($recentAvoid.ContainsKey($item.numberText)) { 1 } else { 0 }
            $score = $item.hits * $Model.all + $item.recentHits * $Model.recent + [Math]::Min($item.miss, 180) * $Model.miss - $avoid * $Model.avoid * 40
            [pscustomobject]@{ numberText = $item.numberText; zodiac = ''; color = 'blue'; score = $score }
        }
    ) | Sort-Object @{ Expression = 'score'; Descending = $true }, @{ Expression = { [int]$_.numberText }; Descending = $false } | Select-Object -First $Limit
}

function Get-BestPredictionNumbers {
    param([object[]]$SourceRecords)

    $model = @{ id = 'balanced'; all = 0.45; recent = 0.65; miss = 0.45; avoid = 0.25 }
    return @(Get-ModelPickFromHistory -History $SourceRecords -Model $model | ForEach-Object { $_.numberText })
}

function Get-GameAlgorithms {
    return @(
        [pscustomobject]@{ id = 'greedy'; name = (U @(0x8D2A, 0x5FC3)) }
        [pscustomobject]@{ id = 'backtracking'; name = (U @(0x56DE, 0x6EAF)) }
        [pscustomobject]@{ id = 'dynamic-programming'; name = (U @(0x52A8, 0x6001, 0x89C4, 0x5212)) }
        [pscustomobject]@{ id = 'simulated-annealing'; name = (U @(0x6A21, 0x62DF, 0x9000, 0x706B)) }
        [pscustomobject]@{ id = 'genetic'; name = (U @(0x9057, 0x4F20, 0x7B97, 0x6CD5)) }
        [pscustomobject]@{ id = 'particle-swarm'; name = (U @(0x7C92, 0x5B50, 0x7FA4)) }
        [pscustomobject]@{ id = 'monte-carlo'; name = (U @(0x8499, 0x7279, 0x5361, 0x6D1B)) }
        [pscustomobject]@{ id = 'ant-colony'; name = (U @(0x8681, 0x7FA4)) }
        [pscustomobject]@{ id = 'markov-chain'; name = (U @(0x9A6C, 0x5C14, 0x53EF, 0x592B, 0x94FE)) }
        [pscustomobject]@{ id = 'bayesian'; name = (U @(0x8D1D, 0x53F6, 0x65AF, 0x63A8, 0x65AD)) }
        [pscustomobject]@{ id = 'association-rules'; name = (U @(0x5173, 0x8054, 0x89C4, 0x5219)) }
    )
}

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
    param([object[]]$SourceRecords, [string]$Game, [string]$AlgorithmId, [string]$SeedIdentity = '')

    $take = if ($Game -eq 'three-hit-three') { 3 } else { 1 }
    $stats = Get-NumberStats -SourceRecords $SourceRecords -Game $Game
    if ([string]::IsNullOrWhiteSpace($SeedIdentity)) {
        $latest = @($SourceRecords | Select-Object -First 1)
        $SeedIdentity = Get-RecordIdentity $latest[0]
    }
    return @(
        foreach ($item in $stats.Values) {
            $noise = Get-SeededNoise "$SeedIdentity|$Game|$AlgorithmId|$($item.numberText)"
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

function Get-MiroFishSandboxNumbers {
    param([object[]]$SourceRecords, [string]$Game, [string]$SeedIdentity = '')

    $take = if ($Game -eq 'three-hit-three') { 3 } else { 1 }
    $stats = Get-NumberStats -SourceRecords $SourceRecords -Game $Game
    return @(
        foreach ($item in $stats.Values) {
            $noise = Get-SeededNoise "$SeedIdentity|mirofish-sandbox|$Game|$($item.numberText)"
            $hotAgent = $item.recentHits * 2.4 + $item.hits * 0.25
            $coldAgent = [Math]::Min($item.miss, 120) * 0.85
            $cycleAgent = [Math]::Sin(([int]$item.numberText + $SourceRecords.Count) / 7.0) * 8
            $coverageAgent = (49 - [int]$item.numberText) * 0.04 + $noise * 9
            $score = $hotAgent + $coldAgent + $cycleAgent + $coverageAgent
            [pscustomobject]@{ numberText = $item.numberText; score = [double]$score }
        }
    ) | Sort-Object @{ Expression = 'score'; Descending = $true }, @{ Expression = { [int]$_.numberText }; Descending = $false } | Select-Object -First $take | ForEach-Object { $_.numberText }
}

function Settle-GameItem {
    param([object]$Item, [object[]]$Records)

    if ($Item.status -eq 'settled' -and -not [string]::IsNullOrWhiteSpace([string]$Item.targetDate) -and -not [string]::IsNullOrWhiteSpace([string]$Item.actualDate) -and [string]$Item.targetDate -ne [string]$Item.actualDate) {
        $Item | Add-Member -NotePropertyName status -NotePropertyValue 'pending' -Force
        $Item.PSObject.Properties.Remove('hit')
        $Item.PSObject.Properties.Remove('actualDate')
        $Item.PSObject.Properties.Remove('actualIssue')
        $Item.PSObject.Properties.Remove('actualNumbers')
    }
    $baseMatches = @($Records | Where-Object {
        $_.source -eq $Item.source -and
        [int]$_.issue -eq [int]$Item.issue
    })
    $draw = @()
    if (-not [string]::IsNullOrWhiteSpace([string]$Item.targetDate)) {
        $draw = @($baseMatches | Where-Object { [string]$_.date -eq [string]$Item.targetDate } | Select-Object -First 1)
        if ($draw.Count -eq 0 -and [string]$Item.source -eq 'hk') {
            $draw = @($baseMatches | Where-Object { (Test-RecordMatchesGameItemYear -Record $_ -Item $Item) -and (Test-DateWithinDays -A ([string]$_.date) -B ([string]$Item.targetDate) -Days 1) } | Select-Object -First 1)
        }
    }
    else {
        $draw = @($baseMatches | Where-Object { Test-RecordMatchesGameItemYear -Record $_ -Item $Item } | Select-Object -First 1)
    }
    if ($draw.Count -eq 0) { return $Item }

    $record = $draw[0]
    $actual = @(
        if ($Item.game -eq 'three-hit-three') {
            $record.balls | Select-Object -First 6 | ForEach-Object { ([int]$_.numberText).ToString('00') }
        } else {
            ([int]$record.balls[6].numberText).ToString('00')
        }
    )
    $recommended = @($Item.numbers | ForEach-Object { ([int]$_).ToString('00') })
    $hit = if ($Item.game -eq 'three-hit-three') {
        @($recommended | Where-Object { $actual -contains $_ }).Count -eq 3
    } else {
        @($recommended).Count -gt 0 -and [string]$actual[0] -eq [string]$recommended[0]
    }

    $Item | Add-Member -NotePropertyName status -NotePropertyValue 'settled' -Force
    $Item | Add-Member -NotePropertyName hit -NotePropertyValue $hit -Force
    $Item | Add-Member -NotePropertyName actualDate -NotePropertyValue $record.date -Force
    $Item | Add-Member -NotePropertyName actualIssue -NotePropertyValue $record.issue -Force
    $Item | Add-Member -NotePropertyName actualNumbers -NotePropertyValue $actual -Force
    return $Item
}

function Test-NumberInList {
    param([object[]]$Values, [string]$Needle)

    $target = ([int]$Needle).ToString('00')
    return @($Values | ForEach-Object { ([int]$_).ToString('00') } | Where-Object { $_ -eq $target }).Count -gt 0
}

function Settle-ForecastItem {
    param([object]$Item, [object[]]$Records)

    $baseMatches = @($Records | Where-Object {
        $_.source -eq $Item.source -and
        [int]$_.issue -eq [int]$Item.issue
    })
    $draw = @()
    if (-not [string]::IsNullOrWhiteSpace([string]$Item.targetDate)) {
        $draw = @($baseMatches | Where-Object { [string]$_.date -eq [string]$Item.targetDate } | Select-Object -First 1)
        if ($draw.Count -eq 0 -and [string]$Item.source -eq 'hk') {
            $draw = @($baseMatches | Where-Object { (Test-RecordMatchesGameItemYear -Record $_ -Item $Item) -and (Test-DateWithinDays -A ([string]$_.date) -B ([string]$Item.targetDate) -Days 1) } | Select-Object -First 1)
        }
    }
    else {
        $draw = @($baseMatches | Where-Object { Test-RecordMatchesGameItemYear -Record $_ -Item $Item } | Select-Object -First 1)
    }
    if ($draw.Count -eq 0) { return $Item }

    $record = $draw[0]
    $actual = @(
        if ($Item.game -eq 'three-hit-three') {
            $record.balls | Select-Object -First 6 | ForEach-Object { ([int]$_.numberText).ToString('00') }
        } else {
            ([int]$record.balls[6].numberText).ToString('00')
        }
    )
    $hit = if ($Item.game -eq 'three-hit-three') {
        @($Item.numbers | Where-Object {
            $group = if ($null -ne $_.value) { @($_.value) } else { @($_) }
            if ($group.Count -eq 1 -and $group[0] -is [array]) { $group = @($group[0]) }
            @($group | Where-Object { Test-NumberInList -Values $actual -Needle $_ }).Count -ge 3
        }).Count -gt 0
    } else {
        Test-NumberInList -Values @($Item.numbers) -Needle $actual[0]
    }

    $Item | Add-Member -NotePropertyName status -NotePropertyValue 'settled' -Force
    $Item | Add-Member -NotePropertyName hit -NotePropertyValue $hit -Force
    $Item | Add-Member -NotePropertyName actualDate -NotePropertyValue $record.date -Force
    $Item | Add-Member -NotePropertyName actualIssue -NotePropertyValue $record.issue -Force
    $Item | Add-Member -NotePropertyName actualNumbers -NotePropertyValue $actual -Force
    return $Item
}

function Get-ForecastOdds {
    param([string]$Game)
    if ($Game -eq 'three-hit-three') { return 650 }
    return 47
}

function Get-ForecastUnitCount {
    param([object]$Numbers, [string]$Game)
    return [Math]::Max(1, @($Numbers).Count)
}

function Add-ForecastEconomics {
    param([object]$Backtest, [object]$Numbers, [string]$Game)

    $odds = Get-ForecastOdds -Game $Game
    $unitCount = Get-ForecastUnitCount -Numbers $Numbers -Game $Game
    $totalStake = [int]$Backtest.tested * $unitCount
    $totalPayout = [int]$Backtest.hits * $odds
    $netProfit = $totalPayout - $totalStake
    $roi = if ($totalStake -gt 0) { [Math]::Round($netProfit / $totalStake * 100, 2) } else { 0 }
    $Backtest | Add-Member -NotePropertyName odds -NotePropertyValue $odds -Force
    $Backtest | Add-Member -NotePropertyName unitCount -NotePropertyValue $unitCount -Force
    $Backtest | Add-Member -NotePropertyName stakePerIssue -NotePropertyValue $unitCount -Force
    $Backtest | Add-Member -NotePropertyName totalStake -NotePropertyValue $totalStake -Force
    $Backtest | Add-Member -NotePropertyName totalPayout -NotePropertyValue $totalPayout -Force
    $Backtest | Add-Member -NotePropertyName netProfit -NotePropertyValue $netProfit -Force
    $Backtest | Add-Member -NotePropertyName roi -NotePropertyValue $roi -Force
    return $Backtest
}

function Get-ForecastQuality {
    param([object]$Backtest, [object]$WeekBacktest, [object]$RandomBaseline)

    $roiScore = [Math]::Max(0, [Math]::Min(40, ([double]$Backtest.roi + 100) / 5))
    $roiEdge = [double]$Backtest.roi - [double]$RandomBaseline.roi
    $edgeScore = [Math]::Max(0, [Math]::Min(25, $roiEdge / 4))
    $missScore = [Math]::Max(0, 20 - [Math]::Min(20, [double]$Backtest.maxMiss * 0.8))
    $currentScore = [Math]::Max(0, 10 - [Math]::Min(10, [double]$Backtest.currentMiss))
    $weekScore = if ([double]$WeekBacktest.netProfit -gt 0) { 5 } else { 0 }
    $score = [Math]::Round($roiScore + $edgeScore + $missScore + $currentScore + $weekScore, 1)
    $level = if ($score -ge 90) { (U @(0x4F18)) } elseif ($score -ge 80) { (U @(0x826F)) } elseif ($score -ge 60) { (U @(0x53CA,0x683C)) } else { (U @(0x4E0D,0x5408,0x683C)) }
    return [pscustomobject]@{ score = $score; level = $level; roiEdge = [Math]::Round($roiEdge, 2) }
}

function Get-ForecastNumberRanking {
    param([object[]]$SourceRecords, [string]$Game, [string]$SeedIdentity = '')

    $stats = Get-NumberStats -SourceRecords $SourceRecords -Game $Game
    $algorithmVotes = @{}
    foreach ($algorithm in Get-GameAlgorithms) {
        foreach ($num in @(Get-AlgorithmNumbers -SourceRecords $SourceRecords -Game $Game -AlgorithmId $algorithm.id -SeedIdentity $SeedIdentity)) {
            if (-not $algorithmVotes.ContainsKey($num)) { $algorithmVotes[$num] = 0 }
            $algorithmVotes[$num]++
        }
    }

    return @(
        foreach ($item in $stats.Values) {
            $vote = if ($algorithmVotes.ContainsKey($item.numberText)) { $algorithmVotes[$item.numberText] } else { 0 }
            $score = $vote * 28 + $item.recentHits * 1.8 + $item.hits * 0.35 + [Math]::Min($item.miss, 90) * 0.42
            [pscustomobject]@{ numberText = $item.numberText; score = [double]$score; vote = $vote; miss = $item.miss; hits = $item.hits; recentHits = $item.recentHits }
        }
    ) | Sort-Object @{ Expression = 'score'; Descending = $true }, @{ Expression = { [int]$_.numberText }; Descending = $false }
}

function Get-ForecastNumbers {
    param([object[]]$SourceRecords, [string]$Game, [string]$SeedIdentity = '')

    $ranking = @(Get-ForecastNumberRanking -SourceRecords $SourceRecords -Game $Game -SeedIdentity $SeedIdentity)
    if ($Game -eq 'special-number') {
        return @($ranking | Select-Object -First 6 | ForEach-Object { $_.numberText })
    }

    $core = @($ranking | Select-Object -First 5 | ForEach-Object { $_.numberText })
    $drag = @($ranking | Select-Object -Skip 5 -First 8 | ForEach-Object { $_.numberText })
    $pool = @($core + $drag | Select-Object -Unique)
    $combos = New-Object 'System.Collections.Generic.List[object]'
    foreach ($combo in Get-Choose3 -Nums $pool) {
        $score = 0
        foreach ($num in $combo) {
            $score += @($ranking | Where-Object { $_.numberText -eq $num } | Select-Object -First 1)[0].score
        }
        $coreCount = @($combo | Where-Object { $core -contains $_ }).Count
        $score += $coreCount * 8
        $combos.Add([pscustomobject]@{ nums = @($combo | Sort-Object { [int]$_ }); score = [double]$score }) | Out-Null
    }
    return @($combos | Sort-Object @{ Expression = 'score'; Descending = $true }, @{ Expression = { ($_.nums -join '-') }; Descending = $false } | Select-Object -First 6 | ForEach-Object { ,@($_.nums) })
}

function Test-ForecastHitRecord {
    param([object]$Numbers, [object]$Record, [string]$Game)

    if ($Game -eq 'three-hit-three') {
        $actual = @($Record.balls | Select-Object -First 6 | ForEach-Object { ([int]$_.numberText).ToString('00') })
        foreach ($group in @($Numbers)) {
            $nums = if ($null -ne $group.value) { @($group.value) } else { @($group) }
            if ($nums.Count -eq 1 -and $nums[0] -is [array]) { $nums = @($nums[0]) }
            if (@($nums | Where-Object { Test-NumberInList -Values $actual -Needle $_ }).Count -ge 3) { return $true }
        }
        return $false
    }

    $special = ([int]$Record.balls[6].numberText).ToString('00')
    return Test-NumberInList -Values @($Numbers) -Needle $special
}

function Get-ForecastBacktest {
    param([object[]]$RecordsAsc, [string]$Game, [scriptblock]$Generator, [int]$Window = 120, [int]$MinHistory = 1)

    $tested = 0
    $hits = 0
    $currentMiss = 0
    $maxMiss = 0
    $run = 0
    $limit = [Math]::Min($Window, [Math]::Max(0, $RecordsAsc.Count - $MinHistory))
    for ($i = $RecordsAsc.Count - $limit; $i -lt $RecordsAsc.Count; $i++) {
        if ($i -lt $MinHistory) { continue }
        $history = @($RecordsAsc[0..($i - 1)] | Sort-Object @{ Expression = 'date'; Descending = $true }, @{ Expression = 'issue'; Descending = $true })
        $numbers = & $Generator $history $Game ('backtest|' + [string]$i)
        $hit = Test-ForecastHitRecord -Numbers $numbers -Record $RecordsAsc[$i] -Game $Game
        $tested++
        if ($hit) {
            $hits++
            $maxMiss = [Math]::Max($maxMiss, $run)
            $run = 0
        } else {
            $run++
        }
    }
    $maxMiss = [Math]::Max($maxMiss, $run)
    for ($i = $RecordsAsc.Count - 1; $i -ge [Math]::Max(0, $RecordsAsc.Count - $limit); $i--) {
        $historyEnd = $i - 1
        if ($historyEnd -lt $MinHistory - 1) { break }
        $history = @($RecordsAsc[0..$historyEnd] | Sort-Object @{ Expression = 'date'; Descending = $true }, @{ Expression = 'issue'; Descending = $true })
        $numbers = & $Generator $history $Game ('current|' + [string]$i)
        if (Test-ForecastHitRecord -Numbers $numbers -Record $RecordsAsc[$i] -Game $Game) { break }
        $currentMiss++
    }

    return [pscustomobject]@{
        tested = $tested
        hits = $hits
        hitRate = if ($tested -gt 0) { [Math]::Round($hits / $tested * 100, 2) } else { 0 }
        currentMiss = $currentMiss
        maxMiss = $maxMiss
        window = $Window
    }
}

function Get-ForecastHistoricalBacktest {
    param([object[]]$RecordsAsc, [string]$Game, [object]$Numbers, [int]$Window = 120)

    $sliceStart = [Math]::Max(0, $RecordsAsc.Count - $Window)
    $tested = 0
    $hits = 0
    $currentMiss = 0
    $maxMiss = 0
    $run = 0
    for ($i = $sliceStart; $i -lt $RecordsAsc.Count; $i++) {
        $hit = Test-ForecastHitRecord -Numbers $Numbers -Record $RecordsAsc[$i] -Game $Game
        $tested++
        if ($hit) {
            $hits++
            $maxMiss = [Math]::Max($maxMiss, $run)
            $run = 0
        } else {
            $run++
        }
    }
    $maxMiss = [Math]::Max($maxMiss, $run)
    for ($i = $RecordsAsc.Count - 1; $i -ge $sliceStart; $i--) {
        if (Test-ForecastHitRecord -Numbers $Numbers -Record $RecordsAsc[$i] -Game $Game) { break }
        $currentMiss++
    }

    return [pscustomobject]@{
        tested = $tested
        hits = $hits
        hitRate = if ($tested -gt 0) { [Math]::Round($hits / $tested * 100, 2) } else { 0 }
        currentMiss = $currentMiss
        maxMiss = $maxMiss
        window = $Window
        mode = 'historical-window-current-picks'
    }
}

function Get-NaturalWeekRange {
    param([string]$TargetDate)

    $date = [datetime]::ParseExact($TargetDate, 'yyyy-MM-dd', $null)
    $dayIndex = ([int]$date.DayOfWeek + 6) % 7
    $start = $date.Date.AddDays(-1 * $dayIndex)
    $end = $start.AddDays(6)
    return [pscustomobject]@{
        weekStart = $start.ToString('yyyy-MM-dd')
        weekEnd = $end.ToString('yyyy-MM-dd')
    }
}

function Get-ForecastNaturalWeekBacktest {
    param([object[]]$RecordsAsc, [string]$Game, [object]$Numbers, [string]$TargetDate)

    $range = Get-NaturalWeekRange -TargetDate $TargetDate
    $weekRecords = @($RecordsAsc | Where-Object { [string]$_.date -ge $range.weekStart -and [string]$_.date -le $range.weekEnd })
    $tested = 0
    $hits = 0
    $currentMiss = 0
    $maxMiss = 0
    $run = 0
    foreach ($record in $weekRecords) {
        $hit = Test-ForecastHitRecord -Numbers $Numbers -Record $record -Game $Game
        $tested++
        if ($hit) {
            $hits++
            $maxMiss = [Math]::Max($maxMiss, $run)
            $run = 0
        } else {
            $run++
        }
    }
    $currentMiss = $run
    $maxMiss = [Math]::Max($maxMiss, $run)

    return [pscustomobject]@{
        tested = $tested
        hits = $hits
        hitRate = if ($tested -gt 0) { [Math]::Round($hits / $tested * 100, 2) } else { 0 }
        currentMiss = $currentMiss
        maxMiss = $maxMiss
        weekStart = $range.weekStart
        weekEnd = $range.weekEnd
        mode = 'natural-week-current-picks'
    }
}

function Get-ForecastWalkForwardBacktest {
    param([object[]]$RecordsAsc, [string]$Game, [string]$StrategyId, [int]$Window = 21, [int]$MinHistory = 30)

    $tested = 0
    $hits = 0
    $currentMiss = 0
    $maxMiss = 0
    $run = 0
    $limit = [Math]::Min($Window, [Math]::Max(0, $RecordsAsc.Count - $MinHistory))
    $start = [Math]::Max($MinHistory, $RecordsAsc.Count - $limit)
    for ($i = $start; $i -lt $RecordsAsc.Count; $i++) {
        $history = @($RecordsAsc[0..($i - 1)] | Sort-Object @{ Expression = 'date'; Descending = $true }, @{ Expression = 'issue'; Descending = $true })
        $effectiveStrategyId = if ($StrategyId -eq 'weekly-profit-guard') { 'score-balanced' } else { $StrategyId }
        $candidate = @(Get-LightForecastStrategyCandidates -SourceRecords $history -Game $Game -SeedIdentity ('walk-forward|' + [string]$i) -OnlyStrategyId $effectiveStrategyId | Select-Object -First 1)
        $numbers = if ($candidate.Count -gt 0) { $candidate[0].numbers } else { Get-ForecastNumbers -SourceRecords $history -Game $Game -SeedIdentity ('walk-forward|' + [string]$i) }
        $hit = Test-ForecastHitRecord -Numbers $numbers -Record $RecordsAsc[$i] -Game $Game
        $tested++
        if ($hit) {
            $hits++
            $maxMiss = [Math]::Max($maxMiss, $run)
            $run = 0
        } else {
            $run++
        }
    }
    $currentMiss = $run
    $maxMiss = [Math]::Max($maxMiss, $run)

    return [pscustomobject]@{
        tested = $tested
        hits = $hits
        hitRate = if ($tested -gt 0) { [Math]::Round($hits / $tested * 100, 2) } else { 0 }
        currentMiss = $currentMiss
        maxMiss = $maxMiss
        window = $Window
        minHistory = $MinHistory
        mode = 'walk-forward'
    }
}

function Get-SequentialNumbers {
    param([int]$Start, [int]$Count)
    return @(0..($Count - 1) | ForEach-Object { ((($Start - 1 + $_) % 49) + 1).ToString('00') })
}

function Get-RandomBaselineForecast {
    param([object[]]$SourceRecords, [string]$Game, [string]$SeedIdentity = '')

    $ranking = @(
        foreach ($n in 1..49) {
            [pscustomobject]@{ numberText = $n.ToString('00'); score = (Get-SeededNoise "$SeedIdentity|random-baseline|$Game|$n") }
        }
    ) | Sort-Object @{ Expression = 'score'; Descending = $true }, @{ Expression = { [int]$_.numberText }; Descending = $false }
    if ($Game -eq 'special-number') {
        return @($ranking | Select-Object -First 6 | ForEach-Object { $_.numberText })
    }
    $pool = @($ranking | Select-Object -First 18 | ForEach-Object { $_.numberText })
    return @(
        0..5 | ForEach-Object {
            $offset = $_ * 3
            ,@($pool[$offset..($offset + 2)] | Sort-Object { [int]$_ })
        }
    )
}

function Convert-RankingToForecastNumbers {
    param([object[]]$List, [string]$Game)

    if ($Game -eq 'special-number') {
        return @($List | Select-Object -First 6 | ForEach-Object { $_.numberText })
    }
    $pool = @($List | Select-Object -First 18 | ForEach-Object { $_.numberText })
    return @(
        0..5 | ForEach-Object {
            $offset = $_ * 3
            ,@($pool[$offset..($offset + 2)] | Sort-Object { [int]$_ })
        }
    )
}

function Normalize-ForecastNumbers {
    param([object]$Numbers, [string]$Game)

    if ($Game -eq 'three-hit-three') {
        $outer = [System.Collections.Generic.List[object]]::new()
        foreach ($group in @($Numbers)) {
            $values = if ($null -ne $group.value) { @($group.value) } else { @($group) }
            $inner = [System.Collections.Generic.List[string]]::new()
            foreach ($num in $values) {
                $inner.Add(([int]$num).ToString('00')) | Out-Null
            }
            $outer.Add($inner) | Out-Null
        }
        return $outer
    }

    $flat = [System.Collections.Generic.List[string]]::new()
    foreach ($num in @($Numbers)) {
        $flat.Add(([int]$num).ToString('00')) | Out-Null
    }
    return $flat
}

function Get-WeeklyProfitGuardNumbers {
    param([object[]]$SourceRecords, [string]$Game)

    $recent = @($SourceRecords | Select-Object -First 7)
    if ($Game -eq 'special-number') {
        $blockedRecent = @($recent | Select-Object -First 6 | ForEach-Object { ([int]$_.balls[6].numberText).ToString('00') } | Select-Object -Unique)
        $ranking = @((Get-ForecastNumberRanking -SourceRecords $SourceRecords -Game $Game) | ForEach-Object { $_.numberText })
        $nums = @()
        foreach ($num in $ranking) {
            if ($nums.Count -ge 6) { break }
            if ($blockedRecent -notcontains $num -and $nums -notcontains $num) { $nums += $num }
        }
        foreach ($num in $ranking) {
            if ($nums.Count -ge 6) { break }
            if ($nums -notcontains $num) { $nums += $num }
        }
        return @($nums | Select-Object -First 6)
    }

    $groups = @()
    foreach ($record in $recent) {
        $firstSix = @($record.balls | Select-Object -First 6 | ForEach-Object { ([int]$_.numberText).ToString('00') })
        $groups += ,@($firstSix | Select-Object -First 3 | Sort-Object { [int]$_ })
        if ($groups.Count -ge 6) { break }
    }
    $fallbackRanking = @(Get-ForecastNumberRanking -SourceRecords $SourceRecords -Game $Game | ForEach-Object { $_.numberText })
    $offset = 0
    while ($groups.Count -lt 6 -and $offset + 2 -lt $fallbackRanking.Count) {
        $groups += ,@($fallbackRanking[$offset..($offset + 2)] | Sort-Object { [int]$_ })
        $offset += 3
    }
    return @($groups | Select-Object -First 6)
}

function Get-ForecastStrategyCandidates {
    param([object[]]$SourceRecords, [string]$Game, [string]$SeedIdentity = '', [string]$OnlyStrategyId = '')

    $ranking = @(Get-ForecastNumberRanking -SourceRecords $SourceRecords -Game $Game -SeedIdentity $SeedIdentity)
    $byHot = @($ranking | Sort-Object @{ Expression = 'hits'; Descending = $true }, @{ Expression = 'recentHits'; Descending = $true }, @{ Expression = { [int]$_.numberText }; Descending = $false })
    $byCold = @($ranking | Sort-Object @{ Expression = 'miss'; Descending = $true }, @{ Expression = { [int]$_.numberText }; Descending = $false })
    $byVote = @($ranking | Sort-Object @{ Expression = 'vote'; Descending = $true }, @{ Expression = 'score'; Descending = $true }, @{ Expression = { [int]$_.numberText }; Descending = $false })
    $strategies = @(
        [pscustomobject]@{ id = 'weekly-profit-guard'; name = (U @(0x5468,0x76C8,0x5229,0x4FDD,0x62A4)); list = @() }
        [pscustomobject]@{ id = 'score-balanced'; name = (U @(0x7EFC,0x5408,0x8BC4,0x5206)); list = $ranking }
        [pscustomobject]@{ id = 'algorithm-vote'; name = (U @(0x7B97,0x6CD5,0x6295,0x7968)); list = $byVote }
        [pscustomobject]@{ id = 'hot-recent'; name = (U @(0x8FD1,0x671F,0x70ED,0x53F7)); list = $byHot }
        [pscustomobject]@{ id = 'cold-miss'; name = (U @(0x9057,0x6F0F,0x51B7,0x53F7)); list = $byCold }
        [pscustomobject]@{ id = 'hot-cold-mix'; name = (U @(0x70ED,0x51B7,0x6DF7,0x5408)); list = @() }
    )

    return @(
        foreach ($strategy in $strategies) {
            if (-not [string]::IsNullOrWhiteSpace($OnlyStrategyId) -and $strategy.id -ne $OnlyStrategyId) { continue }
            $numbers = if ($strategy.id -eq 'weekly-profit-guard') {
                Get-WeeklyProfitGuardNumbers -SourceRecords $SourceRecords -Game $Game
            } elseif ($strategy.id -eq 'hot-cold-mix') {
                $mix = @()
                for ($i = 0; $i -lt 8; $i++) {
                    if ($i -lt $byHot.Count) { $mix += $byHot[$i] }
                    if ($i -lt $byCold.Count) { $mix += $byCold[$i] }
                }
                $dedup = @($mix | Group-Object numberText | ForEach-Object { $_.Group[0] })
                if ($Game -eq 'special-number') {
                    @($dedup | Select-Object -First 6 | ForEach-Object { $_.numberText })
                } else {
                    $pool = @($dedup | Select-Object -First 12 | ForEach-Object { $_.numberText })
                    @(0..5 | ForEach-Object { ,@($pool[$_..($_ + 2)] | Sort-Object { [int]$_ }) })
                }
            } else {
                Convert-RankingToForecastNumbers -List $strategy.list -Game $Game
            }
            [pscustomobject]@{ id = $strategy.id; name = $strategy.name; numbers = @($numbers) }
        }
    )
}

function Get-LightForecastStrategyCandidates {
    param([object[]]$SourceRecords, [string]$Game, [string]$SeedIdentity = '', [string]$OnlyStrategyId = '')

    $stats = @(Get-NumberStats -SourceRecords $SourceRecords -Game $Game).Values
    $balanced = @(
        foreach ($item in $stats) {
            [pscustomobject]@{ numberText = $item.numberText; score = $item.recentHits * 2 + $item.hits * 0.4 + [Math]::Min($item.miss, 90) * 0.35; hits = $item.hits; recentHits = $item.recentHits; miss = $item.miss }
        }
    ) | Sort-Object @{ Expression = 'score'; Descending = $true }, @{ Expression = { [int]$_.numberText }; Descending = $false }
    $byHot = @($balanced | Sort-Object @{ Expression = 'hits'; Descending = $true }, @{ Expression = 'recentHits'; Descending = $true }, @{ Expression = { [int]$_.numberText }; Descending = $false })
    $byCold = @($balanced | Sort-Object @{ Expression = 'miss'; Descending = $true }, @{ Expression = { [int]$_.numberText }; Descending = $false })
    $strategies = @(
        [pscustomobject]@{ id = 'score-balanced'; name = (U @(0x7EFC,0x5408,0x8BC4,0x5206)); list = $balanced }
        [pscustomobject]@{ id = 'algorithm-vote'; name = (U @(0x7B97,0x6CD5,0x6295,0x7968)); list = $balanced }
        [pscustomobject]@{ id = 'hot-recent'; name = (U @(0x8FD1,0x671F,0x70ED,0x53F7)); list = $byHot }
        [pscustomobject]@{ id = 'cold-miss'; name = (U @(0x9057,0x6F0F,0x51B7,0x53F7)); list = $byCold }
        [pscustomobject]@{ id = 'hot-cold-mix'; name = (U @(0x70ED,0x51B7,0x6DF7,0x5408)); list = @() }
    )

    return @(
        foreach ($strategy in $strategies) {
            if (-not [string]::IsNullOrWhiteSpace($OnlyStrategyId) -and $strategy.id -ne $OnlyStrategyId) { continue }
            $numbers = if ($strategy.id -eq 'hot-cold-mix') {
                $mix = @()
                for ($i = 0; $i -lt 9; $i++) {
                    if ($i -lt $byHot.Count) { $mix += $byHot[$i] }
                    if ($i -lt $byCold.Count) { $mix += $byCold[$i] }
                }
                Convert-RankingToForecastNumbers -List @($mix | Group-Object numberText | ForEach-Object { $_.Group[0] }) -Game $Game
            } else {
                Convert-RankingToForecastNumbers -List $strategy.list -Game $Game
            }
            [pscustomobject]@{ id = $strategy.id; name = $strategy.name; numbers = @($numbers) }
        }
    )
}

function Get-OptimizedForecast {
    param([object[]]$SourceRecords, [string]$Game, [string]$SeedIdentity = '', [string]$TargetDate = '')

    $recordsAsc = @($SourceRecords | Sort-Object @{ Expression = 'date'; Descending = $false }, @{ Expression = 'issue'; Descending = $false })
    $strategyResults = @()
    foreach ($candidate in Get-ForecastStrategyCandidates -SourceRecords $SourceRecords -Game $Game -SeedIdentity $SeedIdentity) {
        $bt = Get-ForecastHistoricalBacktest -RecordsAsc $recordsAsc -Game $Game -Numbers $candidate.numbers -Window 120
        $bt = Add-ForecastEconomics -Backtest $bt -Numbers $candidate.numbers -Game $Game
        $candidateWeekBt = Get-ForecastNaturalWeekBacktest -RecordsAsc $recordsAsc -Game $Game -Numbers $candidate.numbers -TargetDate $TargetDate
        $candidateWeekBt = Add-ForecastEconomics -Backtest $candidateWeekBt -Numbers $candidate.numbers -Game $Game
        $weekBonus = if ([double]$candidateWeekBt.netProfit -gt 0) { 3000 + [double]$candidateWeekBt.netProfit * 8 } else { [double]$candidateWeekBt.netProfit * 8 }
        $score = $weekBonus + $bt.roi * 8 + $bt.hitRate * 25 - $bt.maxMiss * 1.5 - $bt.currentMiss * 2 + $bt.hits * 2
        $strategyResults += [pscustomobject]@{
            id = $candidate.id
            name = $candidate.name
            numbers = $candidate.numbers
            backtest = $bt
            weekBacktest = $candidateWeekBt
            score = [Math]::Round($score, 2)
        }
    }
    $randomNumbers = Get-RandomBaselineForecast -SourceRecords $SourceRecords -Game $Game -SeedIdentity $SeedIdentity
    $randomBt = Get-ForecastHistoricalBacktest -RecordsAsc $recordsAsc -Game $Game -Numbers $randomNumbers -Window 120
    $randomBt = Add-ForecastEconomics -Backtest $randomBt -Numbers $randomNumbers -Game $Game
    $selected = @($strategyResults | Sort-Object @{ Expression = 'score'; Descending = $true }, @{ Expression = { $_.backtest.maxMiss }; Descending = $false }, @{ Expression = 'id'; Descending = $false } | Select-Object -First 1)
    $best = if ($selected.Count -gt 0) { $selected[0] } else { [pscustomobject]@{ id = 'score-balanced'; name = 'score-balanced'; numbers = @(Get-ForecastNumbers -SourceRecords $SourceRecords -Game $Game -SeedIdentity $SeedIdentity); backtest = [pscustomobject]@{ tested = 0; hits = 0; hitRate = 0; currentMiss = 0; maxMiss = 0; window = 0 }; score = 0 } }
    $weekBt = Get-ForecastNaturalWeekBacktest -RecordsAsc $recordsAsc -Game $Game -Numbers $best.numbers -TargetDate $TargetDate
    $weekBt = Add-ForecastEconomics -Backtest $weekBt -Numbers $best.numbers -Game $Game
    $walkForwardBt = Add-ForecastEconomics -Backtest (Get-ForecastWalkForwardBacktest -RecordsAsc $recordsAsc -Game $Game -StrategyId $best.id -Window 21) -Numbers $best.numbers -Game $Game
    $weeklyProfitGate = [double]$weekBt.netProfit -gt 0 -and [double]$walkForwardBt.netProfit -gt 0
    $quality = Get-ForecastQuality -Backtest $best.backtest -WeekBacktest $weekBt -RandomBaseline $randomBt
    $best.backtest | Add-Member -NotePropertyName edgeVsRandom -NotePropertyValue ([Math]::Round([double]$best.backtest.hitRate - [double]$randomBt.hitRate, 2)) -Force
    $best.backtest | Add-Member -NotePropertyName roiVsRandom -NotePropertyValue ([Math]::Round([double]$best.backtest.roi - [double]$randomBt.roi, 2)) -Force
    return [pscustomobject]@{
        numbers = Normalize-ForecastNumbers -Numbers $best.numbers -Game $Game
        odds = Get-ForecastOdds -Game $Game
        weekBacktest = $weekBt
        walkForwardBacktest = $walkForwardBt
        weeklyProfitGate = $weeklyProfitGate
        recommendationStatus = if ($weeklyProfitGate) { (U @(0x4E3B,0x63A8)) } else { (U @(0x6682,0x505C,0x89C2,0x5BDF)) }
        qualityScore = $quality.score
        qualityLevel = $quality.level
        forecastVersion = 'forecast-v3-no-recent-copy'
        selectedStrategy = $best.id
        selectedStrategyName = $best.name
        backtest = $best.backtest
        randomBaseline = $randomBt
        strategyPool = @($strategyResults | Sort-Object @{ Expression = 'score'; Descending = $true } | ForEach-Object {
            [pscustomobject]@{
                id = $_.id
                name = $_.name
                score = $_.score
                tested = $_.backtest.tested
                hits = $_.backtest.hits
                hitRate = $_.backtest.hitRate
                currentMiss = $_.backtest.currentMiss
                maxMiss = $_.backtest.maxMiss
                totalStake = $_.backtest.totalStake
                totalPayout = $_.backtest.totalPayout
                netProfit = $_.backtest.netProfit
                roi = $_.backtest.roi
                weekNetProfit = $_.weekBacktest.netProfit
                weekRoi = $_.weekBacktest.roi
            }
        })
    }
}

function New-ForecastPredictions {
    param([object[]]$Records, [object[]]$Existing = @())

    $createdAt = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $items = New-Object 'System.Collections.Generic.List[object]'
    foreach ($old in @($Existing)) {
        $items.Add((Settle-ForecastItem -Item $old -Records $Records)) | Out-Null
    }

    foreach ($source in @('am', 'hk')) {
        $sourceRecords = @($Records | Where-Object { $_.source -eq $source } | Sort-Object @{ Expression = 'date'; Descending = $true }, @{ Expression = 'issue'; Descending = $true })
        if ($sourceRecords.Count -eq 0) { continue }

        $latest = $sourceRecords[0]
        $targetDate = Get-NextDrawDate -SourceRecords $sourceRecords -Source $source
        $issue = [int]$latest.issue + 1
        $displayYear = Get-DisplayYearForTarget -TargetDate $targetDate -Latest $latest
        $seedIdentity = Get-TargetIdentity -Source $source -Latest $latest -Issue $issue -TargetDate $targetDate -DisplayYear $displayYear

        foreach ($game in @('three-hit-three', 'special-number')) {
            $exists = @($items | Where-Object { $_.source -eq $source -and $_.game -eq $game -and [int]$_.issue -eq $issue -and $_.displayYear -eq $displayYear -and [string]$_.targetDate -eq [string]$targetDate })
            $gameName = if ($game -eq 'three-hit-three') { (U @(0x4E09, 0x4E2D, 0x4E09)) } else { (U @(0x7279, 0x522B, 0x53F7)) }
            $optimized = Get-OptimizedForecast -SourceRecords $sourceRecords -Game $game -SeedIdentity $seedIdentity -TargetDate $targetDate
            if ($exists.Count -gt 0) {
                foreach ($existing in $exists) {
                    $hasWeeklyGuard = @($existing.strategyPool | Where-Object { $_.id -eq 'weekly-profit-guard' }).Count -gt 0
                    if ($null -eq $existing.backtest -or $null -eq $existing.randomBaseline -or @($existing.strategyPool).Count -eq 0 -or -not $hasWeeklyGuard -or $null -eq $existing.odds -or $null -eq $existing.backtest.roi -or $null -eq $existing.weekBacktest -or [string]$existing.weekBacktest.mode -ne 'natural-week-current-picks' -or $null -eq $existing.walkForwardBacktest -or $null -eq $existing.qualityScore -or [string]$existing.forecastVersion -ne [string]$optimized.forecastVersion) {
                        $existing | Add-Member -NotePropertyName strategyId -NotePropertyValue $optimized.selectedStrategy -Force
                        $existing | Add-Member -NotePropertyName strategyName -NotePropertyValue $optimized.selectedStrategyName -Force
                        $existing | Add-Member -NotePropertyName selectedStrategy -NotePropertyValue $optimized.selectedStrategy -Force
                        $existing | Add-Member -NotePropertyName selectedStrategyName -NotePropertyValue $optimized.selectedStrategyName -Force
                        $existing | Add-Member -NotePropertyName odds -NotePropertyValue $optimized.odds -Force
                        $existing | Add-Member -NotePropertyName weekBacktest -NotePropertyValue $optimized.weekBacktest -Force
                        $existing | Add-Member -NotePropertyName walkForwardBacktest -NotePropertyValue $optimized.walkForwardBacktest -Force
                        $existing | Add-Member -NotePropertyName weeklyProfitGate -NotePropertyValue $optimized.weeklyProfitGate -Force
                        $existing | Add-Member -NotePropertyName recommendationStatus -NotePropertyValue $optimized.recommendationStatus -Force
                        $existing | Add-Member -NotePropertyName qualityScore -NotePropertyValue $optimized.qualityScore -Force
                        $existing | Add-Member -NotePropertyName qualityLevel -NotePropertyValue $optimized.qualityLevel -Force
                        $existing | Add-Member -NotePropertyName forecastVersion -NotePropertyValue $optimized.forecastVersion -Force
                        $existing | Add-Member -NotePropertyName numbers -NotePropertyValue $optimized.numbers -Force
                        $existing | Add-Member -NotePropertyName backtest -NotePropertyValue $optimized.backtest -Force
                        $existing | Add-Member -NotePropertyName randomBaseline -NotePropertyValue $optimized.randomBaseline -Force
                        $existing | Add-Member -NotePropertyName strategyPool -NotePropertyValue @($optimized.strategyPool) -Force
                    }
                }
                continue
            }
            $items.Add([pscustomobject]@{
                id = ('{0}-forecast-{1}-{2}-{3}' -f $source, $game, $displayYear, $issue)
                source = $source
                sourceName = Get-SourceName $source
                game = $game
                gameName = $gameName
                strategyId = $optimized.selectedStrategy
                strategyName = $optimized.selectedStrategyName
                selectedStrategy = $optimized.selectedStrategy
                selectedStrategyName = $optimized.selectedStrategyName
                odds = $optimized.odds
                weekBacktest = $optimized.weekBacktest
                walkForwardBacktest = $optimized.walkForwardBacktest
                weeklyProfitGate = $optimized.weeklyProfitGate
                recommendationStatus = $optimized.recommendationStatus
                qualityScore = $optimized.qualityScore
                qualityLevel = $optimized.qualityLevel
                forecastVersion = $optimized.forecastVersion
                year = $latest.year
                displayYear = $displayYear
                issue = $issue
                targetDate = $targetDate
                numbers = $optimized.numbers
                backtest = $optimized.backtest
                randomBaseline = $optimized.randomBaseline
                strategyPool = @($optimized.strategyPool)
                createdAt = $createdAt
                status = 'pending'
                savedBy = 'fetch'
            }) | Out-Null
        }
    }

    return [pscustomobject]@{
        generatedAt = $createdAt
        items = @($items | Sort-Object @{ Expression = 'createdAt'; Descending = $true }, @{ Expression = 'source'; Descending = $false }, @{ Expression = 'game'; Descending = $false } | Select-Object -First 300)
    }
}

function New-ForecastEvaluation {
    param([object]$Forecasts)

    return [pscustomobject]@{
        generatedAt = $Forecasts.generatedAt
        items = @(
            foreach ($source in @('am', 'hk')) {
                foreach ($game in @('three-hit-three', 'special-number')) {
                    $row = @($Forecasts.items | Where-Object { $_.source -eq $source -and $_.game -eq $game -and $_.status -eq 'pending' } | Select-Object -First 1)
                    if ($row.Count -eq 0) { continue }
                    [pscustomobject]@{
                        source = $source
                        sourceName = $row[0].sourceName
                        game = $game
                        gameName = $row[0].gameName
                        displayYear = $row[0].displayYear
                        issue = $row[0].issue
                        targetDate = $row[0].targetDate
                        selectedStrategy = $row[0].selectedStrategy
                        selectedStrategyName = $row[0].selectedStrategyName
                        odds = $row[0].odds
                        weekBacktest = $row[0].weekBacktest
                        walkForwardBacktest = $row[0].walkForwardBacktest
                        weeklyProfitGate = $row[0].weeklyProfitGate
                        recommendationStatus = $row[0].recommendationStatus
                        qualityScore = $row[0].qualityScore
                        qualityLevel = $row[0].qualityLevel
                        backtest = $row[0].backtest
                        randomBaseline = $row[0].randomBaseline
                        edgeVsRandom = $row[0].backtest.edgeVsRandom
                        roiVsRandom = $row[0].backtest.roiVsRandom
                        strategyPool = @($row[0].strategyPool)
                    }
                }
            }
        )
    }
}

function Get-Window5RawWindows {
    param([object[]]$Rows)

    if (@($Rows).Count -eq 0) { return @() }
    $maxIssue = @($Rows | ForEach-Object { [int]$_.issue } | Measure-Object -Maximum).Maximum
    $windows = @()
    for ($start = 1; $start -le $maxIssue; $start += 5) {
        $end = $start + 4
        $chunk = @($Rows | Where-Object { [int]$_.issue -ge $start -and [int]$_.issue -le $end })
        if ($chunk.Count -eq 0) { continue }
        $nums = @($chunk | ForEach-Object { ([int]$_.balls[6].numberText).ToString('00') } | Select-Object -Unique)
        $windows += [pscustomobject]@{ start = $start; end = $end; nums = $nums }
    }
    return $windows
}

function Get-GreedyWindow5Pool {
    param([object[]]$Windows)

    $maxPoolSize = 8
    $selected = New-Object 'System.Collections.Generic.List[string]'
    $uncovered = New-Object 'System.Collections.Generic.List[int]'
    for ($i = 0; $i -lt @($Windows).Count; $i++) { $uncovered.Add($i) | Out-Null }
    while ($uncovered.Count -gt 0 -and $selected.Count -lt $maxPoolSize) {
        $bestNum = ''
        $bestGain = -1
        foreach ($n in 1..49) {
            $num = $n.ToString('00')
            if ($selected.Contains($num)) { continue }
            $gain = 0
            foreach ($idx in @($uncovered)) {
                if (@($Windows[$idx].nums) -contains $num) { $gain++ }
            }
            if ($gain -gt $bestGain) {
                $bestGain = $gain
                $bestNum = $num
            }
        }
        if ($bestGain -le 0 -or [string]::IsNullOrWhiteSpace($bestNum)) { break }
        $selected.Add($bestNum) | Out-Null
        foreach ($idx in @($uncovered.ToArray())) {
            if (@($Windows[$idx].nums) -contains $bestNum) { $uncovered.Remove($idx) | Out-Null }
        }
    }
    return @($selected)
}

function Get-StableWindow5Pool {
    param([object[]]$SourceRows, [string]$CurrentYear)

    $freq = @{}
    $years = @($SourceRows | Where-Object { ([string]$_.date).Length -ge 4 -and -not ([string]$_.date).StartsWith($CurrentYear + '-') } | ForEach-Object { ([string]$_.date).Substring(0, 4) } | Sort-Object -Unique)
    foreach ($year in $years) {
        $rows = @($SourceRows | Where-Object { ([string]$_.date).StartsWith($year + '-') } | Sort-Object @{ Expression = 'issue'; Descending = $false })
        $pool = @(Get-GreedyWindow5Pool -Windows (Get-Window5RawWindows -Rows $rows))
        foreach ($num in $pool) {
            if (-not $freq.ContainsKey($num)) { $freq[$num] = 0 }
            $freq[$num]++
        }
    }
    $take = 15
    if ($freq.Count -lt $take) {
        foreach ($row in $SourceRows) {
            $num = ([int]$row.balls[6].numberText).ToString('00')
            if (-not $freq.ContainsKey($num)) { $freq[$num] = 0 }
            $freq[$num]++
        }
    }
    return @($freq.GetEnumerator() | Sort-Object @{ Expression = 'Value'; Descending = $true }, @{ Expression = { [int]$_.Key }; Descending = $false } | Select-Object -First $take | ForEach-Object { $_.Key })
}

function New-Window5State {
    param([object[]]$Records, [object]$Existing = $null, [string]$GeneratedAt = '')

    $items = @(
        foreach ($source in @('am', 'hk')) {
            $sourceRows = @($Records | Where-Object { $_.source -eq $source -and -not [string]::IsNullOrWhiteSpace([string]$_.date) })
            if ($sourceRows.Count -eq 0) { continue }
            $latest = @($sourceRows | Sort-Object @{ Expression = 'date'; Descending = $true }, @{ Expression = 'issue'; Descending = $true } | Select-Object -First 1)[0]
            $year = ([string]$latest.date).Substring(0, 4)
            $yearRows = @($sourceRows | Where-Object { ([string]$_.date).StartsWith($year + '-') } | Sort-Object @{ Expression = 'issue'; Descending = $false })
            $pool = @(Get-GreedyWindow5Pool -Windows (Get-Window5RawWindows -Rows $yearRows) | Select-Object -First 8)
            $existingItem = @($Existing.items | Where-Object { $_.source -eq $source -and [string]$_.year -eq $year } | Select-Object -First 1)
            $oldPool = if ($existingItem.Count -gt 0) { @($existingItem[0].yearPool | Select-Object -First 8 | ForEach-Object { ([int]$_).ToString('00') }) } else { @() }
            $changed = ($pool -join ',') -ne ($oldPool -join ',')
            $changeTime = if ($changed -or $existingItem.Count -eq 0 -or [string]::IsNullOrWhiteSpace([string]$existingItem[0].changeTime)) { $GeneratedAt } else { [string]$existingItem[0].changeTime }
            $interval = if ($source -eq 'hk') { 10 } else { 20 }
            $latestIssue = [int]$latest.issue
            $oldStablePool = if ($existingItem.Count -gt 0 -and $null -ne $existingItem[0].stablePool) { @($existingItem[0].stablePool | Where-Object { [int]$_ -ge 1 } | Select-Object -First 15 | ForEach-Object { ([int]$_).ToString('00') }) } else { @() }
            $oldStableIssue = if ($existingItem.Count -gt 0 -and $null -ne $existingItem[0].stablePoolLastIssue) { [int]$existingItem[0].stablePoolLastIssue } else { 0 }
            $nextRecalcIssue = if ($oldStableIssue -gt 0) { $oldStableIssue + $interval } else { [Math]::Ceiling($latestIssue / $interval) * $interval }
            $shouldRecalcStable = $existingItem.Count -eq 0 -or $oldStablePool.Count -lt 15 -or $latestIssue -ge $nextRecalcIssue -or [string]$existingItem[0].year -ne $year
            $newStablePool = @(if ($shouldRecalcStable) { @(Get-StableWindow5Pool -SourceRows $sourceRows -CurrentYear $year | Select-Object -First 15) } else { @($oldStablePool | Select-Object -First 15) })
            $stableChanged = ($newStablePool -join ',') -ne ($oldStablePool -join ',')
            $stableChangeTime = if ($stableChanged -or $existingItem.Count -eq 0 -or [string]::IsNullOrWhiteSpace([string]$existingItem[0].stablePoolChangeTime)) { $GeneratedAt } else { [string]$existingItem[0].stablePoolChangeTime }
            [pscustomobject]@{
                source = $source
                year = $year
                yearPool = $pool
                adjustmentStatus = if ($changed) { (U @(0x6709,0x53D8,0x66F4)) } else { (U @(0x65E0,0x53D8,0x66F4)) }
                adjustmentReason = if ($changed) { (U @(0x6700,0x65B0,0x5F00,0x5956,0x540E,0x5F53,0x5E74,0x8986,0x76D6,0x6C60,0x5DF2,0x8C03,0x6574)) } else { (U @(0x672C,0x6B21,0x91CD,0x7B97,0x4E0E,0x4E0A,0x6B21,0x4E00,0x81F4)) }
                changeTime = $changeTime
                stablePool = @($newStablePool)
                stablePoolStatus = if (-not $shouldRecalcStable) { (U @(0x672A,0x89E6,0x53D1)) } elseif ($stableChanged) { (U @(0x6709,0x53D8,0x66F4)) } else { (U @(0x65E0,0x53D8,0x66F4)) }
                stablePoolReason = if (-not $shouldRecalcStable) { (U @(0x672A,0x5230,0x91CD,0x7B97,0x6761,0x4EF6,0xFF0C,0x6CBF,0x7528,0x4E0A,0x6B21,0x8DE8,0x5E74,0x7A33,0x5B9A,0x6C60)) } else { (U @(0x5DF2,0x6309,0x5468,0x671F,0x89C4,0x5219,0x91CD,0x7B97,0x8DE8,0x5E74,0x7A33,0x5B9A,0x6C60)) }
                stablePoolChangeTime = $stableChangeTime
                stablePoolLastIssue = if ($shouldRecalcStable) { $latestIssue } else { $oldStableIssue }
                stablePoolNextRecalcIssue = if ($shouldRecalcStable) { $latestIssue + $interval } else { $nextRecalcIssue }
                computedAt = $GeneratedAt
            }
        }
    )

    return [pscustomobject]@{ generatedAt = $GeneratedAt; items = $items }
}

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
        $displayYear = Get-DisplayYearForTarget -TargetDate $targetDate -Latest $latest

        foreach ($game in @('three-hit-three', 'special-number')) {
            $gameName = if ($game -eq 'three-hit-three') { (U @(0x4E09, 0x4E2D, 0x4E09)) } else { (U @(0x7279, 0x522B, 0x53F7)) }
            $existingForTarget = @($items | Where-Object { $_.source -eq $source -and $_.game -eq $game -and [int]$_.issue -eq $issue -and $_.displayYear -eq $displayYear -and [string]$_.targetDate -eq [string]$targetDate })
            $existingAlgorithmIds = @($existingForTarget | ForEach-Object { $_.algorithmId })
            $hasCompleteTarget = $existingForTarget.Count -ge 13 -and ($existingAlgorithmIds -contains 'ensemble') -and ($existingAlgorithmIds -contains 'mirofish-sandbox') -and (@(Get-GameAlgorithms | Where-Object { $existingAlgorithmIds -notcontains $_.id }).Count -eq 0)
            if ($hasCompleteTarget) { continue }

            $algorithmRows = @()
            $seedIdentity = Get-TargetIdentity -Source $source -Latest $latest -Issue $issue -TargetDate $targetDate -DisplayYear $displayYear
            foreach ($algorithm in Get-GameAlgorithms) {
                if ($existingAlgorithmIds -contains $algorithm.id) { continue }
                $numbers = @(Get-AlgorithmNumbers -SourceRecords $sourceRecords -Game $game -AlgorithmId $algorithm.id -SeedIdentity $seedIdentity)
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

            $voteRows = @($existingForTarget | Where-Object { $_.algorithmId -ne 'ensemble' }) + @($algorithmRows)
            $votes = @{}
            foreach ($row in $voteRows) {
                foreach ($num in $row.numbers) {
                    if (-not $votes.ContainsKey($num)) { $votes[$num] = 0 }
                    $votes[$num]++
                }
            }
            $take = if ($game -eq 'three-hit-three') { 3 } else { 1 }
            $ensembleNumbers = @($votes.GetEnumerator() | Sort-Object @{ Expression = 'Value'; Descending = $true }, @{ Expression = { [int]$_.Key }; Descending = $false } | Select-Object -First $take | ForEach-Object { $_.Key })
            if ($existingAlgorithmIds -notcontains 'ensemble') {
                $items.Add([pscustomobject]@{
                    id = ('{0}-{1}-{2}-{3}-ensemble' -f $source, $game, $displayYear, $issue)
                    source = $source
                    sourceName = Get-SourceName $source
                    game = $game
                    gameName = $gameName
                    algorithmId = 'ensemble'
                    algorithmName = (U @(0x7EFC, 0x5408, 0x4E3B, 0x63A8))
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
            if ($existingAlgorithmIds -notcontains 'mirofish-sandbox') {
                $miroFishNumbers = @(Get-MiroFishSandboxNumbers -SourceRecords $sourceRecords -Game $game -SeedIdentity $seedIdentity)
                $items.Add([pscustomobject]@{
                    id = ('{0}-{1}-{2}-{3}-mirofish-sandbox' -f $source, $game, $displayYear, $issue)
                    source = $source
                    sourceName = Get-SourceName $source
                    game = $game
                    gameName = $gameName
                    algorithmId = 'mirofish-sandbox'
                    algorithmName = 'MiroFish 沙盘推演'
                    year = $latest.year
                    displayYear = $displayYear
                    issue = $issue
                    targetDate = $targetDate
                    numbers = $miroFishNumbers
                    createdAt = $createdAt
                    status = 'pending'
                    savedBy = 'fetch'
                }) | Out-Null
            }
        }
    }

    return [pscustomobject]@{
        generatedAt = $createdAt
        items = @($items | Sort-Object @{ Expression = 'createdAt'; Descending = $true }, @{ Expression = 'source'; Descending = $false }, @{ Expression = 'game'; Descending = $false }, @{ Expression = 'algorithmId'; Descending = $false } | Select-Object -First 500)
    }
}

function Get-RecordComboKeys {
    param([object]$Record)

    $firstSix = @($Record.balls | Select-Object -First 6 | ForEach-Object { ([int]$_.numberText).ToString('00') } | Sort-Object { [int]$_ })
    return @(Get-Choose3 -Nums $firstSix | ForEach-Object { Get-ComboKey -Nums $_ })
}

function Get-SanZhongPortfolioMetrics {
    param([object[]]$SourceRecords, [object[]]$Recommendations)

    $keys = @{}
    foreach ($rec in @($Recommendations)) {
        if ($rec.key) {
            $keys[$rec.key] = $true
        }
        elseif ($rec.combo) {
            $keys[(Get-ComboKey -Nums $rec.combo)] = $true
        }
    }

    $hitOrders = New-Object 'System.Collections.Generic.List[int]'
    for ($order = 0; $order -lt $SourceRecords.Count; $order++) {
        $matched = $false
        foreach ($key in (Get-RecordComboKeys -Record $SourceRecords[$order])) {
            if ($keys.ContainsKey($key)) {
                $matched = $true
                break
            }
        }
        if ($matched) { [void]$hitOrders.Add($order) }
    }

    $currentMiss = if ($hitOrders.Count -gt 0) { $hitOrders[0] } else { $SourceRecords.Count }
    $maxMiss = $currentMiss
    for ($i = 1; $i -lt $hitOrders.Count; $i++) {
        $maxMiss = [Math]::Max($maxMiss, $hitOrders[$i] - $hitOrders[$i - 1] - 1)
    }
    if ($hitOrders.Count -eq 0) { $maxMiss = $SourceRecords.Count }

    $coverage = {
        param([int]$Limit)
        $take = [Math]::Min($Limit, $SourceRecords.Count)
        if ($take -le 0) { return 0 }
        $hits = @($hitOrders | Where-Object { $_ -lt $take }).Count
        return [Math]::Round($hits / $take * 100, 1)
    }

    return [pscustomobject]@{
        currentMiss = $currentMiss
        maxMiss = $maxMiss
        hitCount = $hitOrders.Count
        allCoverage = if ($SourceRecords.Count -gt 0) { [Math]::Round($hitOrders.Count / $SourceRecords.Count * 100, 1) } else { 0 }
        coverage60 = & $coverage 60
        coverage120 = & $coverage 120
        coverage240 = & $coverage 240
    }
}

function Get-SanZhongPortfolioMetricsFromOrders {
    param([int]$TotalRecords, [object[]]$Recommendations)

    $seenOrders = @{}
    foreach ($rec in @($Recommendations)) {
        foreach ($order in @($rec.hitOrders)) {
            $seenOrders[[int]$order] = $true
        }
    }
    $hitOrders = @($seenOrders.Keys | ForEach-Object { [int]$_ } | Sort-Object)

    $currentMiss = if ($hitOrders.Count -gt 0) { $hitOrders[0] } else { $TotalRecords }
    $maxMiss = $currentMiss
    for ($i = 1; $i -lt $hitOrders.Count; $i++) {
        $maxMiss = [Math]::Max($maxMiss, $hitOrders[$i] - $hitOrders[$i - 1] - 1)
    }
    if ($hitOrders.Count -eq 0) { $maxMiss = $TotalRecords }

    $coverage = {
        param([int]$Limit)
        $take = [Math]::Min($Limit, $TotalRecords)
        if ($take -le 0) { return 0 }
        $hits = @($hitOrders | Where-Object { $_ -lt $take }).Count
        return [Math]::Round($hits / $take * 100, 1)
    }

    return [pscustomobject]@{
        currentMiss = $currentMiss
        maxMiss = $maxMiss
        hitCount = $hitOrders.Count
        allCoverage = if ($TotalRecords -gt 0) { [Math]::Round($hitOrders.Count / $TotalRecords * 100, 1) } else { 0 }
        coverage60 = & $coverage 60
        coverage120 = & $coverage 120
        coverage240 = & $coverage 240
    }
}

function Get-SanZhongRollingBacktest {
    param([object[]]$SourceRecords, [object[]]$Recommendations, [int]$Window = 120)

    $keys = @{}
    foreach ($rec in @($Recommendations)) { $keys[$rec.key] = $true }
    $limit = [Math]::Min($Window, $SourceRecords.Count)
    $tested = 0
    $hits = 0
    for ($target = 0; $target -lt $limit; $target++) {
        $matched = $false
        foreach ($key in (Get-RecordComboKeys -Record $SourceRecords[$target])) {
            if ($keys.ContainsKey($key)) {
                $matched = $true
                break
            }
        }
        $tested++
        if ($matched) { $hits++ }
    }

    return [pscustomobject]@{
        tested = $tested
        hits = $hits
        hitRate = if ($tested -gt 0) { [Math]::Round($hits / $tested * 100, 1) } else { 0 }
        window = $Window
        mode = 'current-portfolio-window'
    }
}

function Get-SanZhongRecommendationsCore {
    param([object[]]$SourceRecords, [string]$Source, [bool]$IncludeBacktest = $true, [string]$SeedIdentity = '')

    $stats = @{}
    foreach ($a in 1..47) {
        foreach ($b in (($a + 1)..48)) {
            foreach ($c in (($b + 1)..49)) {
                $combo = @($a.ToString('00'), $b.ToString('00'), $c.ToString('00'))
                $key = $combo -join '-'
                $stats[$key] = [pscustomobject]@{
                    combo = $combo
                    key = $key
                    hits = 0
                    lastSeen = $SourceRecords.Count
                    recentHits = 0
                    recent120Hits = 0
                    recent240Hits = 0
                    hitOrders = New-Object 'System.Collections.Generic.List[int]'
                }
            }
        }
    }

    for ($order = 0; $order -lt $SourceRecords.Count; $order++) {
        $firstSix = @($SourceRecords[$order].balls | Select-Object -First 6 | ForEach-Object { ([int]$_.numberText).ToString('00') } | Sort-Object { [int]$_ } -Unique)
        for ($i = 0; $i -lt $firstSix.Count - 2; $i++) {
            for ($j = $i + 1; $j -lt $firstSix.Count - 1; $j++) {
                for ($k = $j + 1; $k -lt $firstSix.Count; $k++) {
                    $combo = @($firstSix[$i], $firstSix[$j], $firstSix[$k])
                    $key = $combo -join '-'
                    $item = $stats[$key]
                    if ($null -eq $item) { continue }
                    $item.hits++
                    $item.lastSeen = [Math]::Min($item.lastSeen, $order)
                    [void]$item.hitOrders.Add($order)
                    if ($order -lt 60) { $item.recentHits++ }
                    if ($order -lt 120) { $item.recent120Hits++ }
                    if ($order -lt 240) { $item.recent240Hits++ }
                }
            }
        }
    }

    if ([string]::IsNullOrWhiteSpace($SeedIdentity)) {
        $latest = @($SourceRecords | Select-Object -First 1)
        $SeedIdentity = Get-RecordIdentity $latest[0]
    }
    $candidates = @(
        foreach ($item in $stats.Values) {
            $miss = $item.lastSeen
            $score = $item.recentHits * 6 + $item.recent120Hits * 3.2 + $item.recent240Hits * 1.4 + $item.hits * 0.35 - [Math]::Min($miss, 180) * 0.08 + (Get-SeededNoise "$SeedIdentity|sanzhong|$Source|$($item.combo -join '-')") * 0.5
            [pscustomobject]@{
                combo = $item.combo
                key = $item.key
                hits = $item.hits
                miss = $miss
                recentHits = $item.recentHits
                recent120Hits = $item.recent120Hits
                recent240Hits = $item.recent240Hits
                score = $score
                hitOrders = @($item.hitOrders)
            }
        }
    ) | Sort-Object @{ Expression = 'score'; Descending = $true } | Select-Object -First 240

    $selected = @()
    while ($selected.Count -lt 10 -and $candidates.Count -gt 0) {
        $best = $null
        foreach ($candidate in $candidates) {
            if (@($selected | Where-Object { $_.key -eq $candidate.key }).Count -gt 0) { continue }
            $test = @($selected + $candidate)
            $metrics = Get-SanZhongPortfolioMetricsFromOrders -TotalRecords $SourceRecords.Count -Recommendations $test
            $portfolioScore = $metrics.coverage120 * 1200 + $metrics.coverage240 * 500 + $metrics.coverage60 * 800 - $metrics.currentMiss * 90 - $metrics.maxMiss * 25 + $candidate.score
            if ($null -eq $best -or $portfolioScore -gt $best.portfolioScore) {
                $best = [pscustomobject]@{ candidate = $candidate; portfolio = $metrics; portfolioScore = $portfolioScore }
            }
        }
        if ($null -eq $best) { break }
        $selected += $best.candidate
    }

    $portfolio = Get-SanZhongPortfolioMetricsFromOrders -TotalRecords $SourceRecords.Count -Recommendations $selected
    $backtest = if ($IncludeBacktest) { Get-SanZhongRollingBacktest -SourceRecords $SourceRecords -Recommendations $selected } else { [pscustomobject]@{ tested = 0; hits = 0; hitRate = 0; window = 0; mode = 'skipped' } }
    return [pscustomobject]@{
        combos = @($selected | ForEach-Object { ,@($_.combo | ForEach-Object { ([int]$_).ToString('00') }) })
        rows = @($selected | ForEach-Object {
            [pscustomobject]@{
                combo = @($_.combo | ForEach-Object { ([int]$_).ToString('00') })
                key = $_.key
                hits = $_.hits
                miss = $_.miss
                recentHits = $_.recentHits
                recent120Hits = $_.recent120Hits
                recent240Hits = $_.recent240Hits
                score = [Math]::Round($_.score, 1)
            }
        })
        portfolio = $portfolio
        backtest = $backtest
        verifiedCandidates = 18424
        method = 'exhaustive-49c3-portfolio'
    }
}

function Get-SanZhongRecommendations {
    param([object[]]$SourceRecords, [string]$Source, [string]$SeedIdentity = '')
    return Get-SanZhongRecommendationsCore -SourceRecords $SourceRecords -Source $Source -IncludeBacktest $true -SeedIdentity $SeedIdentity
}

function New-GeneratedPredictions {
    param([object[]]$Records, [object[]]$Existing = @())

    $createdAt = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $next = @()
    $sanzhong = @()
    foreach ($source in @('am', 'hk')) {
        $latest = Get-LatestRecord -Records $Records -Source $source
        if ($null -eq $latest) { continue }
        $sourceRecords = @($Records | Where-Object { $_.source -eq $source })
        $targetDate = Get-NextDrawDate -SourceRecords $sourceRecords -Source $source
        $issue = [int]$latest.issue + 1
        $displayYear = Get-DisplayYearForTarget -TargetDate $targetDate -Latest $latest
        $numbers = @(Get-BestPredictionNumbers -SourceRecords $sourceRecords)
        if ($numbers.Count -eq 7) {
            $next += [pscustomobject]@{ id = ('{0}-{1}-{2}-next' -f $source, $displayYear, $issue); source = $source; sourceName = Get-SourceName $source; year = $latest.year; displayYear = $displayYear; issue = $issue; targetDate = $targetDate; numbers = $numbers; createdAt = $createdAt; savedBy = 'fetch' }
        }
        $seedIdentity = Get-TargetIdentity -Source $source -Latest $latest -Issue $issue -TargetDate $targetDate -DisplayYear $displayYear
        $sanZhongResult = Get-SanZhongRecommendations -SourceRecords $sourceRecords -Source $source -SeedIdentity $seedIdentity
        $combos = @($sanZhongResult.combos)
        if ($combos.Count -gt 0) {
            $sanzhong += [pscustomobject]@{
                id = ('{0}-{1}-{2}-sanzhong' -f $source, $displayYear, $issue)
                source = $source
                sourceName = Get-SourceName $source
                year = $latest.year
                displayYear = $displayYear
                issue = $issue
                targetDate = $targetDate
                combos = $combos
                rows = $sanZhongResult.rows
                portfolio = $sanZhongResult.portfolio
                backtest = $sanZhongResult.backtest
                verifiedCandidates = $sanZhongResult.verifiedCandidates
                method = $sanZhongResult.method
                createdAt = $createdAt
                savedBy = 'fetch'
            }
        }
    }

    $oldNext = @($Existing | Where-Object { $_.type -eq 'next' } | ForEach-Object { $_.item })
    $oldSanZhong = @($Existing | Where-Object { $_.type -eq 'sanzhong' } | ForEach-Object { $_.item })
    $merge = {
        param([object[]]$OldItems, [object[]]$NewItems)
        $seen = @{}
        $out = New-Object 'System.Collections.Generic.List[object]'
        foreach ($item in @($NewItems + $OldItems)) {
            $displayYear = if ($item.displayYear) { $item.displayYear } elseif ($item.targetDate) { ([string]$item.targetDate).Substring(0, 4) } else { $item.year }
            $key = '{0}|{1}|{2}' -f $item.source, $displayYear, $item.issue
            if ($seen.ContainsKey($key)) { continue }
            $seen[$key] = $true
            $out.Add($item) | Out-Null
        }
        return @($out | Select-Object -First 100)
    }
    return [pscustomobject]@{
        next = & $merge $oldNext $next
        sanzhong = & $merge $oldSanZhong $sanzhong
    }
}

function New-DashboardHtml {
    param([string]$EmbeddedJson)

    $safeJson = $EmbeddedJson -replace '</script', '<\/script'
    $html = @'
<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>&#24320;&#22870;&#35760;&#24405;&#25968;&#25454;&#30475;&#26495;</title>
  <style>
    :root { color-scheme: light; font-family: "Microsoft YaHei", Arial, sans-serif; }
    body { margin: 0; background: #f4f5f7; color: #1f2933; }
    header { background: #0b42d8; color: #fff; padding: 14px 18px; display: flex; justify-content: space-between; align-items: center; }
    header h1 { margin: 0; font-size: 20px; font-weight: 700; }
    header a { color: #fff; text-decoration: none; font-size: 14px; }
    main { max-width: 1180px; margin: 0 auto; padding: 16px; }
    .tabs { display: flex; gap: 8px; margin-bottom: 14px; flex-wrap: wrap; }
    .tabs button { border: 1px solid #cbd5e1; background: #fff; padding: 8px 12px; border-radius: 6px; cursor: pointer; }
    .tabs button.active { background: #0b42d8; color: #fff; border-color: #0b42d8; }
    .grid { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 12px; }
    .panel { background: #fff; border: 1px solid #d9dee7; border-radius: 8px; padding: 14px; }
    .panel h2 { margin: 0 0 10px; font-size: 16px; }
    .metric { font-size: 28px; font-weight: 800; }
    .muted { color: #667085; font-size: 13px; }
    .wide { grid-column: span 2; }
    .full { grid-column: 1 / -1; }
    table { width: 100%; border-collapse: collapse; font-size: 14px; }
    th, td { border-bottom: 1px solid #e5e7eb; padding: 8px; text-align: left; vertical-align: top; }
    .balls { display: flex; gap: 6px; flex-wrap: wrap; }
    .ball { min-width: 34px; padding: 4px 6px; color: #fff; border-radius: 4px; text-align: center; font-weight: 700; }
    .compact-table { table-layout: fixed; font-size: 13px; }
    .compact-table th, .compact-table td { padding: 7px 6px; }
    .compact-table .col-time { width: 112px; }
    .compact-table .col-source { width: 42px; }
    .compact-table .col-issue { width: 76px; }
    .compact-table .col-result { width: 56px; }
    .compact-table .col-draw { width: 176px; }
    .compact-balls { gap: 4px; align-items: flex-start; }
    .compact-balls .ball { min-width: 28px; padding: 3px 5px; line-height: 1.15; }
    .copy-qr { display: grid; grid-template-columns: 1fr 132px; gap: 12px; align-items: center; margin: 8px 0 10px; padding: 10px; border: 1px solid #e5e7eb; border-radius: 8px; background: #f8fafc; }
    .copy-qr strong { display: block; margin-bottom: 6px; font-size: 13px; }
    .copy-qr code { display: block; white-space: normal; word-break: break-all; font-family: Consolas, "Microsoft YaHei", sans-serif; font-size: 13px; }
    .copy-qr img { width: 120px; height: 120px; border: 1px solid #d9dee7; background: #fff; padding: 5px; border-radius: 6px; }
    .history-list { display: grid; gap: 8px; }
    .history-group { border: 1px solid #e5e7eb; border-radius: 8px; background: #fff; overflow: hidden; }
    .history-group summary { display: grid; grid-template-columns: 1fr 150px 110px; gap: 12px; align-items: center; padding: 10px 12px; cursor: pointer; font-size: 13px; font-weight: 700; list-style-position: inside; }
    .history-group[open] summary { border-bottom: 1px solid #e5e7eb; background: #f8fafc; }
    .history-group table { margin: 0; }
    .trail{display:flex;flex-wrap:wrap;gap:3px;max-width:220px}
    .trail i{display:inline-flex;align-items:center;justify-content:center;width:20px;height:20px;border-radius:4px;font-style:normal;font-size:12px;color:#fff}
    .trail .hit{background:#078a16}
    .trail .miss{background:#b8c0cc;color:#1f2937}
    .red { background: #ef1010; }
    .green { background: #07860a; }
    .blue { background: #0617f2; }
    .rank { display: grid; gap: 8px; }
    .bar { display: grid; grid-template-columns: 58px 1fr 42px; gap: 8px; align-items: center; }
    .bar-track { background: #eef2f7; border-radius: 999px; overflow: hidden; height: 10px; }
    .bar-fill { background: #0b42d8; height: 100%; }
    .filters { display: flex; gap: 10px; flex-wrap: wrap; margin-bottom: 12px; align-items: end; }
    .filters label { display: grid; gap: 4px; font-size: 13px; color: #475467; }
    select, input { border: 1px solid #cbd5e1; border-radius: 6px; padding: 7px 9px; background: #fff; min-width: 120px; }
    .mini { font-size: 12px; color: #667085; }
    .num-grid { display: grid; grid-template-columns: repeat(7, minmax(42px, 1fr)); gap: 8px; max-width: 520px; }
    .num-grid input { min-width: 0; text-align: center; font-weight: 700; }
    .actions { display: flex; gap: 8px; flex-wrap: wrap; margin: 12px 0; }
    .primary { border:1px solid #0b42d8; background:#0b42d8; color:#fff; padding:9px 14px; border-radius:6px; cursor:pointer; }
    .secondary { border:1px solid #cbd5e1; background:#fff; color:#1f2933; padding:9px 14px; border-radius:6px; cursor:pointer; }
    @media (max-width: 820px) { .grid { grid-template-columns: 1fr; } .wide { grid-column: auto; } .copy-qr { grid-template-columns: 1fr; } .history-group summary { grid-template-columns: 1fr; } }
  </style>
</head>
<body>
  <header>
    <h1>&#24320;&#22870;&#35760;&#24405;&#25968;&#25454;&#30475;&#26495;</h1>
    <div class="actions">
      <button id="manual-collect" class="primary" type="button">&#25163;&#21160;&#37319;&#38598;</button>
      <span id="collect-status" class="muted"></span>
      <a href="kjjl.html">&#36820;&#22238;&#24320;&#22870;&#35760;&#24405;</a>
    </div>
  </header>
  <main>
    <nav class="tabs">
      <button class="active" data-tab="overview">&#30475;&#26495;</button>
      <button data-tab="games">&#28216;&#25103;</button>
      <button data-tab="forecast">&#39044;&#27979;</button>
      <button data-tab="window5">5&#26399;&#31383;&#21475;</button>
      <button data-tab="threeWindow5">&#19977;&#20013;&#19977;5&#26399;&#31383;&#21475;</button>
      <button data-tab="patternWatch">&#35268;&#24459;&#35266;&#23519;</button>
      <button data-tab="patternAnalysis">&#35268;&#24459;&#20998;&#26512;</button>
      <button data-tab="daily">&#26085;&#25253;</button>
    </nav>
    <section id="app"></section>
  </main>
  <script id="embedded-records" type="application/json">
__EMBEDDED_JSON__
  </script>
  <script>
    const app = document.getElementById('app');
    const tabs = document.querySelectorAll('.tabs button');
    let records = [];
    let summary = null;
    let generatedPredictions = {next: [], sanzhong: []};
    let gamePredictions = {items: []};
    let forecastPredictions = {items: []};
    let window5State = {items: []};
    const esc = (value) => String(value ?? '').replace(/[&<>"']/g, (ch) => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[ch]));
    const pct = (value, max) => max ? Math.round(value / max * 100) : 0;
    function rankHtml(items, limit = 10) {
      const top = (items || []).slice(0, limit);
      const max = top[0]?.count || 1;
      return `<div class="rank">${top.map(item => `<div class="bar"><strong>${esc(item.name)}</strong><div class="bar-track"><div class="bar-fill" style="width:${pct(item.count, max)}%"></div></div><span>${item.count}</span></div>`).join('')}</div>`;
    }
    function ballsHtml(balls, compact = false) {
      return `<div class="balls ${compact ? 'compact-balls' : ''}">${balls.map(ball => `<span class="ball ${esc(ball.color)}">${esc(ball.numberText)}<br>${esc(ball.zodiac)}</span>`).join('')}</div>`;
    }
    const zodiacList = ['\u9f20','\u725b','\u864e','\u5154','\u9f99','\u86c7','\u9a6c','\u7f8a','\u7334','\u9e21','\u72d7','\u732a'];
    function zodiacOptions() {
      return `<option value="all">&#20840;&#37096;</option>${zodiacList.map(z => `<option value="${esc(z)}">${esc(z)}</option>`).join('')}`;
    }
    function uniq(values) { return [...new Set(values.filter(v => v !== null && v !== undefined && v !== ''))].sort(); }
    function flattenBalls(list) { return list.flatMap((record, order) => record.balls.map(ball => ({...ball, record, order}))); }
    function sourceRecords(source) { return records.filter(r => r.source === source); }
    function sourceSummary(source) { return summary.bySource?.[source] || {}; }
    function displayYear(record) {
      const dateText = String(record?.date || '');
      return dateText.length >= 4 ? dateText.slice(0, 4) : String(record?.year || '');
    }
    const sourceRecordCache = {};
    const sanZhongCache = {};
    const maxMissLimit = 6;
    function cachedSourceRecords(source) {
      if (!sourceRecordCache[source]) sourceRecordCache[source] = sourceRecords(source);
      return sourceRecordCache[source];
    }
    function sourceOptions(selected = 'am') {
      return `<option value="am" ${selected === 'am' ? 'selected' : ''}>&#28595;&#38376;</option><option value="hk" ${selected === 'hk' ? 'selected' : ''}>&#39321;&#28207;</option>`;
    }
    function sanzhongBacktestStatus(source) {
      const sourcePrediction = (generatedPredictions.sanzhong || []).find(item => item.source === source);
      return sourcePrediction?.backtest ? `${sourcePrediction.method || ''}:${sourcePrediction.backtest.hitRate || 0}%` : '';
    }
    function resetRecordCaches() {
      sourceRecordCache.am = null;
      sourceRecordCache.hk = null;
    }
    function applyPayload(data) {
      records = data.records || [];
      summary = data.summary || {};
      generatedPredictions = data.predictions || {next: [], sanzhong: []};
      gamePredictions = data.games || {items: []};
      forecastPredictions = data.forecasts || {items: []};
      window5State = data.window5 || {items: []};
      resetRecordCaches();
    }
    function isHostedDashboard() {
      return location.protocol === 'http:' || location.protocol === 'https:';
    }
    async function loadOnlineDataIfHosted() {
      if (!isHostedDashboard()) return false;
      try {
        const response = await fetch('/api/data', {cache: 'no-store'});
        if (!response.ok) return false;
        const data = await response.json();
        applyPayload(data);
        return true;
      } catch (err) {
        return false;
      }
    }
    async function manualCollect() {
      const button = document.getElementById('manual-collect');
      const status = document.getElementById('collect-status');
      if (!isHostedDashboard()) {
        status.textContent = '\u672c\u5730\u6587\u4ef6\u4e0d\u80fd\u76f4\u63a5\u8c03\u7528 Vercel \u91c7\u96c6\u63a5\u53e3';
        return;
      }
      button.disabled = true;
      status.textContent = '\u91c7\u96c6\u4e2d...';
      try {
        const response = await fetch('/api/collect', {method: 'POST'});
        const result = await response.json();
        if (!response.ok || !result.ok) throw new Error(result.error || '\u91c7\u96c6\u5931\u8d25');
        await loadOnlineDataIfHosted();
        status.textContent = `\u91c7\u96c6\u5b8c\u6210\uff1a${result.summary?.generatedAt || ''}`;
        renderOverview();
      } catch (err) {
        status.textContent = `\u91c7\u96c6\u5931\u8d25\uff1a${err.message}`;
      } finally {
        button.disabled = false;
      }
    }
    function renderOverview() {
      const selected = document.getElementById('overview-source')?.value || 'am';
      const selectedSummary = sourceSummary(selected);
      const selectedRecords = sourceRecords(selected);
      app.innerHTML = `<div class="grid">
        <section class="panel full"><div class="filters"><label>&#26469;&#28304;<select id="overview-source">${sourceOptions(selected)}</select></label></div></section>
        <section class="panel"><h2>&#35760;&#24405;&#24635;&#25968;</h2><div class="metric">${selectedSummary.totalRecords}</div><div class="muted">${esc(selectedSummary.sourceName)} pages/*.html</div></section>
        <section class="panel"><h2>&#21495;&#30721;&#26679;&#26412;</h2><div class="metric">${selectedSummary.totalBalls}</div><div class="muted">&#27599;&#26399; 7 &#20010;&#21495;&#30721;</div></section>
        <section class="panel"><h2>&#26368;&#26032;&#26399;&#21495;</h2><div class="metric">${selectedSummary.latest ? esc(selectedSummary.latest.issue) : '-'}</div><div class="muted">${selectedSummary.latest ? esc(selectedSummary.latest.date) : ''}</div></section>
        <section class="panel"><h2>&#26356;&#26032;&#26102;&#38388;</h2><div class="metric" style="font-size:18px">${esc(summary.generatedAt)}</div><div class="muted">&#26412;&#22320;&#29983;&#25104;&#26102;&#38388;</div></section>
        <section class="panel wide"><h2>&#26368;&#26032;&#24320;&#22870;</h2>${selectedSummary.latest ? `<p>${esc(displayYear(selectedSummary.latest))}&#24180; ${esc(selectedSummary.latest.issue)}&#26399; ${esc(selectedSummary.latest.date)}</p>${ballsHtml(selectedSummary.latest.balls)}` : ''}</section>
        <section class="panel wide"><h2>&#28909;&#38376;&#21495;&#30721;</h2>${rankHtml(selectedSummary.numbers, 12)}</section>
        <section class="panel wide"><h2>&#29983;&#32918;&#20998;&#24067;</h2>${rankHtml(selectedSummary.zodiacs, 12)}</section>
        <section class="panel wide"><h2>&#39068;&#33394;&#20998;&#24067;</h2>${rankHtml(selectedSummary.colors, 6)}</section>
        <section class="panel full"><h2>&#26368;&#36817; 20 &#26399;</h2><table><thead><tr><th>&#26469;&#28304;</th><th>&#24180;&#20221;</th><th>&#26399;&#21495;</th><th>&#26085;&#26399;</th><th>&#21495;&#30721;</th></tr></thead><tbody>${selectedRecords.slice(0, 20).map(r => `<tr><td>${esc(r.sourceName)}</td><td>${esc(displayYear(r))}</td><td>${esc(r.issue)}</td><td>${esc(r.date)}</td><td>${ballsHtml(r.balls)}</td></tr>`).join('')}</tbody></table></section>
      </div>`;
      document.getElementById('overview-source').addEventListener('change', renderOverview);
    }
    function gameRows(source, game) {
      return (gamePredictions.items || []).filter(item => item.source === source && item.game === game);
    }
    function forecastRows(source, game) {
      return (forecastPredictions.items || []).filter(item => item.source === source && item.game === game);
    }
    function asArray(value) {
      if (Array.isArray(value)) return value;
      if (value === null || value === undefined || value === '') return [];
      return [value];
    }
    function normalizeNumberGroup(value) {
      if (value && typeof value === 'object' && !Array.isArray(value) && Array.isArray(value.value)) return value.value;
      return asArray(value);
    }
    function numberChips(nums) {
      return `<div class="balls compact-balls">${normalizeNumberGroup(nums).map(n => `<span class="ball blue">${esc(String(Number(n)).padStart(2, '0'))}</span>`).join('')}</div>`;
    }
    const window5Pools = {
      hk: {stablePool: ['02','01','04','08','03','07','10','11','13','24','34','39','40','42','44']},
      am: {stablePool: ['08','01','05','06','09','10','12','20','23','30','02','03','24']}
    };
    function specialNum(record) {
      return String(Number(record?.balls?.[6]?.numberText || 0)).padStart(2, '0');
    }
    function fiveWindowCoverage(rows, pool) {
      if (!rows.length) return [];
      const maxIssue = Math.max(...rows.map(row => Number(row.issue || 0)));
      const poolSet = new Set(pool);
      const windows = [];
      for (let start = 1; start <= maxIssue; start += 5) {
        const end = start + 4;
        const chunk = rows.filter(row => Number(row.issue || 0) >= start && Number(row.issue || 0) <= end);
        if (!chunk.length) continue;
        const hits = chunk.filter(row => poolSet.has(specialNum(row))).map(row => ({issue: row.issue, date: row.date, num: specialNum(row)}));
        windows.push({start, end, count: chunk.length, hits, covered: hits.length > 0});
      }
      return windows;
    }
    const maxWindow5PoolSize = 8;
    const maxStableWindow5PoolSize = 15;
    function greedyFiveWindowPool(windows) {
      const allNums = Array.from({length: 49}, (_, idx) => String(idx + 1).padStart(2, '0'));
      const uncovered = new Set(windows.map((_, idx) => idx));
      const selected = [];
      while (uncovered.size > 0) {
        if (selected.length >= maxWindow5PoolSize) break;
        let best = null;
        allNums.forEach(num => {
          if (selected.includes(num)) return;
          let gain = 0;
          uncovered.forEach(idx => {
            if (windows[idx].nums.has(num)) gain++;
          });
          if (!best || gain > best.gain || (gain === best.gain && Number(num) < Number(best.num))) best = {num, gain};
        });
        if (!best || best.gain <= 0) break;
        selected.push(best.num);
        [...uncovered].forEach(idx => {
          if (windows[idx].nums.has(best.num)) uncovered.delete(idx);
        });
      }
      return selected;
    }
    function fiveWindowRawWindows(rows) {
      if (!rows.length) return [];
      const maxIssue = Math.max(...rows.map(row => Number(row.issue || 0)));
      const windows = [];
      for (let start = 1; start <= maxIssue; start += 5) {
        const end = start + 4;
        const chunk = rows.filter(row => Number(row.issue || 0) >= start && Number(row.issue || 0) <= end);
        if (!chunk.length) continue;
        windows.push({start, end, count: chunk.length, nums: new Set(chunk.map(specialNum))});
      }
      return windows;
    }
    function fiveWindowAnalysis(source) {
      const sourceRows = cachedSourceRecords(source).slice().sort((a, b) => Number(a.issue || 0) - Number(b.issue || 0));
      const latest = sourceRows.slice().sort((a, b) => String(b.date || '').localeCompare(String(a.date || '')) || Number(b.issue || 0) - Number(a.issue || 0))[0];
      const currentYear = displayYear(latest);
      const yearRows = sourceRows.filter(row => displayYear(row) === currentYear).sort((a, b) => Number(a.issue || 0) - Number(b.issue || 0));
      const pools = window5Pools[source] || window5Pools.am;
      const rawYearWindows = fiveWindowRawWindows(yearRows);
      const stateItem = (window5State.items || []).find(item => item.source === source && String(item.year) === String(currentYear));
      const yearPool = (stateItem?.yearPool?.length ? stateItem.yearPool : greedyFiveWindowPool(rawYearWindows)).slice(0, maxWindow5PoolSize);
      const stablePool = (stateItem?.stablePool?.length ? stateItem.stablePool : pools.stablePool).slice(0, maxStableWindow5PoolSize);
      const yearWindows = fiveWindowCoverage(yearRows, yearPool);
      const stableWindows = fiveWindowCoverage(yearRows, stablePool);
      const latestIssue = Number(latest?.issue || 0);
      const currentStart = Math.floor((latestIssue - 1) / 5) * 5 + 1;
      const currentWindow = yearWindows.find(item => item.start === currentStart) || {start: currentStart, end: currentStart + 4, count: 0, hits: [], covered: false};
      const yearly = [];
      const years = uniq(sourceRows.map(displayYear));
      years.forEach(year => {
        const rows = sourceRows.filter(row => displayYear(row) === year).sort((a, b) => Number(a.issue || 0) - Number(b.issue || 0));
        const pool = year === currentYear ? yearPool : stablePool;
        const windows = fiveWindowCoverage(rows, pool);
        const misses = windows.filter(item => !item.covered);
        yearly.push({year, total: windows.length, covered: windows.length - misses.length, misses});
      });
      const adjustmentStatus = stateItem?.adjustmentStatus || (yearPool.length > 0 ? '&#26080;&#21464;&#26356;' : '&#26080;&#25968;&#25454;');
      const adjustmentReason = stateItem?.adjustmentReason || (yearPool.length > 0 ? '&#26412;&#27425;&#37325;&#31639;&#19982;&#19978;&#27425;&#19968;&#33268;' : '&#24403;&#24180;&#26242;&#26080;&#24320;&#22870;&#31383;&#21475;');
      const changeTime = stateItem?.changeTime || summary.generatedAt || '';
      const stablePoolStatus = stateItem?.stablePoolStatus || '&#26410;&#35302;&#21457;';
      const stablePoolReason = stateItem?.stablePoolReason || '';
      const stablePoolChangeTime = stateItem?.stablePoolChangeTime || '';
      const stablePoolNextRecalcIssue = stateItem?.stablePoolNextRecalcIssue || '';
      return {source, latest, currentYear, currentWindow, yearPool, stablePool, yearWindows, stableWindows, yearly, adjustmentStatus, adjustmentReason, changeTime, stablePoolStatus, stablePoolReason, stablePoolChangeTime, stablePoolNextRecalcIssue};
    }
    function regularNums(record) {
      return (record?.balls || []).slice(0, 6).map(ball => String(ball.numberText || ball.number || '').padStart(2, '0'));
    }
    function comboKey(nums) {
      return nums.map(n => String(n).padStart(2, '0')).sort((a, b) => Number(a) - Number(b)).join('-');
    }
    function buildThreeHitCombos(records) {
      const rows = records.slice().sort((a, b) => Number(a.issue || 0) - Number(b.issue || 0));
      const numberCounts = new Map();
      rows.forEach(row => regularNums(row).forEach(num => numberCounts.set(num, (numberCounts.get(num) || 0) + 1)));
      const pool = [...numberCounts.entries()]
        .sort((a, b) => b[1] - a[1] || Number(a[0]) - Number(b[0]))
        .slice(0, 18)
        .map(item => item[0])
        .sort((a, b) => Number(a) - Number(b));
      const comboMap = new Map();
      rows.forEach(row => {
        const nums = regularNums(row).filter(num => pool.includes(num)).sort((a, b) => Number(a) - Number(b));
        for (let i = 0; i < nums.length - 2; i++) {
          for (let j = i + 1; j < nums.length - 1; j++) {
            for (let k = j + 1; k < nums.length; k++) {
              const numbers = [nums[i], nums[j], nums[k]];
              const key = comboKey(numbers);
              if (!comboMap.has(key)) comboMap.set(key, {numbers, hits: 0, windows: new Set(), lastIssue: 0});
              const item = comboMap.get(key);
              item.hits++;
              item.windows.add(Math.floor((Number(row.issue || 0) - 1) / 5));
              item.lastIssue = Math.max(item.lastIssue, Number(row.issue || 0));
            }
          }
        }
      });
      const ranked = [...comboMap.values()].map(item => ({
        numbers: item.numbers,
        hits: item.hits,
        windowHits: item.windows.size,
        lastIssue: item.lastIssue,
        score: item.windows.size * 10 + item.hits + item.lastIssue / 1000
      })).sort((a, b) => b.score - a.score || comboKey(a.numbers).localeCompare(comboKey(b.numbers)));
      const selected = [];
      ranked.forEach(item => {
        if (selected.length >= 12) return;
        const overlapTooHigh = selected.filter(existing => item.numbers.filter(num => existing.numbers.includes(num)).length >= 2).length >= 3;
        if (!overlapTooHigh) selected.push(item);
      });
      ranked.forEach(item => {
        if (selected.length >= 12) return;
        if (!selected.some(existing => comboKey(existing.numbers) === comboKey(item.numbers))) selected.push(item);
      });
      return {numberPool: pool, combos: selected};
    }
    function threeHitWindowCoverage(rows, combos) {
      if (!rows.length) return [];
      const maxIssue = Math.max(...rows.map(row => Number(row.issue || 0)));
      const windows = [];
      for (let start = 1; start <= maxIssue; start += 5) {
        const end = start + 4;
        const chunk = rows.filter(row => Number(row.issue || 0) >= start && Number(row.issue || 0) <= end);
        if (!chunk.length) continue;
        const hits = [];
        chunk.forEach(row => {
          const regular = regularNums(row);
          combos.forEach(combo => {
            if (combo.numbers.every(num => regular.includes(num))) hits.push({issue: row.issue, date: row.date, combo: combo.numbers});
          });
        });
        windows.push({start, end, count: chunk.length, hits, covered: hits.length > 0});
      }
      return windows;
    }
    function threeWindowAnalysis(source) {
      const sourceRows = cachedSourceRecords(source).slice().sort((a, b) => Number(a.issue || 0) - Number(b.issue || 0));
      const latest = sourceRows.slice().sort((a, b) => String(b.date || '').localeCompare(String(a.date || '')) || Number(b.issue || 0) - Number(a.issue || 0))[0];
      const currentYear = displayYear(latest);
      const yearRows = sourceRows.filter(row => displayYear(row) === currentYear).sort((a, b) => Number(a.issue || 0) - Number(b.issue || 0));
      const latestIssue = Number(latest?.issue || 0);
      const currentStart = Math.floor((latestIssue - 1) / 5) * 5 + 1;
      const currentEnd = currentStart + 4;
      const trainingRows = yearRows.filter(row => Number(row.issue || 0) < currentStart || Number(row.issue || 0) > currentEnd);
      const built = buildThreeHitCombos(trainingRows.length ? trainingRows : yearRows.length ? yearRows : sourceRows);
      const yearWindows = threeHitWindowCoverage(yearRows, built.combos);
      const currentWindow = yearWindows.find(item => item.start === currentStart) || {start: currentStart, end: currentStart + 4, count: 0, hits: [], covered: false};
      let maxMiss = 0;
      let currentMiss = 0;
      let run = 0;
      let hitWindows = 0;
      yearWindows.forEach(item => {
        if (item.covered) {
          hitWindows++;
          maxMiss = Math.max(maxMiss, run);
          run = 0;
        } else {
          run++;
        }
      });
      maxMiss = Math.max(maxMiss, run);
      for (let i = yearWindows.length - 1; i >= 0; i--) {
        if (yearWindows[i].covered) break;
        currentMiss++;
      }
      return {source, latest, currentYear, numberPool: built.numberPool, combos: built.combos, currentWindow, yearWindows, stats: {total: yearWindows.length, hits: hitWindows, misses: yearWindows.length - hitWindows, hitRate: yearWindows.length ? Math.round(hitWindows / yearWindows.length * 100) : 0, currentMiss, maxMiss}};
    }
    function randomWindowBaseline(pickCount, totalCount, drawsPerWindow) {
      if (!pickCount || !totalCount || !drawsPerWindow) return 0;
      return Math.round((1 - Math.pow(1 - pickCount / totalCount, drawsPerWindow)) * 10000) / 100;
    }
    function patternLevel(edge, currentMiss, maxMiss) {
      if (edge < 0 || (maxMiss > 0 && currentMiss > maxMiss)) return '&#22833;&#25928;';
      if (edge >= 15 && currentMiss <= 2) return '&#20248;&#31168;';
      if (edge >= 8 && currentMiss <= 3) return '&#33391;&#22909;';
      return '&#35266;&#23519;';
    }
    function patternStats(windows) {
      const completed = windows.filter(item => Number(item.count || 0) >= 5);
      const total = completed.length;
      const hits = completed.filter(item => item.covered).length;
      let currentMiss = 0;
      for (let i = completed.length - 1; i >= 0; i--) {
        if (completed[i].covered) break;
        currentMiss++;
      }
      let maxMiss = 0;
      let run = 0;
      completed.forEach(item => {
        if (item.covered) {
          maxMiss = Math.max(maxMiss, run);
          run = 0;
        } else {
          run++;
        }
      });
      maxMiss = Math.max(maxMiss, run);
      const recent = completed.slice(-10);
      const recentHits = recent.filter(item => item.covered).length;
      return {total, hits, hitRate: total ? Math.round(hits / total * 10000) / 100 : 0, currentMiss, maxMiss, recentHitRate: recent.length ? Math.round(recentHits / recent.length * 10000) / 100 : 0};
    }
    function specialStructureStats(rows) {
      const items = rows.map(row => row.balls?.[6]).filter(Boolean);
      const colorMap = new Map();
      const tailMap = new Map();
      items.forEach(ball => {
        colorMap.set(ball.color, (colorMap.get(ball.color) || 0) + 1);
        const tail = String(ball.numberText || '').slice(-1);
        tailMap.set(tail, (tailMap.get(tail) || 0) + 1);
      });
      const toRows = (map) => [...map.entries()].map(([name, count]) => ({name, count})).sort((a, b) => b.count - a.count || String(a.name).localeCompare(String(b.name)));
      return {colors: toRows(colorMap), tails: toRows(tailMap)};
    }
    function optimizedSpecialPool(rows, basePool, size) {
      const structure = specialStructureStats(rows);
      const tailRank = new Map(structure.tails.map((item, idx) => [String(item.name), structure.tails.length - idx]));
      const colorRank = new Map(structure.colors.map((item, idx) => [String(item.name), structure.colors.length - idx]));
      const freq = new Map();
      rows.forEach(row => {
        const ball = row.balls?.[6];
        if (!ball) return;
        const num = String(ball.numberText || '').padStart(2, '0');
        freq.set(num, {num, color: ball.color, count: (freq.get(num)?.count || 0) + 1});
      });
      const base = new Set(basePool);
      const scored = Array.from({length: 49}, (_, idx) => String(idx + 1).padStart(2, '0')).map(num => {
        const item = freq.get(num) || {num, color: '', count: 0};
        const tail = num.slice(-1);
        const score = item.count * 8 + (tailRank.get(tail) || 0) * 3 + (colorRank.get(item.color) || 0) * 2 + (base.has(num) ? 20 : 0);
        return {num, score};
      }).sort((a, b) => b.score - a.score || Number(a.num) - Number(b.num));
      const selected = [];
      const tailCounts = new Map();
      scored.forEach(item => {
        if (selected.length >= size) return;
        const tail = item.num.slice(-1);
        if ((tailCounts.get(tail) || 0) >= 2) return;
        selected.push(item.num);
        tailCounts.set(tail, (tailCounts.get(tail) || 0) + 1);
      });
      scored.forEach(item => {
        if (selected.length >= size) return;
        if (!selected.includes(item.num)) selected.push(item.num);
      });
      return selected;
    }
    function threeComboStructureStats(combos) {
      const spans = new Map();
      const parity = new Map();
      combos.forEach(item => {
        const nums = item.numbers.map(n => Number(n)).sort((a, b) => a - b);
        const span = nums[2] - nums[0];
        const spanName = span <= 12 ? '0-12' : span <= 24 ? '13-24' : '25+';
        spans.set(spanName, (spans.get(spanName) || 0) + 1);
        const odd = nums.filter(n => n % 2 === 1).length;
        const key = `${odd}\u5947${3 - odd}\u5076`;
        parity.set(key, (parity.get(key) || 0) + 1);
      });
      const toRows = (map) => [...map.entries()].map(([name, count]) => ({name, count})).sort((a, b) => b.count - a.count || String(a.name).localeCompare(String(b.name)));
      return {spans: toRows(spans), parity: toRows(parity)};
    }
    function optimizedThreeCombos(rows, baseCombos, size) {
      const built = buildThreeHitCombos(rows);
      const candidates = [...baseCombos, ...built.combos];
      const seen = new Set();
      const ranked = candidates.filter(item => {
        const key = comboKey(item.numbers);
        if (seen.has(key)) return false;
        seen.add(key);
        return true;
      }).map(item => ({...item, key: comboKey(item.numbers)})).sort((a, b) => (b.windowHits || 0) - (a.windowHits || 0) || (b.hits || 0) - (a.hits || 0) || a.key.localeCompare(b.key));
      const selected = [];
      const parityCounts = new Map();
      const spanCounts = new Map();
      ranked.forEach(item => {
        if (selected.length >= size) return;
        const nums = item.numbers.map(n => Number(n)).sort((a, b) => a - b);
        const odd = nums.filter(n => n % 2 === 1).length;
        const parity = `${odd}\u5947${3 - odd}\u5076`;
        const span = nums[2] - nums[0];
        const spanName = span <= 12 ? '0-12' : span <= 24 ? '13-24' : '25+';
        const overlapTooHigh = selected.filter(existing => item.numbers.filter(num => existing.numbers.includes(num)).length >= 2).length >= 3;
        if (overlapTooHigh || (parityCounts.get(parity) || 0) >= 5 || (spanCounts.get(spanName) || 0) >= 7) return;
        selected.push(item);
        parityCounts.set(parity, (parityCounts.get(parity) || 0) + 1);
        spanCounts.set(spanName, (spanCounts.get(spanName) || 0) + 1);
      });
      ranked.forEach(item => {
        if (selected.length >= size) return;
        if (!selected.some(existing => existing.key === item.key)) selected.push(item);
      });
      return selected.slice(0, size);
    }
    function optimizationCompareRow(name, original, optimized, baseline) {
      const originalEdge = Math.round((original.hitRate - baseline) * 100) / 100;
      const optimizedEdge = Math.round((optimized.hitRate - baseline) * 100) / 100;
      const delta = Math.round((optimized.hitRate - original.hitRate) * 100) / 100;
      const verdict = delta > 0 ? '\u4F18\u5316\u66F4\u4F18' : delta < 0 ? '\u539F\u6C60\u66F4\u4F18' : '\u6301\u5E73';
      return `<tr><td>${name}</td><td>${esc(original.hitRate)}%</td><td>${esc(optimized.hitRate)}%</td><td>${esc(baseline)}%</td><td>${esc(originalEdge)}%</td><td>${esc(optimizedEdge)}%</td><td>${esc(delta)}%</td><td>${verdict}</td></tr>`;
    }
    function patternWatchAnalysis(source) {
      const special = fiveWindowAnalysis(source);
      const three = threeWindowAnalysis(source);
      const specialStats = patternStats(special.yearWindows);
      const stableStats = patternStats(special.stableWindows);
      const threeStats = patternStats(three.yearWindows);
      const specialBaseline = randomWindowBaseline(special.yearPool.length, 49, 5);
      const stableBaseline = randomWindowBaseline(special.stablePool.length, 49, 5);
      const threeBaseline = randomWindowBaseline(three.combos.length * 20, 18424, 5);
      const yearRows = cachedSourceRecords(source).filter(row => displayYear(row) === special.currentYear);
      const optimizedSpecial = optimizedSpecialPool(yearRows, special.yearPool, 8);
      const optimizedStable = optimizedSpecialPool(yearRows, special.stablePool, 15);
      const optimizedThree = optimizedThreeCombos(yearRows, three.combos, 12);
      const optimizedSpecialStats = patternStats(fiveWindowCoverage(yearRows, optimizedSpecial));
      const optimizedStableStats = patternStats(fiveWindowCoverage(yearRows, optimizedStable));
      const optimizedThreeStats = patternStats(threeHitWindowCoverage(yearRows, optimizedThree));
      return {
        source,
        currentYear: special.currentYear,
        special: {...specialStats, baseline: specialBaseline, edge: Math.round((specialStats.hitRate - specialBaseline) * 100) / 100, level: patternLevel(specialStats.hitRate - specialBaseline, specialStats.currentMiss, specialStats.maxMiss), poolSize: special.yearPool.length, structure: specialStructureStats(yearRows)},
        stable: {...stableStats, baseline: stableBaseline, edge: Math.round((stableStats.hitRate - stableBaseline) * 100) / 100, level: patternLevel(stableStats.hitRate - stableBaseline, stableStats.currentMiss, stableStats.maxMiss), poolSize: special.stablePool.length},
        three: {...threeStats, baseline: threeBaseline, edge: Math.round((threeStats.hitRate - threeBaseline) * 100) / 100, level: patternLevel(threeStats.hitRate - threeBaseline, threeStats.currentMiss, threeStats.maxMiss), comboSize: three.combos.length, structure: threeComboStructureStats(three.combos)},
        optimized: {special: {pool: optimizedSpecial, stats: optimizedSpecialStats}, stable: {pool: optimizedStable, stats: optimizedStableStats}, three: {combos: optimizedThree, stats: optimizedThreeStats}}
      };
    }
    function recommendationSummary(rows) {
      const map = new Map();
      rows.forEach(row => {
        const nums = asArray(row.numbers).map(n => String(n).padStart(2, '0')).sort((a, b) => Number(a) - Number(b));
        const key = nums.join('-');
        if (!key) return;
        if (!map.has(key)) map.set(key, {numbers: nums, count: 0, algorithms: []});
        const item = map.get(key);
        item.count++;
        item.algorithms.push(row.algorithmName || row.algorithmId || '');
      });
      return [...map.values()].sort((a, b) => b.count - a.count || a.numbers.join('-').localeCompare(b.numbers.join('-')));
    }
    function recommendationCopyText(summaryRows, game) {
      if (game === 'special-number') {
        return summaryRows.map(item => String(Number(item.numbers[0]))).join(',');
      }
      return summaryRows.map(item => `\uFF08${item.numbers.join('-')}\uFF09`).join(',');
    }
    function recommendationSummaryHtml(rows, game) {
      const summaryRows = recommendationSummary(rows);
      const copyText = recommendationCopyText(summaryRows, game);
      const qrUrl = `https://api.qrserver.com/v1/create-qr-code/?size=160x160&data=${encodeURIComponent(copyText)}`;
      return `<h3>&#25512;&#33616;&#27719;&#24635;</h3>
        <div class="copy-qr"><div><strong>&#24494;&#20449;&#25195;&#30721;&#22797;&#21046;</strong><code>${esc(copyText)}</code></div><img alt="QR" src="${qrUrl}"></div>
        <table><thead><tr><th>&#25512;&#33616;&#32452;&#21512;</th><th>&#27425;&#25968;</th><th>&#26469;&#28304;&#31639;&#27861;</th></tr></thead><tbody>${summaryRows.map(item => `<tr><td>${numberChips(item.numbers)}</td><td>${item.count}</td><td>${esc(item.algorithms.join(', '))}</td></tr>`).join('')}</tbody></table>`;
    }
    function recommendationHistoryHtml(rows) {
      const historyRows = rows.filter(row => row.algorithmId !== 'ensemble' && row.algorithmId !== 'mirofish-sandbox');
      const map = new Map();
      historyRows.forEach(row => {
        const key = [row.targetDate || '', row.displayYear || '', row.issue || '', row.createdAt || ''].join('|');
        if (!map.has(key)) {
          map.set(key, {
            targetDate: row.targetDate || '',
            displayYear: row.displayYear || '',
            issue: row.issue || '',
            createdAt: row.createdAt || '',
            status: row.status || '',
            rows: []
          });
        }
        map.get(key).rows.push(row);
      });
      function historyGroupDate(group) {
        const actualRow = group.rows.find(row => row.status === 'settled' && row.actualDate);
        return actualRow ? actualRow.actualDate : group.targetDate;
      }
      const groups = [...map.values()].sort((a, b) =>
        String(b.createdAt || '').localeCompare(String(a.createdAt || '')) ||
        String(b.targetDate || '').localeCompare(String(a.targetDate || '')) ||
        Number(b.issue || 0) - Number(a.issue || 0)
      );
      return `<h3>&#25512;&#33616;&#35760;&#24405;</h3>
        <div class="history-list">${groups.slice(0, 30).map((group, idx) => {
          const settled = group.rows.filter(row => row.status === 'settled');
          const hits = settled.filter(row => row.hit).length;
          const summary = group.status === 'settled'
            ? `&#24050;&#24320;&#22870; ${hits}/${settled.length} &#21629;&#20013;`
            : '&#24453;&#24320;&#22870;';
          const actual = group.rows.find(row => row.actualNumbers)?.actualNumbers;
          return `<details class="history-group" ${idx === 0 ? 'open' : ''}>
            <summary><span>${esc(historyGroupDate(group))} ${esc(group.displayYear)} / ${esc(group.issue)}</span><span>${esc(group.createdAt)}</span><span>${summary}</span></summary>
            <table class="compact-table"><thead><tr><th>&#31639;&#27861;</th><th>&#25512;&#33616;</th><th class="col-result">&#32467;&#26524;</th><th class="col-draw">&#24320;&#22870;</th></tr></thead><tbody>${group.rows.map(row => `<tr><td>${esc(row.algorithmName)}</td><td>${numberChips(row.numbers)}</td><td>${row.status === 'settled' ? (row.hit ? '&#21629;&#20013;' : '&#26410;&#20013;') : '&#24453;&#24320;&#22870;'}</td><td>${actual ? numberChips(actual) : '-'}</td></tr>`).join('')}</tbody></table>
          </details>`;
        }).join('')}</div>`;
    }
    function recommendationHitsRecord(recommendation, record, game) {
      const nums = asArray(recommendation?.numbers).map(n => String(n).padStart(2, '0'));
      if (!record || nums.length === 0) return false;
      if (game === 'three-hit-three') {
        const regular = record.balls.slice(0, 6).map(ball => String(ball.numberText).padStart(2, '0'));
        return nums.length >= 3 && nums.slice(0, 3).every(num => regular.includes(num));
      }
      const special = String(record.balls[6]?.numberText || '').padStart(2, '0');
      return nums[0] === special;
    }
    function historicalMaxMissForRecommendations(source, game, recommendations) {
      const recs = cachedSourceRecords(source).slice().sort((a, b) => String(a.date || '').localeCompare(String(b.date || '')) || Number(a.issue || 0) - Number(b.issue || 0));
      const picks = recommendations.filter(row => asArray(row?.numbers).length > 0);
      if (recs.length === 0 || picks.length === 0) return 0;
      let maxMiss = 0;
      let run = 0;
      recs.forEach(record => {
        const hit = picks.some(pick => recommendationHitsRecord(pick, record, game));
        if (hit) {
          maxMiss = Math.max(maxMiss, run);
          run = 0;
        } else {
          run++;
        }
      });
      return Math.max(maxMiss, run);
    }
    function gameMissStats(rows, historicalMaxMiss = null) {
      const settled = rows.filter(row => row.status === 'settled').sort((a, b) => String(b.actualDate || '').localeCompare(String(a.actualDate || '')) || Number(b.actualIssue || 0) - Number(a.actualIssue || 0));
      let currentMiss = 0;
      for (const row of settled) {
        if (row.hit) break;
        currentMiss++;
      }
      let maxMiss = 0;
      let run = 0;
      let hits = 0;
      [...settled].reverse().forEach(row => {
        if (row.hit) {
          hits++;
          maxMiss = Math.max(maxMiss, run);
          run = 0;
        } else {
          run++;
        }
      });
      maxMiss = Math.max(maxMiss, run);
      return {currentMiss, maxMiss: historicalMaxMiss ?? maxMiss, hits, settled: settled.length};
    }
    function gameGroupStats(rows, historicalMaxMiss = null) {
      const map = new Map();
      rows.filter(row => row.status === 'settled').forEach(row => {
        const key = [row.actualDate || row.targetDate || '', row.displayYear || '', row.actualIssue || row.issue || ''].join('|');
        if (!map.has(key)) map.set(key, []);
        map.get(key).push(row);
      });
      const settledGroups = [...map.values()].map(group => ({
        actualDate: group[0].actualDate || group[0].targetDate || '',
        actualIssue: group[0].actualIssue || group[0].issue || 0,
        hit: group.some(row => row.hit)
      })).sort((a, b) => String(b.actualDate || '').localeCompare(String(a.actualDate || '')) || Number(b.actualIssue || 0) - Number(a.actualIssue || 0));
      let currentMiss = 0;
      for (const group of settledGroups) {
        if (group.hit) break;
        currentMiss++;
      }
      let maxMiss = 0;
      let run = 0;
      let hits = 0;
      [...settledGroups].reverse().forEach(group => {
        if (group.hit) {
          hits++;
          maxMiss = Math.max(maxMiss, run);
          run = 0;
        } else {
          run++;
        }
      });
      maxMiss = Math.max(maxMiss, run);
      return {currentMiss, maxMiss: historicalMaxMiss ?? maxMiss, hits, settled: settledGroups.length};
    }
    function gameSection(source, game, title) {
      const rows = gameRows(source, game).sort((a, b) => String(b.createdAt || '').localeCompare(String(a.createdAt || '')) || Number(b.issue || 0) - Number(a.issue || 0));
      const pendingOrLatest = rows.find(row => row.status === 'pending') || rows[0];
      const targetRows = pendingOrLatest ? rows.filter(row => Number(row.issue) === Number(pendingOrLatest.issue) && String(row.displayYear || '') === String(pendingOrLatest.displayYear || '') && String(row.targetDate || '') === String(pendingOrLatest.targetDate || '')) : [];
      const ensemble = targetRows.find(row => row.algorithmId === 'ensemble');
      const algorithms = targetRows.filter(row => row.algorithmId !== 'ensemble' && row.algorithmId !== 'mirofish-sandbox');
      const ensembleHistoricalMaxMiss = historicalMaxMissForRecommendations(source, game, ensemble ? [ensemble] : []);
      const algorithmHistoricalMaxMiss = historicalMaxMissForRecommendations(source, game, algorithms);
      const ensembleStats = gameMissStats(rows.filter(row => row.algorithmId === 'ensemble'), ensembleHistoricalMaxMiss);
      const algorithmStats = gameGroupStats(rows.filter(row => row.algorithmId !== 'ensemble' && row.algorithmId !== 'mirofish-sandbox'), algorithmHistoricalMaxMiss);
      return `<section class="panel full">
        <h2>${title}</h2>
        <div class="grid">
          <section class="panel wide"><h2>&#32508;&#21512;&#20027;&#25512;</h2>${ensemble ? `<p>${esc(ensemble.targetDate || '')} ${esc(ensemble.displayYear || '')} / ${esc(ensemble.issue || '')}</p>${numberChips(ensemble.numbers)}` : '<p class="muted">&#26242;&#26080;&#25512;&#33616;</p>'}</section>
          <section class="panel"><h2>&#32508;&#21512;&#20027;&#25512;&#25112;&#32489;</h2><p>&#24403;&#21069;&#36951;&#33853;&#65306;${ensembleStats.currentMiss}</p><p>&#21382;&#21490;&#26368;&#22823;&#36951;&#33853;&#65306;${ensembleStats.maxMiss}</p><p>&#24050;&#32467;&#31639;&#65306;${ensembleStats.settled}&#65292;&#21629;&#20013;&#65306;${ensembleStats.hits}</p></section>
          <section class="panel"><h2>11&#31639;&#27861;&#25972;&#20307;&#25112;&#32489;</h2><p>&#24403;&#21069;&#36951;&#33853;&#65306;${algorithmStats.currentMiss}</p><p>&#21382;&#21490;&#26368;&#22823;&#36951;&#33853;&#65306;${algorithmStats.maxMiss}</p><p>&#24050;&#32467;&#31639;&#65306;${algorithmStats.settled}&#65292;&#21629;&#20013;&#65306;${algorithmStats.hits}</p></section>
        </div>
        ${recommendationSummaryHtml(algorithms, game)}
        <h3>11&#31181;&#31639;&#27861;&#25512;&#33616;</h3>
        <table><thead><tr><th>&#31639;&#27861;</th><th>&#25512;&#33616;</th><th>&#30446;&#26631;&#26399;&#21495;</th><th>&#29366;&#24577;</th></tr></thead><tbody>${algorithms.map(row => `<tr><td>${esc(row.algorithmName)}</td><td>${numberChips(row.numbers)}</td><td>${esc(row.targetDate || '')}<br>${esc(row.displayYear || '')} / ${esc(row.issue || '')}</td><td>${row.status === 'settled' ? (row.hit ? '&#21629;&#20013;' : '&#26410;&#20013;') : '&#24453;&#24320;&#22870;'}</td></tr>`).join('')}</tbody></table>
        ${recommendationHistoryHtml(rows)}
      </section>`;
    }
    function renderGames() {
      const selected = document.getElementById('game-source')?.value || 'am';
      app.innerHTML = `<div class="grid">
        <section class="panel full"><div class="filters"><label>&#26469;&#28304;<select id="game-source">${sourceOptions(selected)}</select></label></div></section>
        ${gameSection(selected, 'three-hit-three', '&#19977;&#20013;&#19977;&#25512;&#33616;')}
        ${gameSection(selected, 'special-number', '&#29305;&#21035;&#21495;&#25512;&#33616;')}
      </div>`;
      document.getElementById('game-source').addEventListener('change', renderGames);
    }
    function forecastStats(rows) {
      const settled = rows.filter(row => row.status === 'settled').sort((a, b) => String(b.actualDate || '').localeCompare(String(a.actualDate || '')) || Number(b.actualIssue || 0) - Number(a.actualIssue || 0));
      let currentMiss = 0;
      for (const row of settled) {
        if (row.hit) break;
        currentMiss++;
      }
      let maxMiss = 0;
      let run = 0;
      let hits = 0;
      [...settled].reverse().forEach(row => {
        if (row.hit) {
          hits++;
          maxMiss = Math.max(maxMiss, run);
          run = 0;
        } else {
          run++;
        }
      });
      maxMiss = Math.max(maxMiss, run);
      return {currentMiss, maxMiss, hits, settled: settled.length};
    }
    function forecastNumberHtml(row) {
      if (!row) return '<p class="muted">&#26242;&#26080;&#39044;&#27979;</p>';
      if (row.game === 'three-hit-three') {
        return `<div class="history-list">${asArray(row.numbers).map(group => `<div>${numberChips(group)}</div>`).join('')}</div>`;
      }
      return numberChips(row.numbers);
    }
    function forecastCopyText(row) {
      if (!row) return '';
      if (row.game === 'three-hit-three') {
        return asArray(row.numbers).map(group => `\uFF08${normalizeNumberGroup(group).map(n => String(Number(n)).padStart(2, '0')).join('-')}\uFF09`).join(',');
      }
      return asArray(row.numbers).map(n => String(Number(n))).join(',');
    }
    function forecastBacktestHtml(row) {
      if (!row || !row.backtest) return '<p class="muted">&#26242;&#26080;&#22238;&#27979;</p>';
      const bt = row.backtest || {};
      const rb = row.randomBaseline || {};
      return `<div class="grid">
        <section class="panel"><h2>&#31574;&#30053;&#22238;&#27979;</h2><p>&#27979;&#35797;&#65306;${esc(bt.tested || 0)}&#65292;&#21629;&#20013;&#65306;${esc(bt.hits || 0)}</p><p>&#21629;&#20013;&#29575;&#65306;${esc(bt.hitRate || 0)}%</p><p>&#24403;&#21069;&#36951;&#33853;&#65306;${esc(bt.currentMiss || 0)}&#65292;&#26368;&#22823;&#36951;&#33853;&#65306;${esc(bt.maxMiss || 0)}</p></section>
        <section class="panel"><h2>&#22238;&#27979;&#30408;&#20111;</h2><p>&#36180;&#29575;&#65306;${esc(bt.odds || row.odds || 0)}&#20493;&#65292;&#25237;&#20837;&#65306;${esc(bt.totalStake || 0)}</p><p>&#36820;&#22870;&#65306;${esc(bt.totalPayout || 0)}&#65292;&#20928;&#30408;&#20111;&#65306;${esc(bt.netProfit || 0)}</p><p>ROI&#65306;${esc(bt.roi || 0)}%</p></section>
        <section class="panel"><h2>&#38543;&#26426;&#22522;&#20934;</h2><p>&#27979;&#35797;&#65306;${esc(rb.tested || 0)}&#65292;&#21629;&#20013;&#65306;${esc(rb.hits || 0)}</p><p>&#21629;&#20013;&#29575;&#65306;${esc(rb.hitRate || 0)}%&#65292;ROI&#65306;${esc(rb.roi || 0)}%</p><p>&#21629;&#20013;&#29575;&#24046;&#65306;${esc(bt.edgeVsRandom || 0)}%&#65292;ROI&#24046;&#65306;${esc(bt.roiVsRandom || 0)}%</p></section>
        <section class="panel"><h2>&#30408;&#21033;&#38376;&#27099;</h2><p>&#29366;&#24577;&#65306;${esc(row.recommendationStatus || '')}</p><p>&#33258;&#28982;&#21608;&#65306;${esc(row.weekBacktest?.weekStart || '')} - ${esc(row.weekBacktest?.weekEnd || '')}</p><p>&#33258;&#28982;&#21608;&#20928;&#30408;&#20111;&#65306;${esc(row.weekBacktest?.netProfit ?? 0)}&#65292;ROI&#65306;${esc(row.weekBacktest?.roi ?? 0)}%</p><p>&#28378;&#21160;&#22238;&#27979;&#20928;&#30408;&#20111;&#65306;${esc(row.walkForwardBacktest?.netProfit ?? 0)}&#65292;ROI&#65306;${esc(row.walkForwardBacktest?.roi ?? 0)}%</p><p>&#35780;&#20998;&#65306;${esc(row.qualityScore ?? 0)} / ${esc(row.qualityLevel || '')}</p></section>
      </div>`;
    }
    function forecastStrategyPoolHtml(row) {
      const pool = asArray(row?.strategyPool);
      if (pool.length === 0) return '<p class="muted">&#26242;&#26080;&#31574;&#30053;&#27744;</p>';
      return `<h3>&#31574;&#30053;&#27744;&#22238;&#27979;</h3>
        <table class="compact-table"><thead><tr><th>&#31574;&#30053;</th><th>&#35780;&#20998;</th><th>&#27979;&#35797;</th><th>&#21629;&#20013;</th><th>&#21629;&#20013;&#29575;</th><th>ROI</th><th>&#20928;&#30408;&#20111;</th><th>&#26368;&#22823;&#36951;&#33853;</th></tr></thead><tbody>${pool.map(item => `<tr><td>${esc(item.name || item.id)}</td><td>${esc(item.score || 0)}</td><td>${esc(item.tested || 0)}</td><td>${esc(item.hits || 0)}</td><td>${esc(item.hitRate || 0)}%</td><td>${esc(item.roi || 0)}%</td><td>${esc(item.netProfit || 0)}</td><td>${esc(item.maxMiss || 0)}</td></tr>`).join('')}</tbody></table>`;
    }
    function forecastSection(source, game, title) {
      const rows = forecastRows(source, game).sort((a, b) => String(b.createdAt || '').localeCompare(String(a.createdAt || '')) || Number(b.issue || 0) - Number(a.issue || 0));
      const latest = rows.find(row => row.status === 'pending') || rows[0];
      const stats = forecastStats(rows);
      const copyText = forecastCopyText(latest);
      const qrUrl = `https://api.qrserver.com/v1/create-qr-code/?size=160x160&data=${encodeURIComponent(copyText)}`;
      return `<section class="panel full">
        <h2>${title}</h2>
        <div class="grid">
          <section class="panel wide"><h2>&#26412;&#26399;&#35266;&#23519;</h2>${latest ? `<p>${esc(latest.targetDate || '')} ${esc(latest.displayYear || '')} / ${esc(latest.issue || '')}</p>${forecastNumberHtml(latest)}` : '<p class="muted">&#26242;&#26080;&#39044;&#27979;</p>'}</section>
          <section class="panel"><h2>&#35266;&#23519;&#25112;&#32489;</h2><p>&#24403;&#21069;&#36951;&#33853;&#65306;${stats.currentMiss}</p><p>&#21382;&#21490;&#26368;&#22823;&#36951;&#33853;&#65306;${stats.maxMiss}</p><p>&#24050;&#32467;&#31639;&#65306;${stats.settled}&#65292;&#21629;&#20013;&#65306;${stats.hits}</p></section>
        </div>
        <div class="copy-qr"><div><strong>&#24494;&#20449;&#25195;&#30721;&#22797;&#21046;</strong><code>${esc(copyText)}</code></div><img alt="QR" src="${qrUrl}"></div>
        ${forecastBacktestHtml(latest)}
        ${forecastStrategyPoolHtml(latest)}
        <h3>&#35266;&#23519;&#35760;&#24405;</h3>
        <table class="compact-table"><thead><tr><th class="col-time">&#26102;&#38388;</th><th class="col-issue">&#26399;&#21495;</th><th>&#39044;&#27979;</th><th class="col-result">&#32467;&#26524;</th><th class="col-draw">&#24320;&#22870;</th></tr></thead><tbody>${rows.slice(0, 30).map(row => `<tr><td>${esc(row.createdAt)}</td><td>${esc(row.actualDate || row.targetDate || '')}<br>${esc(row.displayYear || '')} / ${esc(row.actualIssue || row.issue || '')}</td><td>${forecastNumberHtml(row)}</td><td>${row.status === 'settled' ? (row.hit ? '&#21629;&#20013;' : '&#26410;&#20013;') : '&#24453;&#24320;&#22870;'}</td><td>${row.actualNumbers ? numberChips(row.actualNumbers) : '-'}</td></tr>`).join('')}</tbody></table>
      </section>`;
    }
    function renderForecast() {
      const selected = document.getElementById('forecast-source')?.value || 'am';
      app.innerHTML = `<div class="grid">
        <section class="panel full"><div class="filters"><label>&#26469;&#28304;<select id="forecast-source">${sourceOptions(selected)}</select></label></div></section>
        ${forecastSection(selected, 'three-hit-three', '&#19977;&#20013;&#19977;&#39044;&#27979;&#35266;&#23519;')}
        ${forecastSection(selected, 'special-number', '&#29305;&#21035;&#21495;&#39044;&#27979;&#35266;&#23519;')}
      </div>`;
      document.getElementById('forecast-source').addEventListener('change', renderForecast);
    }
    function renderWindow5() {
      const selected = document.getElementById('window5-source')?.value || 'am';
      const analysis = fiveWindowAnalysis(selected);
      const win = analysis.currentWindow;
      const missRows = analysis.yearly.map(row => `<tr><td>${esc(row.year)}</td><td>${esc(row.covered)} / ${esc(row.total)}</td><td>${esc(row.total - row.covered)}</td><td>${row.misses.slice(0, 12).map(item => `${String(item.start).padStart(3, '0')}-${String(item.end).padStart(3, '0')}`).join(', ') || '-'}</td></tr>`).join('');
      const hitText = win.hits.length ? win.hits.map(item => `${esc(item.issue)}&#26399; ${esc(item.num)}`).join(' / ') : '&#35266;&#23519;&#20013;';
      app.innerHTML = `<div class="grid">
        <section class="panel full"><div class="filters"><label>&#26469;&#28304;<select id="window5-source">${sourceOptions(selected)}</select></label></div></section>
        <section class="panel wide"><h2>5&#26399;&#31383;&#21475;&#35266;&#23519;</h2><p>${esc(analysis.currentYear)}&#24180; ${String(win.start).padStart(3, '0')}-${String(win.end).padStart(3, '0')}&#31383;&#21475;</p><p>&#24050;&#24320;&#65306;${esc(win.count)}&#26399;&#65292;&#21097;&#20313;&#65306;${esc(Math.max(0, 5 - win.count))}&#26399;</p><p>&#29366;&#24577;&#65306;${win.covered ? '&#24050;&#35206;&#30422;' : '&#35266;&#23519;&#20013;'}</p><p>&#21629;&#20013;&#65306;${hitText}</p></section>
        <section class="panel"><h2>&#24403;&#24180;&#35206;&#30422;&#27744;</h2>${numberChips(analysis.yearPool)}<p>${analysis.adjustmentStatus}</p><p class="muted">${analysis.adjustmentReason}</p><p class="muted">&#21464;&#26356;&#26102;&#38388;&#65306;${esc(analysis.changeTime || '-')}</p></section>
        <section class="panel"><h2>&#36328;&#24180;&#31283;&#23450;&#27744;</h2>${numberChips(analysis.stablePool)}<p>${analysis.stablePoolStatus}</p><p class="muted">${analysis.stablePoolReason}</p><p class="muted">&#21464;&#26356;&#26102;&#38388;&#65306;${esc(analysis.stablePoolChangeTime || '-')}</p><p class="muted">&#19979;&#27425;&#37325;&#31639;&#26399;&#21495;&#65306;${esc(analysis.stablePoolNextRecalcIssue || '-')}</p></section>
        <section class="panel full"><h2>&#24403;&#24180;&#31383;&#21475;&#26126;&#32454;</h2><table class="compact-table"><thead><tr><th>&#31383;&#21475;</th><th>&#24050;&#24320;</th><th>&#29366;&#24577;</th><th>&#21629;&#20013;</th></tr></thead><tbody>${analysis.yearWindows.map(item => `<tr><td>${String(item.start).padStart(3, '0')}-${String(item.end).padStart(3, '0')}</td><td>${esc(item.count)}</td><td>${item.covered ? '&#24050;&#35206;&#30422;' : '&#35266;&#23519;&#20013;'}</td><td>${item.hits.map(hit => `${esc(hit.issue)}:${esc(hit.num)}`).join(', ') || '-'}</td></tr>`).join('')}</tbody></table></section>
        <section class="panel full"><h2>&#24180;&#24230;&#22238;&#27979;</h2><table class="compact-table"><thead><tr><th>&#24180;&#20221;</th><th>&#35206;&#30422;&#31383;&#21475;</th><th>&#28431;&#31383;&#21475;</th><th>&#28431;&#31383;&#21475;&#21015;&#34920;</th></tr></thead><tbody>${missRows}</tbody></table></section>
      </div>`;
      document.getElementById('window5-source').addEventListener('change', renderWindow5);
    }
    function renderThreeWindow5() {
      const selected = document.getElementById('three-window5-source')?.value || 'am';
      const analysis = threeWindowAnalysis(selected);
      const win = analysis.currentWindow;
      const copyText = analysis.combos.map(item => `\uFF08${item.numbers.join('-')}\uFF09`).join(',');
      const qrUrl = `https://api.qrserver.com/v1/create-qr-code/?size=160x160&data=${encodeURIComponent(copyText)}`;
      const hitText = win.hits.length ? win.hits.map(item => `${esc(item.issue)}&#26399; ${esc(item.combo.join('-'))}`).join(' / ') : '&#35266;&#23519;&#20013;';
      app.innerHTML = `<div class="grid">
        <section class="panel full"><div class="filters"><label>&#26469;&#28304;<select id="three-window5-source">${sourceOptions(selected)}</select></label></div></section>
        <section class="panel wide"><h2>&#19977;&#20013;&#19977;5&#26399;&#31383;&#21475;</h2><p>${esc(analysis.currentYear)}&#24180; ${String(win.start).padStart(3, '0')}-${String(win.end).padStart(3, '0')}&#31383;&#21475;</p><p>&#24050;&#24320;&#65306;${esc(win.count)}&#26399;&#65292;&#21097;&#20313;&#65306;${esc(Math.max(0, 5 - win.count))}&#26399;</p><p>&#29366;&#24577;&#65306;${win.covered ? '&#24050;&#21629;&#20013;' : '&#35266;&#23519;&#20013;'}</p><p>&#21629;&#20013;&#65306;${hitText}</p></section>
        <section class="panel"><h2>&#31383;&#21475;&#25112;&#32489;</h2><p>&#24403;&#21069;&#28431;&#31383;&#65306;${esc(analysis.stats.currentMiss)}</p><p>&#21382;&#21490;&#26368;&#22823;&#28431;&#31383;&#65306;${esc(analysis.stats.maxMiss)}</p><p>&#32479;&#35745;&#31383;&#21475;&#65306;${esc(analysis.stats.total)}&#65292;&#21629;&#20013;&#65306;${esc(analysis.stats.hits)}</p><p>&#31383;&#21475;&#21629;&#20013;&#29575;&#65306;${esc(analysis.stats.hitRate)}%</p></section>
        <section class="panel"><h2>&#24403;&#24180;&#21495;&#30721;&#27744;</h2>${numberChips(analysis.numberPool)}<p class="muted">&#22522;&#20110;&#24403;&#24180;&#21069;6&#20010;&#24179;&#30721;&#39057;&#27425;&#29983;&#25104;</p></section>
        <section class="panel full"><h2>&#24403;&#21069;&#25512;&#33616;&#32452;&#21512;</h2><div class="copy-qr"><div><strong>&#24494;&#20449;&#25195;&#30721;&#22797;&#21046;</strong><code>${esc(copyText)}</code></div><img alt="QR" src="${qrUrl}"></div><table class="compact-table"><thead><tr><th>&#32452;&#21512;</th><th>&#21382;&#21490;&#21629;&#20013;</th><th>&#21629;&#20013;&#31383;&#21475;</th><th>&#26368;&#36817;&#21629;&#20013;&#26399;</th></tr></thead><tbody>${analysis.combos.map(item => `<tr><td>${numberChips(item.numbers)}</td><td>${esc(item.hits)}</td><td>${esc(item.windowHits)}</td><td>${esc(item.lastIssue)}</td></tr>`).join('')}</tbody></table></section>
        <section class="panel full"><h2>&#24403;&#24180;&#31383;&#21475;&#26126;&#32454;</h2><table class="compact-table"><thead><tr><th>&#31383;&#21475;</th><th>&#24050;&#24320;</th><th>&#29366;&#24577;</th><th>&#21629;&#20013;&#32452;&#21512;</th></tr></thead><tbody>${analysis.yearWindows.map(item => `<tr><td>${String(item.start).padStart(3, '0')}-${String(item.end).padStart(3, '0')}</td><td>${esc(item.count)}</td><td>${item.covered ? '&#24050;&#21629;&#20013;' : '&#35266;&#23519;&#20013;'}</td><td>${item.hits.slice(0, 8).map(hit => `${esc(hit.issue)}:${esc(hit.combo.join('-'))}`).join(', ') || '-'}</td></tr>`).join('')}</tbody></table></section>
      </div>`;
      document.getElementById('three-window5-source').addEventListener('change', renderThreeWindow5);
    }
    function patternMetricRow(name, item, sizeLabel) {
      return `<tr><td>${esc(name)}</td><td>${esc(sizeLabel)}</td><td>${esc(item.hitRate)}%</td><td>${esc(item.baseline)}%</td><td>${esc(item.edge)}%</td><td>${esc(item.currentMiss)}</td><td>${esc(item.maxMiss)}</td><td>${esc(item.recentHitRate)}%</td><td>${item.level}</td></tr>`;
    }
    function simpleRankList(items) {
      return `<table class="compact-table"><thead><tr><th>&#32467;&#26500;</th><th>&#27425;&#25968;</th></tr></thead><tbody>${items.map(item => `<tr><td>${esc(item.name)}</td><td>${esc(item.count)}</td></tr>`).join('')}</tbody></table>`;
    }
    function comboListHtml(combos) {
      return `<div class="history-list">${combos.map(item => `<div>${numberChips(item.numbers)}</div>`).join('')}</div>`;
    }
    function renderPatternWatch() {
      const selected = document.getElementById('pattern-source')?.value || 'am';
      const analysis = patternWatchAnalysis(selected);
      app.innerHTML = `<div class="grid">
        <section class="panel full"><div class="filters"><label>&#26469;&#28304;<select id="pattern-source">${sourceOptions(selected)}</select></label></div></section>
        <section class="panel full"><h2>&#35268;&#24459;&#35266;&#23519;</h2><p class="muted">${esc(analysis.currentYear)}&#24180;&#65292;&#23545;&#27604;&#23454;&#38469;5&#26399;&#31383;&#21475;&#21629;&#20013;&#29575;&#19982;&#38543;&#26426;&#22522;&#20934;&#12290;</p><table class="compact-table"><thead><tr><th>&#35266;&#23519;&#39033;</th><th>&#35268;&#27169;</th><th>&#23454;&#38469;</th><th>&#38543;&#26426;&#22522;&#20934;</th><th>&#36229;&#39069;</th><th>&#24403;&#21069;&#28431;&#31383;</th><th>&#26368;&#22823;&#28431;&#31383;</th><th>&#36817;10&#31383;&#21475;</th><th>&#31561;&#32423;</th></tr></thead><tbody>
          ${patternMetricRow('\u7279\u522B\u53F7\u5F53\u5E748\u7801\u6C60', analysis.special, `${analysis.special.poolSize}\u7801`)}
          ${patternMetricRow('\u7279\u522B\u53F7\u8DE8\u5E74\u7A33\u5B9A\u6C60', analysis.stable, `${analysis.stable.poolSize}\u7801`)}
          ${patternMetricRow('\u4E09\u4E2D\u4E09\u7EC4\u5408\u6C60', analysis.three, `${analysis.three.comboSize}\u7EC4`)}
        </tbody></table></section>
        <section class="panel full"><h2>&#35268;&#24459;&#20248;&#21270;&#27744;</h2><p class="muted">&#21407;&#27744;&#19981;&#21160;&#65292;&#27492;&#22788;&#20165;&#29992;&#20110;&#35266;&#23519;&#35268;&#24459;&#32467;&#26500;&#20248;&#21270;&#21518;&#30340;&#22238;&#27979;&#34920;&#29616;&#12290;</p><div class="grid">
          <section class="panel"><h2>&#29305;&#21035;&#21495;&#24403;&#24180;8&#30721;&#20248;&#21270;</h2>${numberChips(analysis.optimized.special.pool)}<p class="muted">&#20445;&#30041;&#21407;&#27744;&#26680;&#24515;&#65292;&#25353;&#24403;&#24180;&#39057;&#27425;&#12289;&#39068;&#33394;&#12289;&#23614;&#25968;&#20998;&#25955;&#20248;&#21270;&#12290;</p></section>
          <section class="panel"><h2>&#29305;&#21035;&#21495;&#36328;&#24180;&#31283;&#23450;&#20248;&#21270;</h2>${numberChips(analysis.optimized.stable.pool)}<p class="muted">&#20445;&#30041;&#36328;&#24180;&#31283;&#23450;&#27744;&#26435;&#37325;&#65292;&#25353;&#24403;&#24180;&#32467;&#26500;&#20570;&#36731;&#37327;&#35843;&#25972;&#12290;</p></section>
          <section class="panel wide"><h2>&#19977;&#20013;&#19977;12&#32452;&#20248;&#21270;</h2>${comboListHtml(analysis.optimized.three.combos)}<p class="muted">&#25353;&#21382;&#21490;&#31383;&#21475;&#21629;&#20013;&#12289;&#36328;&#24230;&#12289;&#22855;&#20598;&#21644;&#37325;&#22797;&#21495;&#25511;&#21046;&#20248;&#21270;&#12290;</p></section>
        </div></section>
        <section class="panel full"><h2>&#20248;&#21270;&#34920;&#29616;&#23545;&#27604;</h2><table class="compact-table"><thead><tr><th>&#35266;&#23519;&#39033;</th><th>&#21407;&#22987;&#23454;&#38469;</th><th>&#20248;&#21270;&#23454;&#38469;</th><th>&#38543;&#26426;&#22522;&#20934;</th><th>&#21407;&#22987;&#36229;&#39069;</th><th>&#20248;&#21270;&#36229;&#39069;</th><th>&#21464;&#21270;</th><th>&#32467;&#35770;</th></tr></thead><tbody>
          ${optimizationCompareRow('\u7279\u522B\u53F7\u5F53\u5E748\u7801\u6C60', analysis.special, analysis.optimized.special.stats, analysis.special.baseline)}
          ${optimizationCompareRow('\u7279\u522B\u53F7\u8DE8\u5E74\u7A33\u5B9A\u6C60', analysis.stable, analysis.optimized.stable.stats, analysis.stable.baseline)}
          ${optimizationCompareRow('\u4E09\u4E2D\u4E09\u7EC4\u5408\u6C60', analysis.three, analysis.optimized.three.stats, analysis.three.baseline)}
        </tbody></table></section>
        <section class="panel wide"><h2>&#29305;&#21035;&#21495;&#39068;&#33394;&#32467;&#26500;</h2>${simpleRankList(analysis.special.structure.colors)}</section>
        <section class="panel wide"><h2>&#29305;&#21035;&#21495;&#23614;&#25968;&#32467;&#26500;</h2>${simpleRankList(analysis.special.structure.tails.slice(0, 10))}</section>
        <section class="panel wide"><h2>&#19977;&#20013;&#19977;&#36328;&#24230;&#32467;&#26500;</h2>${simpleRankList(analysis.three.structure.spans)}</section>
        <section class="panel wide"><h2>&#19977;&#20013;&#19977;&#22855;&#20598;&#32467;&#26500;</h2>${simpleRankList(analysis.three.structure.parity)}</section>
      </div>`;
      document.getElementById('pattern-source').addEventListener('change', renderPatternWatch);
    }
    function patternRiskStats(windows) {
      const completed = windows.filter(item => Number(item.count || 0) >= 5);
      const total = completed.length;
      const hits = completed.filter(item => item.covered).length;
      let currentMiss = 0;
      for (let i = completed.length - 1; i >= 0; i--) {
        if (completed[i].covered) break;
        currentMiss++;
      }
      const previousWindows = completed.slice(0, Math.max(0, completed.length - currentMiss));
      let previousMaxMiss = 0;
      let run = 0;
      previousWindows.forEach(item => {
        if (item.covered) {
          previousMaxMiss = Math.max(previousMaxMiss, run);
          run = 0;
        } else {
          run++;
        }
      });
      previousMaxMiss = Math.max(previousMaxMiss, run);
      const recent = completed.slice(-10);
      const recentHits = recent.filter(item => item.covered).length;
      return {total, hits, hitRate: total ? Math.round(hits / total * 10000) / 100 : 0, currentMiss, previousMaxMiss, recentHitRate: recent.length ? Math.round(recentHits / recent.length * 10000) / 100 : 0};
    }
    function qualityLevel(item) {
      if (item.total < 10) return {text: '\u6837\u672C\u4E0D\u8DB3', tone: 'info'};
      if (item.edge >= 15 && item.recentHitRate >= item.baseline) return {text: '\u4F18\u79C0', tone: 'good'};
      if (item.edge >= 8) return {text: '\u826F\u597D', tone: 'good'};
      if (item.edge >= 0) return {text: '\u89C2\u5BDF', tone: 'info'};
      return {text: '\u5F31\u4E8E\u968F\u673A', tone: 'bad'};
    }
    function riskStatus(item) {
      if (item.currentMiss === 0) return {text: '\u672C\u7A97\u5DF2\u8986\u76D6', tone: 'good'};
      if (item.previousMaxMiss > 0 && item.currentMiss > item.previousMaxMiss) return {text: '\u7A81\u7834\u5386\u53F2\u6F0F\u7A97', tone: 'bad'};
      const base = Math.max(1, item.previousMaxMiss);
      const pressure = item.currentMiss / base;
      if (pressure >= 0.85) return {text: '\u63A5\u8FD1\u5386\u53F2\u6F0F\u7A97', tone: 'warn'};
      if (pressure >= 0.6) return {text: '\u538B\u529B\u5347\u9AD8', tone: 'warn'};
      return {text: '\u6B63\u5E38\u56DE\u64A4', tone: 'info'};
    }
    function statusBadge(item) {
      return `<span class="badge ${esc(item.tone)}">${esc(item.text)}</span>`;
    }
    function patternAnalysisRows(source) {
      const special = fiveWindowAnalysis(source);
      const three = threeWindowAnalysis(source);
      const yearRows = cachedSourceRecords(source).filter(row => displayYear(row) === special.currentYear);
      const decorate = (name, sizeLabel, stats, baseline) => ({name, sizeLabel, ...stats, baseline, edge: Math.round((stats.hitRate - baseline) * 100) / 100});
      return {
        currentYear: special.currentYear,
        rows: [
          decorate('\u7279\u522B\u53F7\u5F53\u5E748\u7801\u6C60', `${special.yearPool.length}\u7801`, patternRiskStats(special.yearWindows), randomWindowBaseline(special.yearPool.length, 49, 5)),
          decorate('\u7279\u522B\u53F7\u8DE8\u5E74\u7A33\u5B9A\u6C60', `${special.stablePool.length}\u7801`, patternRiskStats(special.stableWindows), randomWindowBaseline(special.stablePool.length, 49, 5)),
          decorate('\u4E09\u4E2D\u4E09\u7EC4\u5408\u6C60', `${three.combos.length}\u7EC4`, patternRiskStats(three.yearWindows), randomWindowBaseline(three.combos.length * 20, 18424, 5))
        ],
        special: {structure: specialStructureStats(yearRows)},
        three: {structure: threeComboStructureStats(three.combos)}
      };
    }
    function patternAnalysisMetricRow(item) {
      return `<tr><td>${esc(item.name)}</td><td>${esc(item.sizeLabel)}</td><td>${esc(item.total)}</td><td>${esc(item.hitRate)}%</td><td>${esc(item.baseline)}%</td><td>${esc(item.edge)}%</td><td>${esc(item.recentHitRate)}%</td><td>${statusBadge(qualityLevel(item))}</td><td>${esc(item.currentMiss)}</td><td>${esc(item.previousMaxMiss)}</td><td>${statusBadge(riskStatus(item))}</td></tr>`;
    }
    function renderPatternAnalysis() {
      const selected = document.getElementById('pattern-analysis-source')?.value || 'am';
      const analysis = patternAnalysisRows(selected);
      app.innerHTML = `<div class="grid">
        <section class="panel full"><div class="filters"><label>&#26469;&#28304;<select id="pattern-analysis-source">${sourceOptions(selected)}</select></label></div></section>
        <section class="panel wide"><h2>&#38271;&#26399;&#36136;&#37327;</h2><p class="muted">&#21482;&#30475;&#38271;&#26399;&#21629;&#20013;&#29575;&#30456;&#23545;&#38543;&#26426;&#22522;&#20934;&#30340;&#36229;&#39069;&#65292;&#19981;&#25226;&#24403;&#21069;&#28431;&#31383;&#30452;&#25509;&#24403;&#25104;&#35268;&#24459;&#22833;&#25928;&#12290;</p></section>
        <section class="panel wide"><h2>&#24403;&#21069;&#29366;&#24577;</h2><p class="muted">&#21333;&#29420;&#27604;&#36739;&#24403;&#21069;&#36830;&#32493;&#28431;&#31383;&#19982;&#21382;&#21490;&#26368;&#22823;&#24050;&#32467;&#26463;&#28431;&#31383;&#65292;&#29992;&#20110;&#25552;&#31034;&#22238;&#25764;&#21387;&#21147;&#12290;</p></section>
        <section class="panel full"><h2>${esc(analysis.currentYear)}&#24180;&#35268;&#24459;&#20998;&#26512;</h2><table class="compact-table"><thead><tr><th>&#35266;&#23519;&#39033;</th><th>&#35268;&#27169;</th><th>&#26679;&#26412;&#31383;&#21475;</th><th>&#23454;&#38469;</th><th>&#38543;&#26426;&#22522;&#20934;</th><th>&#36229;&#39069;</th><th>&#36817;10&#31383;&#21475;</th><th>&#38271;&#26399;&#36136;&#37327;</th><th>&#24403;&#21069;&#28431;&#31383;</th><th>&#21382;&#21490;&#26368;&#22823;&#28431;&#31383;</th><th>&#24403;&#21069;&#29366;&#24577;</th></tr></thead><tbody>${analysis.rows.map(patternAnalysisMetricRow).join('')}</tbody></table></section>
        <section class="panel wide"><h2>&#29305;&#21035;&#21495;&#39068;&#33394;&#32467;&#26500;</h2>${simpleRankList(analysis.special.structure.colors)}</section>
        <section class="panel wide"><h2>&#29305;&#21035;&#21495;&#23614;&#25968;&#32467;&#26500;</h2>${simpleRankList(analysis.special.structure.tails.slice(0, 10))}</section>
        <section class="panel wide"><h2>&#19977;&#20013;&#19977;&#36328;&#24230;&#32467;&#26500;</h2>${simpleRankList(analysis.three.structure.spans)}</section>
        <section class="panel wide"><h2>&#19977;&#20013;&#19977;&#22855;&#20598;&#32467;&#26500;</h2>${simpleRankList(analysis.three.structure.parity)}</section>
      </div>`;
      document.getElementById('pattern-analysis-source').addEventListener('change', renderPatternAnalysis);
    }
    function renderDaily() {
      const selected = document.getElementById('daily-source')?.value || 'am';
      const selectedSummary = sourceSummary(selected);
      const coldFor = (source) => {
        const list = sourceRecords(source);
        return Array.from({length: 49}, (_, idx) => String(idx + 1).padStart(2, '0')).map(num => {
          const pos = list.findIndex(r => r.balls.some(b => b.numberText === num));
          return {name: num, count: pos < 0 ? list.length : pos};
        }).sort((a, b) => b.count - a.count).slice(0, 8);
      };
      app.innerHTML = `<div class="grid">
        <section class="panel full"><div class="filters"><label>&#26469;&#28304;<select id="daily-source">${sourceOptions(selected)}</select></label></div></section>
        <section class="panel wide"><h2>&#20170;&#26085;&#26368;&#26032;</h2>${selectedSummary.latest ? `<p>${esc(selectedSummary.latest.sourceName)} ${esc(displayYear(selectedSummary.latest))}&#24180; ${esc(selectedSummary.latest.issue)}&#26399; ${esc(selectedSummary.latest.date)}</p>${ballsHtml(selectedSummary.latest.balls)}` : ''}</section>
        <section class="panel wide"><h2>&#25968;&#25454;&#29366;&#24577;</h2><div class="metric">${selectedSummary.totalRecords}</div><p class="muted">&#29983;&#25104;&#26102;&#38388;&#65306;${esc(summary.generatedAt)}</p><p><a href="report.html">&#25171;&#24320;&#29420;&#31435;&#26085;&#25253;</a></p></section>
        <section class="panel wide"><h2>&#28909;&#38376;&#21495;&#30721;</h2>${rankHtml((selectedSummary.numbers || []).slice(0, 8), 8)}</section>
        <section class="panel wide"><h2>&#36951;&#28431;&#21495;&#30721;</h2>${rankHtml(coldFor(selected), 8)}</section>
      </div>`;
      document.getElementById('daily-source').addEventListener('change', renderDaily);
    }
    const renderers = {
      overview: renderOverview,
      games: renderGames,
      forecast: renderForecast,
      window5: renderWindow5,
      threeWindow5: renderThreeWindow5,
      patternWatch: renderPatternWatch,
      patternAnalysis: renderPatternAnalysis,
      daily: renderDaily
    };
    tabs.forEach(btn => btn.addEventListener('click', () => { tabs.forEach(item => item.classList.remove('active')); btn.classList.add('active'); renderers[btn.dataset.tab](); }));
    async function initDashboard() {
      try {
        const embedded = JSON.parse(document.getElementById('embedded-records').textContent);
        applyPayload(embedded);
        await loadOnlineDataIfHosted();
        document.getElementById('manual-collect').addEventListener('click', manualCollect);
        renderOverview();
      } catch (err) {
        app.innerHTML = `<section class="panel"><h2>&#25968;&#25454;&#21152;&#36733;&#22833;&#36133;</h2><p>${esc(err.message)}</p></section>`;
      }
    }
    initDashboard();
  </script>
</body>
</html>
'@
    return $html.Replace('__EMBEDDED_JSON__', $safeJson)
}

function New-ReportHtml {
    param([object]$Summary)

    $amJson = ($Summary.bySource.am | ConvertTo-Json -Depth 8 -Compress)
    $hkJson = ($Summary.bySource.hk | ConvertTo-Json -Depth 8 -Compress)
    $html = @'
<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>&#24320;&#22870;&#26085;&#25253;</title>
  <style>
    body { margin: 0; font-family: "Microsoft YaHei", Arial, sans-serif; background: #f4f5f7; color: #1f2933; }
    main { max-width: 920px; margin: 0 auto; padding: 18px; }
    .panel { background:#fff; border:1px solid #d9dee7; border-radius:8px; padding:16px; margin-bottom:12px; }
    .balls { display:flex; gap:6px; flex-wrap:wrap; }
    .ball { min-width:34px; padding:4px 6px; color:#fff; border-radius:4px; text-align:center; font-weight:700; }
    .red { background:#ef1010; } .green { background:#07860a; } .blue { background:#0617f2; }
    a { color:#0b42d8; }
  </style>
</head>
<body>
  <main>
    <h1>&#24320;&#22870;&#26085;&#25253;</h1>
    <section class="panel"><p>&#29983;&#25104;&#26102;&#38388;&#65306;__GENERATED_AT__</p><p>&#35760;&#24405;&#24635;&#25968;&#65306;__TOTAL_RECORDS__&#65292;&#21495;&#30721;&#26679;&#26412;&#65306;__TOTAL_BALLS__</p><p><a href="dashboard.html">&#36820;&#22238;&#25968;&#25454;&#30475;&#26495;</a></p></section>
    <section class="panel"><h2>&#28595;&#38376;&#26085;&#25253;</h2><div id="am"></div></section>
    <section class="panel"><h2>&#39321;&#28207;&#26085;&#25253;</h2><div id="hk"></div></section>
  </main>
  <script>
    const am = __AM_JSON__;
    const hk = __HK_JSON__;
    const esc = (value) => String(value ?? '').replace(/[&<>"']/g, (ch) => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[ch]));
    function displayYear(record) { const dateText = String(record?.date || ''); return dateText.length >= 4 ? dateText.slice(0, 4) : String(record?.year || ''); }
    function ballsHtml(balls) { return '<div class="balls">' + balls.map(ball => `<span class="ball ${esc(ball.color)}">${esc(ball.numberText)}<br>${esc(ball.zodiac)}</span>`).join('') + '</div>'; }
    function section(data) {
      const latest = data.latest;
      return `${latest ? `<p>${esc(displayYear(latest))}&#24180; ${esc(latest.issue)}&#26399; ${esc(latest.date)}</p>${ballsHtml(latest.balls)}` : ''}
      <h3>&#28909;&#38376;&#21495;&#30721;</h3><ol>${(data.numbers || []).slice(0, 10).map(item => `<li>${esc(item.name)} - ${item.count}</li>`).join('')}</ol>`;
    }
    document.getElementById('am').innerHTML = section(am);
    document.getElementById('hk').innerHTML = section(hk);
  </script>
</body>
</html>
'@
    return $html.Replace('__AM_JSON__', $amJson).Replace('__HK_JSON__', $hkJson).Replace('__GENERATED_AT__', [string]$Summary.generatedAt).Replace('__TOTAL_RECORDS__', [string]$Summary.totalRecords).Replace('__TOTAL_BALLS__', [string]$Summary.totalBalls)
}

$pagesDir = Join-Path $RootDir 'pages'
if (-not (Test-Path -LiteralPath $pagesDir)) { throw "Pages directory not found: $pagesDir" }

$records = New-Object 'System.Collections.Generic.List[object]'
foreach ($file in (Get-ChildItem -LiteralPath $pagesDir -Filter '*.html' -File)) {
    $html = [IO.File]::ReadAllText($file.FullName, [Text.Encoding]::UTF8)
    $source = Get-SourceKind $file.Name
    $year = Get-YearFromFile -FileName $file.Name -Html $html
    foreach ($record in (Parse-RecordBlocks -Html $html -Source $source -Year $year -FileName $file.Name)) {
        $records.Add($record) | Out-Null
    }
}

$unique = @{}
foreach ($record in $records) { $unique[$record.id] = $record }
$deduped = @($unique.Values | Sort-Object @{ Expression = 'date'; Descending = $true }, @{ Expression = 'source'; Descending = $false }, @{ Expression = 'issue'; Descending = $true })
$summary = Get-Summary $deduped

$dataDir = Join-Path $RootDir 'data'
if (-not (Test-Path -LiteralPath $dataDir)) { New-Item -ItemType Directory -Path $dataDir -Force | Out-Null }
$predictionsPath = Join-Path $dataDir 'predictions.json'
$existingPredictionPairs = @()
if (Test-Path -LiteralPath $predictionsPath) {
    try {
        $existingPredictions = Get-Content -LiteralPath $predictionsPath -Raw -Encoding UTF8 | ConvertFrom-Json
        foreach ($item in @($existingPredictions.next)) { $existingPredictionPairs += [pscustomobject]@{ type = 'next'; item = $item } }
        foreach ($item in @($existingPredictions.sanzhong)) { $existingPredictionPairs += [pscustomobject]@{ type = 'sanzhong'; item = $item } }
    }
    catch {
        $existingPredictionPairs = @()
    }
}
$predictions = New-GeneratedPredictions -Records $deduped -Existing $existingPredictionPairs
[IO.File]::WriteAllText($predictionsPath, ($predictions | ConvertTo-Json -Depth 10), $Utf8NoBom)
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
$forecastPath = Join-Path $dataDir 'prediction-observations.json'
$existingForecastItems = @()
if (Test-Path -LiteralPath $forecastPath) {
    try {
        $existingForecastData = Get-Content -LiteralPath $forecastPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $existingForecastItems = @($existingForecastData.items)
    }
    catch {
        $existingForecastItems = @()
    }
}
$forecasts = New-ForecastPredictions -Records $deduped -Existing $existingForecastItems
[IO.File]::WriteAllText($forecastPath, ($forecasts | ConvertTo-Json -Depth 12), $Utf8NoBom)
$forecastEvaluationPath = Join-Path $dataDir 'forecast-evaluation.json'
$forecastEvaluation = New-ForecastEvaluation -Forecasts $forecasts
[IO.File]::WriteAllText($forecastEvaluationPath, ($forecastEvaluation | ConvertTo-Json -Depth 12), $Utf8NoBom)
$window5Path = Join-Path $dataDir 'window5-state.json'
$existingWindow5 = $null
if (Test-Path -LiteralPath $window5Path) {
    try { $existingWindow5 = Get-Content -LiteralPath $window5Path -Raw -Encoding UTF8 | ConvertFrom-Json } catch { $existingWindow5 = $null }
}
$window5 = New-Window5State -Records $deduped -Existing $existingWindow5 -GeneratedAt $summary.generatedAt
[IO.File]::WriteAllText($window5Path, ($window5 | ConvertTo-Json -Depth 8), $Utf8NoBom)
$payload = [pscustomobject]@{ summary = $summary; records = $deduped; predictions = $predictions; games = $gamePredictions; forecasts = $forecasts; window5 = $window5 }
$jsonPath = Join-Path $dataDir 'records.json'
$json = $payload | ConvertTo-Json -Depth 10
[IO.File]::WriteAllText($jsonPath, $json, $Utf8NoBom)
$dashboardPath = Join-Path $RootDir 'dashboard.html'
$dashboardHtml = New-DashboardHtml -EmbeddedJson $json
[IO.File]::WriteAllText($dashboardPath, $dashboardHtml, $Utf8NoBom)
$indexPath = Join-Path $RootDir 'index.html'
[IO.File]::WriteAllText($indexPath, $dashboardHtml, $Utf8NoBom)
$reportPath = Join-Path $RootDir 'report.html'
[IO.File]::WriteAllText($reportPath, (New-ReportHtml -Summary $summary), $Utf8NoBom)
Write-Host "Records: $($deduped.Count)"
Write-Host "Saved: $jsonPath"
Write-Host "Saved: $dashboardPath"
Write-Host "Saved: $indexPath"
Write-Host "Saved: $reportPath"
