param(
    [string]$SourceUrl = 'https://2025kj.zkclhb.com:2025/am.html',
    [string]$OutputDir = 'C:\codex\test\am',
    [string]$BaseUrl = 'https://2025kj.zkclhb.com:2025/am.html',
    [switch]$SkipSnapshot
)

$ErrorActionPreference = 'Stop'
$Utf8NoBom = [Text.UTF8Encoding]::new($false)

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = 'INFO'
    )

    $logDir = Join-Path $OutputDir 'logs'
    if (-not (Test-Path -LiteralPath $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }

    $line = '{0} [{1}] {2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message
    Add-Content -LiteralPath (Join-Path $logDir 'fetch.log') -Value $line -Encoding UTF8
}

function New-HttpClient {
    Add-Type -AssemblyName System.Net.Http
    $client = [System.Net.Http.HttpClient]::new()
    $client.Timeout = [TimeSpan]::FromSeconds(30)

    $headers = @{
        'User-Agent'      = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36'
        'Accept'          = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8'
        'Accept-Language' = 'zh-CN,zh;q=0.9,en;q=0.8'
        'Cache-Control'   = 'no-cache'
        'Pragma'          = 'no-cache'
    }
    foreach ($key in $headers.Keys) {
        $client.DefaultRequestHeaders.TryAddWithoutValidation($key, $headers[$key]) | Out-Null
    }

    return $client
}

function Get-SourceContent {
    param([string]$Url)

    if (Test-Path -LiteralPath $Url) {
        return [IO.File]::ReadAllText((Resolve-Path -LiteralPath $Url).ProviderPath, [Text.Encoding]::UTF8)
    }
    $uri = [Uri]$Url
    if ($uri.IsFile -and (Test-Path -LiteralPath $uri.LocalPath)) {
        return [IO.File]::ReadAllText($uri.LocalPath, [Text.Encoding]::UTF8)
    }

    $client = New-HttpClient
    try {
        $bytes = $client.GetByteArrayAsync($Url).GetAwaiter().GetResult()
        return [Text.Encoding]::UTF8.GetString($bytes)
    }
    finally {
        $client.Dispose()
    }
}

function Get-LocalNoticeText {
    $chars = @(
        0x672C, 0x5730, 0x5F00, 0x5956, 0x8BB0, 0x5F55, 0x526F, 0x672C,
        0xFF0C, 0x6700, 0x540E, 0x6293, 0x53D6, 0x65F6, 0x95F4, 0xFF1A
    )
    return [string]::Concat(($chars | ForEach-Object { [char]$_ }))
}

function Save-RemoteAsset {
    param(
        [Uri]$AssetUri,
        [string]$LocalPath
    )

    if ($AssetUri.IsFile -and (Test-Path -LiteralPath $AssetUri.LocalPath)) {
        Copy-Item -LiteralPath $AssetUri.LocalPath -Destination $LocalPath -Force
        return
    }

    $headers = @{
        'User-Agent'      = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36'
        'Accept'          = '*/*'
        'Accept-Language' = 'zh-CN,zh;q=0.9,en;q=0.8'
    }
    Invoke-WebRequest -Uri $AssetUri.AbsoluteUri -Headers $headers -OutFile $LocalPath -UseBasicParsing -TimeoutSec 30
}

