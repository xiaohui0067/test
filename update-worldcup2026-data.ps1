param(
  [string]$Workspace = $PSScriptRoot
)

$ErrorActionPreference = "Stop"

$nodeScript = Join-Path $Workspace "update-worldcup2026-data.mjs"
if (-not (Test-Path -LiteralPath $nodeScript)) {
  throw "Missing update-worldcup2026-data.mjs"
}

Push-Location $Workspace
try {
  node $nodeScript
} finally {
  Pop-Location
}
