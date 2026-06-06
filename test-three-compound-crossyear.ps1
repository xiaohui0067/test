$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$outDir = Join-Path $root 'test-three-compound-crossyear-output'
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
    python (Join-Path $root 'build-three-compound.py') $outDir 'TEST-CROSSYEAR' | Out-Null

    $statePath = Join-Path $dataDir 'three-compound-state.json'
    if (-not (Test-Path $statePath)) {
        throw 'three-compound-state.json was not generated'
    }

    $state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
    $items = @($state.items)
    if ($items.Count -eq 0) {
        throw 'expected at least one three-compound state item'
    }

    foreach ($item in $items) {
        $yearPools = @($item.pools)
        $crossYearPools = @($item.crossYearPools)

        if ($crossYearPools.Count -ne 4) {
            throw "expected 4 crossYearPools for $($item.source), got $($crossYearPools.Count)"
        }

        foreach ($size in @(5, 6, 7, 8)) {
            $pool = @($crossYearPools | Where-Object { [int]$_.poolSize -eq $size })
            if ($pool.Count -ne 1) {
                throw "expected one crossYear pool size $size for $($item.source), got $($pool.Count)"
            }

            $nums = @($pool[0].pool)
            if ($nums.Count -ne $size) {
                throw "expected crossYear pool size $size to contain $size numbers for $($item.source), got $($nums.Count)"
            }

            if ([string]$pool[0].scope -ne 'all-history') {
                throw "expected crossYear pool size $size scope all-history for $($item.source)"
            }

            if ([int]$pool[0].historyTotal -lt [int]$pool[0].yearTotal) {
                throw "expected historyTotal >= yearTotal for $($item.source) size $size"
            }

            if ($null -eq $pool[0].yearWindows) {
                throw "expected yearWindows on crossYear pool for $($item.source) size $size"
            }

            $yearPool = @($yearPools | Where-Object { [int]$_.poolSize -eq $size })
            if ($yearPool.Count -eq 1) {
                $intersection = @($nums | Where-Object { @($yearPool[0].pool) -contains $_ })
                if ([int]$pool[0].intersectionCount -ne $intersection.Count) {
                    throw "expected intersectionCount to match actual intersection for $($item.source) size $size"
                }
            }
        }
    }

    Write-Host 'three compound cross-year state shape ok'
}
finally {
    if (Test-Path -LiteralPath $outDir) {
        Remove-Item -LiteralPath $outDir -Recurse -Force
    }
}
