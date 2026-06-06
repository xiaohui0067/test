$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$scriptPath = Join-Path $root 'build-data.ps1'
$outDir = Join-Path $root 'test-game-predictions-cache-output'
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
    $gamePath = Join-Path $outDir 'data\game-predictions.json'
    $firstItemJson = @"
import json
from pathlib import Path
data = json.loads(Path(r'$gamePath').read_text(encoding='utf-8'))
items = [item for item in data.get('items', []) if item.get('source') == 'am' and item.get('game') == 'three-hit-three' and item.get('algorithmId') == 'ensemble']
print(json.dumps(items[0] if items else {}, ensure_ascii=False))
"@ | python -
    $firstItem = $firstItemJson | ConvertFrom-Json
    if (-not $firstItem.id) { throw 'first ensemble game prediction was not created' }

    @"
import json
from pathlib import Path
path = Path(r'$gamePath')
data = json.loads(path.read_text(encoding='utf-8'))
for item in data.get('items', []):
    if item.get('id') == '$($firstItem.id)':
        item['status'] = 'settled'
        item['actualDate'] = item.get('targetDate')
        item['actualIssue'] = item.get('issue')
        item['actualNumbers'] = item.get('numbers', [])
        item['hit'] = True
        item['settleCacheSentinel'] = 'keep-me'
        break
path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding='utf-8')
"@ | python -

    Start-Sleep -Seconds 1
    & $scriptPath -RootDir $outDir | Out-Null
    $secondItemJson = @"
import json
from pathlib import Path
data = json.loads(Path(r'$gamePath').read_text(encoding='utf-8'))
items = [
    item for item in data.get('items', [])
    if item.get('source') == '$($firstItem.source)'
    and item.get('game') == '$($firstItem.game)'
    and item.get('algorithmId') == '$($firstItem.algorithmId)'
    and int(item.get('issue') or 0) == $($firstItem.issue)
    and str(item.get('displayYear') or '') == '$($firstItem.displayYear)'
    and str(item.get('targetDate') or '') == '$($firstItem.targetDate)'
]
print(json.dumps(items[0] if items else {}, ensure_ascii=False))
"@ | python -
    $secondItem = $secondItemJson | ConvertFrom-Json

    if (-not $secondItem.id) { throw 'cached game prediction was not found on second build' }
    if ([string]$secondItem.createdAt -ne [string]$firstItem.createdAt) {
        throw "expected game prediction createdAt to be reused, got $($secondItem.createdAt), expected $($firstItem.createdAt)"
    }
    if ([string]$secondItem.settleCacheSentinel -ne 'keep-me') {
        throw 'expected settled game prediction to be reused without re-settlement'
    }

    Write-Host 'game predictions cache ok'
}
finally {
    if (Test-Path -LiteralPath $outDir) {
        Remove-Item -LiteralPath $outDir -Recurse -Force
    }
}
