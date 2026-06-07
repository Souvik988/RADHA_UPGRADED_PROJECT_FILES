$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'
$dest = Join-Path $env:TEMP 'jdk17.zip'
if (Test-Path $dest) { Remove-Item $dest -Force }
Write-Host "Downloading to $dest"
Invoke-WebRequest -Uri 'https://aka.ms/download-jdk/microsoft-jdk-17.0.16-windows-x64.zip' -OutFile $dest -UseBasicParsing
$f = Get-Item $dest
Write-Host ("Downloaded: {0} bytes ({1:N1} MB)" -f $f.Length, ($f.Length / 1MB))
