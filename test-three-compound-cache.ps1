$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$outDir = Join-Path $root 'test-three-compound-cache-output'
$dataDir = Join-Path $outDir 'data'

function New-TestRecord {
    param([string]$Source, [string]$Date, [int]$Issue, [int[]]$Numbers)

    [pscustomobject]@{
        source = $Source
        date = $Date
        issue = $Issue
        balls = @(
            foreach ($num in $Numbers) {
                [pscustomobject]@{ numberText = $num.ToString('00'); number = $num }
            }
        )
    }
}

if (Test-Path -LiteralPath $outDir) {
    Remove-Item -LiteralPath $outDir -Recurse -Force
}
New-Item -ItemType Directory -Path $dataDir -Force | Out-Null

$records = @()
foreach ($source in @('am', 'hk')) {
    for ($i = 1; $i -le 12; $i++) {
        $records += New-TestRecord -Source $source -Date "2025-01-$($i.ToString('00'))" -Issue $i -Numbers @(1, 2, 3, 10, 11, 12, 49)
    }
    for ($i = 1; $i -le 12; $i++) {
        $records += New-TestRecord -Source $source -Date "2026-01-$($i.ToString('00'))" -Issue $i -Numbers @(4, 5, 6, 13, 14, 15, 48)
    }
}

$recordsJson = [pscustomobject]@{ records = $records } | ConvertTo-Json -Depth 8
[IO.File]::WriteAllText((Join-Path $dataDir 'records.json'), $recordsJson, [Text.UTF8Encoding]::new($false))

try {
    python (Join-Path $root 'build-three-compound.py') $outDir 'FIRST-RUN' | Out-Null
    python (Join-Path $root 'build-three-compound.py') $outDir 'SECOND-RUN' | Out-Null

    $statePath = Join-Path $dataDir 'three-compound-state.json'
    $state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
    foreach ($item in @($state.items)) {
        if ([string]$item.status -ne 'cached') {
            throw "expected cached source item for $($item.source), got $($item.status)"
        }
        if ([string]$item.computedAt -ne 'SECOND-RUN') {
            throw "expected computedAt SECOND-RUN for $($item.source), got $($item.computedAt)"
        }
        if (@($item.pools).Count -ne 4) {
            throw "expected 4 pools for $($item.source)"
        }
        if (@($item.crossYearPools).Count -ne 4) {
            throw "expected 4 crossYearPools for $($item.source)"
        }
        foreach ($pool in @($item.pools + $item.crossYearPools)) {
            if ([string]$pool.status -ne 'cached') {
                throw "expected cached pool for $($item.source) size $($pool.poolSize), got $($pool.status)"
            }
        }
    }

    Write-Host 'three compound cache reuse ok'
}
finally {
    if (Test-Path -LiteralPath $outDir) {
        Remove-Item -LiteralPath $outDir -Recurse -Force
    }
}
