$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'

$zip = Join-Path $env:TEMP 'jdk17.zip'
$extractDir = 'C:\Java\_extract'
$finalDir = 'C:\Java\jdk-17'

if (-not (Test-Path 'C:\Java')) {
    New-Item -ItemType Directory -Path 'C:\Java' -Force | Out-Null
}

if (Test-Path $extractDir) { Remove-Item -Path $extractDir -Recurse -Force }
if (Test-Path $finalDir)   { Remove-Item -Path $finalDir   -Recurse -Force }

Write-Host "Extracting $zip -> $extractDir"
Expand-Archive -Path $zip -DestinationPath $extractDir -Force

$inner = Get-ChildItem -Path $extractDir -Directory | Select-Object -First 1
if (-not $inner) { throw "No inner folder found inside the extracted ZIP" }
Write-Host "Inner folder: $($inner.FullName)"

Move-Item -Path $inner.FullName -Destination $finalDir -Force
Remove-Item -Path $extractDir -Recurse -Force

if (-not (Test-Path (Join-Path $finalDir 'bin\java.exe'))) {
    throw "java.exe not found at $finalDir\bin\java.exe after extract"
}
Write-Host "OK: $finalDir\bin\java.exe exists"
