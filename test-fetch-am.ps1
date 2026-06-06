$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$scriptPath = Join-Path $root 'fetch-am.ps1'
$sourceHtml = Join-Path $root 'sample-source.html'
$sourceStaticDir = Join-Path $root 'static'
$outDir = Join-Path $root 'test-output'
$zhText = [string]::Concat([char]0x6FB3, [char]0x95E8, [char]0x5F00, [char]0x5956, [char]0x8BB0, [char]0x5F55)

if (Test-Path -LiteralPath $outDir) {
    Remove-Item -LiteralPath $outDir -Recurse -Force
}
if (Test-Path -LiteralPath $sourceStaticDir) {
    Remove-Item -LiteralPath $sourceStaticDir -Recurse -Force
}

$sampleHtml = @"
<!DOCTYPE html>
<html>
<head>
  <link rel="stylesheet" href="static/css/history.css">
</head>
<body>
  <a href="hk.html">HK</a>
  <a href="2025.html">2025</a>
  <img src="/static/logo.png">
  <script src="static/app.js"></script>
  <div class="record">DRAW-001</div>
  <div class="zh">$zhText</div>
</body>
</html>
"@
$utf8NoBom = [Text.UTF8Encoding]::new($false)
[IO.File]::WriteAllText($sourceHtml, $sampleHtml, $utf8NoBom)

New-Item -ItemType Directory -Path (Join-Path $sourceStaticDir 'css') -Force | Out-Null
[IO.File]::WriteAllText((Join-Path $sourceStaticDir 'css/history.css'), 'body { color: #111; }', $utf8NoBom)
[IO.File]::WriteAllText((Join-Path $sourceStaticDir 'app.js'), 'window.__sample = true;', $utf8NoBom)
[IO.File]::WriteAllText((Join-Path $root 'hk.html'), '<html><head><link rel="stylesheet" href="static/css/history.css"></head><body><a href="hk2025.html">HK2025</a><a href="2025.html">2025</a>HK-LOCAL</body></html>', $utf8NoBom)
[IO.File]::WriteAllText((Join-Path $root '2025.html'), '<html><body>YEAR-2025</body></html>', $utf8NoBom)
[IO.File]::WriteAllText((Join-Path $root 'hk2025.html'), '<html><body>HK-YEAR-2025</body></html>', $utf8NoBom)

try {
    & $scriptPath -SourceUrl $sourceHtml -OutputDir $outDir -BaseUrl $sourceHtml -SkipSnapshot | Out-Null

    $index = Join-Path $outDir 'kjjl.html'
    if (-not (Test-Path -LiteralPath $index)) {
        throw 'kjjl.html was not created'
    }

    $html = [IO.File]::ReadAllText($index, [Text.Encoding]::UTF8)
    if ($html -notmatch 'assets/site/static/css/history\.css') {
        throw 'stylesheet was not rewritten to local asset path'
    }
    if ($html -notmatch 'href="pages/hk.html"') {
        throw 'hk navigation href was not rewritten to local page'
    }
    if ($html -notmatch 'href="pages/2025.html"') {
        throw 'year navigation href was not rewritten to local page'
    }
    if (-not (Test-Path -LiteralPath (Join-Path $outDir 'pages/hk.html'))) {
        throw 'hk local page was not saved'
    }
    if (-not (Test-Path -LiteralPath (Join-Path $outDir 'pages/am.html'))) {
        throw 'root am page copy was not saved under pages'
    }
    if (-not (Test-Path -LiteralPath (Join-Path $outDir 'pages/2025.html'))) {
        throw 'year local page was not saved'
    }
    if (-not (Test-Path -LiteralPath (Join-Path $outDir 'pages/hk2025.html'))) {
        throw 'second-level hk year page was not saved'
    }
    if ($html -notmatch 'assets/site/static/app\.js') {
        throw 'script src was not rewritten to local asset path'
    }
    $hkHtml = [IO.File]::ReadAllText((Join-Path $outDir 'pages/hk.html'), [Text.Encoding]::UTF8)
    if ($hkHtml -notmatch 'href="../assets/site/static/css/history\.css"') {
        throw 'nested page stylesheet path was not rewritten relative to pages directory'
    }
    if ($hkHtml -notmatch 'href="2025.html"') {
        throw 'nested page navigation path was not rewritten relative to pages directory'
    }
    if ($hkHtml -notmatch 'href="hk2025.html"') {
        throw 'second-level nested page navigation path was not rewritten'
    }
    if ($html -notmatch 'DRAW-001') {
        throw 'record content missing'
    }
    if (-not $html.Contains($zhText)) {
        throw 'Chinese content was not preserved'
    }
    if ($html -match 'https://2025kj\.zkclhb\.com:2025') {
        throw 'original site link remained in local HTML'
    }

    Write-Host 'PASS'
}
finally {
    if (Test-Path -LiteralPath $sourceHtml) {
        Remove-Item -LiteralPath $sourceHtml -Force
    }
    foreach ($pageName in @('hk.html', '2025.html', 'hk2025.html')) {
        $pagePath = Join-Path $root $pageName
        if (Test-Path -LiteralPath $pagePath) {
            Remove-Item -LiteralPath $pagePath -Force
        }
    }
    if (Test-Path -LiteralPath $sourceStaticDir) {
        Remove-Item -LiteralPath $sourceStaticDir -Recurse -Force
    }
    if (Test-Path -LiteralPath $outDir) {
        Remove-Item -LiteralPath $outDir -Recurse -Force
    }
}
