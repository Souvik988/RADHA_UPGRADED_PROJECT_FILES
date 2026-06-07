$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$zipPath = Join-Path $env:TEMP 'cmdline-tools.zip'
$url = 'https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip'

Write-Host "Downloading $url -> $zipPath"
$attempt = 0
$maxAttempts = 2
$lastErr = $null
while ($attempt -lt $maxAttempts) {
  $attempt++
  try {
    Invoke-WebRequest -Uri $url -OutFile $zipPath -UseBasicParsing -TimeoutSec 540
    break
  } catch {
    $lastErr = $_
    Write-Host "Attempt $attempt failed: $($_.Exception.Message)"
    if ($attempt -ge $maxAttempts) { throw $lastErr }
    Start-Sleep -Seconds 5
  }
}

$fi = Get-Item $zipPath
Write-Host ("Downloaded: {0} ({1} bytes)" -f $fi.FullName, $fi.Length)
if ($fi.Length -lt 50000000) {
  throw "Downloaded file looks too small ($($fi.Length) bytes); aborting."
}
Write-Host "DOWNLOAD_OK"
