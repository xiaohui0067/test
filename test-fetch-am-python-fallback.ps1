$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$scriptPath = Join-Path $root 'fetch-am.ps1'
$fixtureDir = Join-Path $root 'test-fallback-source'
$outDir = Join-Path $root 'test-fallback-output'
$port = 18765
$server = $null

if (Test-Path -LiteralPath $outDir) {
    Remove-Item -LiteralPath $outDir -Recurse -Force
}
if (Test-Path -LiteralPath $fixtureDir) {
    Remove-Item -LiteralPath $fixtureDir -Recurse -Force
}

try {
    New-Item -ItemType Directory -Path (Join-Path $fixtureDir 'static') -Force | Out-Null
    $utf8NoBom = [Text.UTF8Encoding]::new($false)
    [IO.File]::WriteAllText((Join-Path $fixtureDir 'am.html'), '<html><head><link rel="stylesheet" href="static/site.css"></head><body>FALLBACK-ROOT</body></html>', $utf8NoBom)
    [IO.File]::WriteAllText((Join-Path $fixtureDir 'static/site.css'), 'body { color: #222; }', $utf8NoBom)

    $server = Start-Process -FilePath 'python' -ArgumentList @('-m', 'http.server', $port, '--bind', '127.0.0.1', '--directory', $fixtureDir) -WindowStyle Hidden -PassThru
    Start-Sleep -Milliseconds 800

    $env:FETCH_AM_FORCE_DOTNET_DOWNLOAD_FAILURE = '1'
    & $scriptPath -SourceUrl "http://127.0.0.1:$port/am.html" -BaseUrl "http://127.0.0.1:$port/am.html" -OutputDir $outDir -SkipSnapshot | Out-Null

    $index = Join-Path $outDir 'index.html'
    if (-not (Test-Path -LiteralPath $index)) {
        throw 'index.html was not created'
    }
    $html = [IO.File]::ReadAllText($index, [Text.Encoding]::UTF8)
    if ($html -notmatch 'FALLBACK-ROOT') {
        throw 'fallback-downloaded page content missing'
    }
    if (-not (Test-Path -LiteralPath (Join-Path $outDir 'assets/site/static/site.css'))) {
        throw 'fallback-downloaded asset missing'
    }
    $log = [IO.File]::ReadAllText((Join-Path $outDir 'logs/fetch.log'), [Text.Encoding]::UTF8)
    if ($log -notmatch 'Python download fallback') {
        throw 'Python fallback was not used'
    }

    Write-Host 'PASS'
}
finally {
    Remove-Item Env:FETCH_AM_FORCE_DOTNET_DOWNLOAD_FAILURE -ErrorAction SilentlyContinue
    if ($null -ne $server -and -not $server.HasExited) {
        Stop-Process -Id $server.Id -Force
    }
    if (Test-Path -LiteralPath $fixtureDir) {
        Remove-Item -LiteralPath $fixtureDir -Recurse -Force
    }
    if (Test-Path -LiteralPath $outDir) {
        Remove-Item -LiteralPath $outDir -Recurse -Force
    }
}
