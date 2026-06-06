$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$scriptPath = Join-Path $root 'build-data.ps1'
$outDir = Join-Path $root 'test-sanzhong-output'
$pagesDir = Join-Path $outDir 'pages'
$utf8NoBom = [Text.UTF8Encoding]::new($false)

$yang = [string][char]0x7F8A
$issueText = [string][char]0x671F
$openText = [string]::Concat(@([char]0x5F00, [char]0x5956, [char]0x65F6, [char]0x65F6, [char]0x95F4)) -replace ([string][char]0x65F6 + [string][char]0x65F6), ([string][char]0x65F6)

if (Test-Path -LiteralPath $outDir) {
    Remove-Item -LiteralPath $outDir -Recurse -Force
}
New-Item -ItemType Directory -Path $pagesDir -Force | Out-Null

function New-RecordHtml {
    param([int]$Issue, [string]$Date, [int[]]$Numbers)

    $balls = for ($i = 0; $i -lt 7; $i++) {
        $n = $Numbers[$i].ToString('00')
        '<div class="ball" data-name="{0}" data-index="{1}"><p><span class="red">{2}</span><b>{0}</b></p></div>' -f $yang, $i, $n
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

$records = @()
for ($i = 1; $i -le 36; $i++) {
    $date = ([datetime]'2026-01-01').AddDays($i - 1).ToString('yyyy-MM-dd')
    if ($i % 4 -eq 0) {
        $nums = @(1, 2, 3, 10, 11, 12, 49)
    }
    elseif ($i % 4 -eq 1) {
        $nums = @(4, 5, 6, 13, 14, 15, 48)
    }
    elseif ($i % 4 -eq 2) {
        $nums = @(7, 8, 9, 16, 17, 18, 47)
    }
    else {
        $nums = @(19, 20, 21, 22, 23, 24, 46)
    }
    $records += New-RecordHtml -Issue $i -Date $date -Numbers $nums
}

[IO.File]::WriteAllText((Join-Path $pagesDir 'am.html'), "<html><body>$($records -join "`n")</body></html>", $utf8NoBom)

try {
    & $scriptPath -RootDir $outDir | Out-Null

    $predictionsPath = Join-Path $outDir 'data/predictions.json'
    if (-not (Test-Path -LiteralPath $predictionsPath)) {
        throw 'predictions.json was not created'
    }

    $predictions = Get-Content -LiteralPath $predictionsPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $am = @($predictions.sanzhong | Where-Object { $_.source -eq 'am' } | Select-Object -First 1)
    if (-not $am) {
        throw 'am sanzhong prediction was not created'
    }
    if ($am.verifiedCandidates -ne 18424) {
        throw "expected 18424 verified candidates, got $($am.verifiedCandidates)"
    }
    if ($am.method -ne 'exhaustive-49c3-portfolio') {
        throw "unexpected sanzhong method: $($am.method)"
    }
    if (-not $am.portfolio -or $null -eq $am.portfolio.coverage120) {
        throw 'portfolio coverage metrics were not saved'
    }
    if (-not $am.backtest -or $null -eq $am.backtest.hitRate) {
        throw 'rolling backtest metrics were not saved'
    }
    if (@($am.combos).Count -ne 10) {
        throw "expected 10 combos, got $(@($am.combos).Count)"
    }

    $dashboard = [IO.File]::ReadAllText((Join-Path $outDir 'index.html'), [Text.Encoding]::UTF8)
    if (-not $dashboard.Contains('data-tab="threeWindow5"')) {
        throw 'dashboard should render the three-hit five-window tab'
    }
    if (-not $dashboard.Contains('function buildThreeHitCombos(records)')) {
        throw 'dashboard should include three-hit combo coverage analysis'
    }

    Write-Host 'PASS'
}
finally {
    if (Test-Path -LiteralPath $outDir) {
        Remove-Item -LiteralPath $outDir -Recurse -Force
    }
}
