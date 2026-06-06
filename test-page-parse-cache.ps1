$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$scriptPath = Join-Path $root 'build-data.ps1'
$outDir = Join-Path $root 'test-page-parse-cache-output'
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
for ($i = 1; $i -le 10; $i++) {
    $records += New-RecordHtml -Issue $i -Date "2026-01-$($i.ToString('00'))" -Numbers @(1, 2, 3, 10, 11, 12, 49)
}
[IO.File]::WriteAllText((Join-Path $pagesDir 'am.html'), "<html><body>$($records -join "`n")</body></html>", $utf8NoBom)

try {
    & $scriptPath -RootDir $outDir | Out-Null
    & $scriptPath -RootDir $outDir | Out-Null

    $cachePath = Join-Path $outDir 'data\page-parse-cache.json'
    if (-not (Test-Path -LiteralPath $cachePath)) {
        throw 'page-parse-cache.json was not created'
    }

    $cacheText = Get-Content -LiteralPath $cachePath -Raw
    if (-not $cacheText.Contains('"files"')) {
        throw 'page parse cache should contain files'
    }
    if ($cacheText.Contains('"records"')) {
        throw 'page parse cache index should not inline parsed records'
    }
    if (-not $cacheText.Contains('"cacheFile"')) {
        throw 'page parse cache index should reference per-page cache files'
    }
    if (-not $cacheText.Contains('"am.html"')) {
        throw 'page parse cache should include am.html entry'
    }
    $cacheDir = Join-Path $outDir 'data\page-parse-cache'
    if (-not (Test-Path -LiteralPath $cacheDir)) {
        throw 'page parse cache directory was not created'
    }
    if (-not (Test-Path -LiteralPath (Join-Path $cacheDir 'am.html.json'))) {
        throw 'page parse cache should write per-page records cache'
    }

    $recordsPath = Join-Path $outDir 'data\records.json'
    $recordCount = @"
import json
from pathlib import Path
data = json.loads(Path(r'$recordsPath').read_text(encoding='utf-8'))
print(len(data.get('records', [])))
"@ | python -
    if ([int]$recordCount -ne 10) {
        throw "expected 10 records after cached build, got $recordCount"
    }

    Write-Host 'page parse cache ok'
}
finally {
    if (Test-Path -LiteralPath $outDir) {
        Remove-Item -LiteralPath $outDir -Recurse -Force
    }
}
