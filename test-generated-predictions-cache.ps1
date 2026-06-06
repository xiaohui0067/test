$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$scriptPath = Join-Path $root 'build-data.ps1'
$outDir = Join-Path $root 'test-generated-predictions-cache-output'
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
for ($i = 1; $i -le 20; $i++) {
    $date = ([datetime]'2026-01-01').AddDays($i - 1).ToString('yyyy-MM-dd')
    if ($i % 2 -eq 0) {
        $records += New-RecordHtml -Issue $i -Date $date -Numbers @(1, 2, 3, 10, 11, 12, 49)
    }
    else {
        $records += New-RecordHtml -Issue $i -Date $date -Numbers @(4, 5, 6, 13, 14, 15, 48)
    }
}
[IO.File]::WriteAllText((Join-Path $pagesDir 'am.html'), "<html><body>$($records -join "`n")</body></html>", $utf8NoBom)

try {
    & $scriptPath -RootDir $outDir | Out-Null
    $first = Get-Content -LiteralPath (Join-Path $outDir 'data\predictions.json') -Raw | ConvertFrom-Json
    $firstNext = @($first.next | Where-Object { $_.source -eq 'am' } | Select-Object -First 1)[0]
    $firstSan = @($first.sanzhong | Where-Object { $_.source -eq 'am' } | Select-Object -First 1)[0]

    Start-Sleep -Seconds 1
    & $scriptPath -RootDir $outDir | Out-Null
    $second = Get-Content -LiteralPath (Join-Path $outDir 'data\predictions.json') -Raw | ConvertFrom-Json
    $secondNext = @($second.next | Where-Object { $_.source -eq 'am' -and $_.issue -eq $firstNext.issue -and $_.displayYear -eq $firstNext.displayYear -and $_.targetDate -eq $firstNext.targetDate } | Select-Object -First 1)[0]
    $secondSan = @($second.sanzhong | Where-Object { $_.source -eq 'am' -and $_.issue -eq $firstSan.issue -and $_.displayYear -eq $firstSan.displayYear -and $_.targetDate -eq $firstSan.targetDate } | Select-Object -First 1)[0]

    if (-not $secondNext) { throw 'cached next prediction was not found on second build' }
    if (-not $secondSan) { throw 'cached sanzhong prediction was not found on second build' }
    if ([string]$secondNext.createdAt -ne [string]$firstNext.createdAt) {
        throw "expected next createdAt to be reused, got $($secondNext.createdAt), expected $($firstNext.createdAt)"
    }
    if ([string]$secondSan.createdAt -ne [string]$firstSan.createdAt) {
        throw "expected sanzhong createdAt to be reused, got $($secondSan.createdAt), expected $($firstSan.createdAt)"
    }

    Write-Host 'generated predictions cache ok'
}
finally {
    if (Test-Path -LiteralPath $outDir) {
        Remove-Item -LiteralPath $outDir -Recurse -Force
    }
}
