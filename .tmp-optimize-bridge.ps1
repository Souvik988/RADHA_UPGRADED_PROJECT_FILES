$ErrorActionPreference = 'Stop'
$drv = 'C:\Users\sayan\Desktop\image-gpt\browser-agent\dist\browser\imageDriver.js'
$cli = 'C:\Users\sayan\Desktop\image-gpt\mcp-server\dist\relayClient.js'

# --- Image driver: backup + optimize ---
if (Test-Path $drv) {
  if (-not (Test-Path "$drv.bak")) { Copy-Item $drv "$drv.bak" }
  $c = Get-Content $drv -Raw
  # Shrink the stabilization wait (was 55_000) -> 18_000 ; raise deadline (was 600_000) -> 900_000
  $c = $c -replace 'IMAGE_STABILIZATION_MS = 55_000', 'IMAGE_STABILIZATION_MS = 18_000'
  $c = $c -replace 'IMAGE_STABILIZATION_MS = 55000', 'IMAGE_STABILIZATION_MS = 18000'
  $c = $c -replace 'DEFAULT_TIMEOUT_MS = 600_000', 'DEFAULT_TIMEOUT_MS = 900_000'
  $c = $c -replace 'DEFAULT_TIMEOUT_MS = 600000', 'DEFAULT_TIMEOUT_MS = 900000'
  Set-Content $drv $c -NoNewline
  Write-Output "DRV_OK stabil=$([regex]::Match($c,'IMAGE_STABILIZATION_MS = \d+').Value) deadline=$([regex]::Match($c,'DEFAULT_TIMEOUT_MS = \d+').Value)"
} else { Write-Output "DRV_MISSING" }

# --- MCP relay client: raise outer request timeout above the new deadline ---
if (Test-Path $cli) {
  if (-not (Test-Path "$cli.bak")) { Copy-Item $cli "$cli.bak" }
  $c2 = Get-Content $cli -Raw
  $c2 = $c2 -replace 'DEFAULT_REQUEST_TIMEOUT_MS = 660_000', 'DEFAULT_REQUEST_TIMEOUT_MS = 1_020_000'
  $c2 = $c2 -replace 'DEFAULT_REQUEST_TIMEOUT_MS = 660000', 'DEFAULT_REQUEST_TIMEOUT_MS = 1020000'
  Set-Content $cli $c2 -NoNewline
  Write-Output "CLI_OK timeout=$([regex]::Match($c2,'DEFAULT_REQUEST_TIMEOUT_MS = [\d_]+').Value)"
} else { Write-Output "CLI_MISSING" }
