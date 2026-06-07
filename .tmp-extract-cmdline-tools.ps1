$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$zipPath = Join-Path $env:TEMP 'cmdline-tools.zip'
if (-not (Test-Path $zipPath)) { throw "Zip not found at $zipPath" }

$target = 'C:\Android\cmdline-tools\latest'
$parent = 'C:\Android\cmdline-tools'

# Make target dir parent
New-Item -ItemType Directory -Path $parent -Force | Out-Null

# Clean any prior partial install at target
if (Test-Path $target) {
  Write-Host "Removing existing $target"
  Remove-Item -Path $target -Recurse -Force
}

# Staging
$staging = Join-Path $env:TEMP 'android-cmdline-tools-staging'
if (Test-Path $staging) { Remove-Item $staging -Recurse -Force }
New-Item -ItemType Directory -Path $staging -Force | Out-Null

Write-Host "Expanding $zipPath to $staging"
Expand-Archive -Path $zipPath -DestinationPath $staging -Force

$inner = Join-Path $staging 'cmdline-tools'
if (-not (Test-Path $inner)) {
  throw "Expected $inner to exist after extraction"
}

Write-Host "Moving $inner -> $target"
Move-Item -Path $inner -Destination $target -Force

Remove-Item -Path $staging -Recurse -Force

if (Test-Path (Join-Path $target 'bin\sdkmanager.bat')) {
  Write-Host "EXTRACT_OK: sdkmanager.bat present"
} else {
  throw "sdkmanager.bat missing after extract at $target\bin\sdkmanager.bat"
}