function Convert-ToLocalViewHtml {
    param(
        [string]$Html,
        [string]$BaseUrl,
        [string]$OutputDir,
        [hashtable]$PageMap = @{},
        [string]$RelativePrefix = ''
    )

    $base = [Uri]$BaseUrl
    $rewritten = $Html

    $rewritten = [regex]::Replace(
        $rewritten,
        '(?is)<script\b[^>]*\bsrc=["'']https?://[^"'']*cnzz\.com/[^"'']*["''][^>]*>\s*</script>',
        ''
    )
    $rewritten = [regex]::Replace(
        $rewritten,
        '(?is)<script\b[^>]*>.*?cnzz\.com.*?</script>',
        ''
    )

    foreach ($attribute in @('src', 'href')) {
        $pattern = '(?i)(\b' + $attribute + '\s*=\s*["''])(?!data:|javascript:|mailto:|tel:|#|https?:|//)([^"'']+\.(?:css|js|png|jpg|jpeg|gif|webp|ico|svg|woff|woff2|ttf)(?:\?[^"'']*)?)(["''])'
        $rewritten = [regex]::Replace($rewritten, $pattern, {
            param($match)

            $assetValue = $match.Groups[2].Value
            $assetUri = [Uri]::new($base, $assetValue)
            if ($base.IsFile) {
                $pathPart = $assetValue.TrimStart('/', '\')
            }
            else {
                $pathPart = $assetUri.AbsolutePath.TrimStart('/')
            }
            $queryPart = ''
            if (-not [string]::IsNullOrWhiteSpace($assetUri.Query)) {
                $queryPart = '-' + ([Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($assetUri.Query)).TrimEnd('=') -replace '[+/]', '_')
            }

            $localRelative = ('assets/site/{0}{1}' -f $pathPart, $queryPart) -replace '\\', '/'
            $localPath = Join-Path $OutputDir ($localRelative -replace '/', [IO.Path]::DirectorySeparatorChar)
            $localDir = Split-Path -Parent $localPath
            if (-not (Test-Path -LiteralPath $localDir)) {
                New-Item -ItemType Directory -Path $localDir -Force | Out-Null
            }

            try {
                Save-RemoteAsset -AssetUri $assetUri -LocalPath $localPath
            }
            catch {
                Write-Log "Asset download failed: $($assetUri.AbsoluteUri) - $($_.Exception.Message)" 'WARN'
                return $match.Groups[1].Value + '#' + $match.Groups[3].Value
            }

            return $match.Groups[1].Value + $RelativePrefix + $localRelative + $match.Groups[3].Value
        })
    }

    $rewritten = [regex]::Replace($rewritten, '(?i)(\bhref\s*=\s*["''])(?!data:|javascript:|mailto:|tel:|#|(?:\.\./)*assets/)([^"'']+)(["''])', {
        param($match)
        $hrefUri = [Uri]::new($base, $match.Groups[2].Value)
        $key = $hrefUri.AbsoluteUri
        if ($PageMap.ContainsKey($key)) {
            return $match.Groups[1].Value + $PageMap[$key] + $match.Groups[3].Value
        }
        return $match.Groups[1].Value + '#' + $match.Groups[3].Value
    })

    $stamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $noticeText = (Get-LocalNoticeText) + $stamp
    $notice = @"
<div id="local-fetch-notice" style="position:sticky;top:0;z-index:99999;padding:8px 12px;background:#fff7cc;border-bottom:1px solid #e3c96a;color:#333;font-size:14px;line-height:1.4;text-align:center;">
$noticeText
</div>
"@

    if ($rewritten -match '(?i)<body[^>]*>') {
        return [regex]::Replace($rewritten, '(?i)(<body[^>]*>)', '$1' + $notice, 1)
    }

    return $notice + $rewritten
}

function Get-LinkedHtmlPages {
    param(
        [string]$Html,
        [string]$BaseUrl
    )

    $base = [Uri]$BaseUrl
    $items = New-Object 'System.Collections.Generic.List[object]'
    $seen = @{}
    $pattern = '(?i)\bhref\s*=\s*["''](?!data:|javascript:|mailto:|tel:|#)([^"'']+\.html(?:\?[^"'']*)?)(["''])'

    foreach ($match in [regex]::Matches($Html, $pattern)) {
        $uri = [Uri]::new($base, $match.Groups[1].Value)
        if ($uri.IsFile) {
            $sameSite = $true
        }
        else {
            $sameSite = ($uri.Scheme -eq $base.Scheme -and $uri.Host -eq $base.Host -and $uri.Port -eq $base.Port)
        }

        if (-not $sameSite) {
            continue
        }

        $key = $uri.AbsoluteUri
        if ($seen.ContainsKey($key)) {
            continue
        }
        $seen[$key] = $true

        $fileName = [IO.Path]::GetFileName($uri.AbsolutePath)
        if ([string]::IsNullOrWhiteSpace($fileName)) {
            continue
        }

        $items.Add([pscustomobject]@{
            Uri = $uri
            LocalRelative = ('pages/{0}' -f $fileName)
        }) | Out-Null
    }

    return $items
}

function Get-LocalPageName {
    param([Uri]$Uri)

    $fileName = [IO.Path]::GetFileName($Uri.AbsolutePath)
    if ([string]::IsNullOrWhiteSpace($fileName)) {
        $fileName = 'index.html'
    }
    return $fileName
}

function Get-SiteHtmlPages {
    param(
        [string]$RootHtml,
        [string]$RootUrl,
        [int]$MaxPages = 80
    )

    $rootUri = [Uri]$RootUrl
    $pages = [ordered]@{}
    $queue = New-Object 'System.Collections.Generic.Queue[object]'

    $rootPageName = 'am.html'
    $rootKey = $rootUri.AbsoluteUri
    $pages[$rootKey] = [pscustomobject]@{
        Uri = $rootUri
        LocalRelative = ('pages/{0}' -f $rootPageName)
        Html = $RootHtml
    }

    foreach ($link in (Get-LinkedHtmlPages -Html $RootHtml -BaseUrl $RootUrl)) {
        if (-not $pages.Contains($link.Uri.AbsoluteUri)) {
            $pages[$link.Uri.AbsoluteUri] = [pscustomobject]@{
                Uri = $link.Uri
                LocalRelative = $link.LocalRelative
                Html = $null
            }
            $queue.Enqueue($link.Uri)
        }
    }

    while ($queue.Count -gt 0 -and $pages.Count -lt $MaxPages) {
        $uri = $queue.Dequeue()
        $key = $uri.AbsoluteUri
        try {
            Write-Log "Start discovering linked page: $key"
            $pageHtml = Get-SourceContent -Url $key
            $pages[$key].Html = $pageHtml

            foreach ($link in (Get-LinkedHtmlPages -Html $pageHtml -BaseUrl $key)) {
                $linkKey = $link.Uri.AbsoluteUri
                if ($pages.Contains($linkKey)) {
                    continue
                }
                if ($pages.Count -ge $MaxPages) {
                    break
                }
                $pages[$linkKey] = [pscustomobject]@{
                    Uri = $link.Uri
                    LocalRelative = $link.LocalRelative
                    Html = $null
                }
                $queue.Enqueue($link.Uri)
            }
        }
        catch {
            Write-Log "Linked page discovery failed: $key - $($_.Exception.Message)" 'WARN'
        }
    }

    return $pages
}

if (-not (Test-Path -LiteralPath $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

try {
    Write-Log "Start fetching: $SourceUrl"
    $html = Get-SourceContent -Url $SourceUrl
    $baseUrlForRewrite = $BaseUrl
    if ((Test-Path -LiteralPath $SourceUrl) -and $PSBoundParameters.ContainsKey('BaseUrl') -eq $false) {
        $baseUrlForRewrite = [Uri]::new((Resolve-Path -LiteralPath $SourceUrl).ProviderPath).AbsoluteUri
    }
    $allPages = Get-SiteHtmlPages -RootHtml $html -RootUrl $baseUrlForRewrite
    $linkedPages = @($allPages.Values)
    $pageMap = @{}
    foreach ($page in $linkedPages) {
        $pageMap[$page.Uri.AbsoluteUri] = $page.LocalRelative
    }
    $nestedPageMap = @{}
    foreach ($page in $linkedPages) {
        $nestedPageMap[$page.Uri.AbsoluteUri] = [IO.Path]::GetFileName($page.LocalRelative)
    }

    $pagesDir = Join-Path $OutputDir 'pages'
    if (-not (Test-Path -LiteralPath $pagesDir)) {
        New-Item -ItemType Directory -Path $pagesDir -Force | Out-Null
    }

    $localHtml = Convert-ToLocalViewHtml -Html $html -BaseUrl $baseUrlForRewrite -OutputDir $OutputDir -PageMap $pageMap

    $indexPath = Join-Path $OutputDir 'index.html'
    [IO.File]::WriteAllText($indexPath, $localHtml, $Utf8NoBom)

    $rootPage = $allPages[([Uri]$baseUrlForRewrite).AbsoluteUri]
    if ($null -ne $rootPage) {
        $rootNestedHtml = Convert-ToLocalViewHtml -Html $html -BaseUrl $baseUrlForRewrite -OutputDir $OutputDir -PageMap $nestedPageMap -RelativePrefix '../'
        $rootNestedPath = Join-Path $OutputDir ($rootPage.LocalRelative -replace '/', [IO.Path]::DirectorySeparatorChar)
        [IO.File]::WriteAllText($rootNestedPath, $rootNestedHtml, $Utf8NoBom)
    }

    foreach ($page in $linkedPages) {
        if ($page.Uri.AbsoluteUri -eq ([Uri]$baseUrlForRewrite).AbsoluteUri) {
            continue
        }
        try {
            Write-Log "Start saving linked page: $($page.Uri.AbsoluteUri)"
            $pageHtml = $page.Html
            if ([string]::IsNullOrEmpty($pageHtml)) {
                $pageHtml = Get-SourceContent -Url $page.Uri.AbsoluteUri
            }
            $convertedPage = Convert-ToLocalViewHtml -Html $pageHtml -BaseUrl $page.Uri.AbsoluteUri -OutputDir $OutputDir -PageMap $nestedPageMap -RelativePrefix '../'
            $pagePath = Join-Path $OutputDir ($page.LocalRelative -replace '/', [IO.Path]::DirectorySeparatorChar)
            [IO.File]::WriteAllText($pagePath, $convertedPage, $Utf8NoBom)
            Write-Log "Linked page saved: $pagePath"
        }
        catch {
            Write-Log "Linked page fetch failed: $($page.Uri.AbsoluteUri) - $($_.Exception.Message)" 'WARN'
        }
    }

    if (-not $SkipSnapshot) {
        $snapshotDir = Join-Path $OutputDir 'snapshots'
        if (-not (Test-Path -LiteralPath $snapshotDir)) {
            New-Item -ItemType Directory -Path $snapshotDir -Force | Out-Null
        }
        $snapshotName = 'am-{0}.html' -f (Get-Date -Format 'yyyyMMdd-HHmmss')
        Copy-Item -LiteralPath $indexPath -Destination (Join-Path $snapshotDir $snapshotName) -Force
    }

    $buildDataScript = Join-Path $OutputDir 'build-data.ps1'
    if (Test-Path -LiteralPath $buildDataScript) {
        & $buildDataScript -RootDir $OutputDir | Out-Null
        Write-Log "Dashboard data refreshed"
    }

    Write-Log "Fetch success: $indexPath"
    Write-Host "Saved: $indexPath"
}
catch {
    Write-Log $_.Exception.Message 'ERROR'
    throw
}
