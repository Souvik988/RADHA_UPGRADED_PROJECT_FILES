$ErrorActionPreference = 'Stop'

$adds = @(
  'C:\Android\cmdline-tools\latest\bin',
  'C:\Android\platform-tools',
  'C:\Android\emulator'
)

$current = (Get-ItemProperty -Path 'HKCU:\Environment' -Name Path -ErrorAction SilentlyContinue).Path
if ($null -eq $current) { $current = '' }

Write-Host "Current USER PATH:"
Write-Host $current

$entries = @()
if ($current.Length -gt 0) {
  $entries = $current -split ';' | Where-Object { $_ -ne '' }
}

foreach ($add in $adds) {
  $exists = $false
  foreach ($e in $entries) {
    if ($e.TrimEnd('\') -ieq $add.TrimEnd('\')) { $exists = $true; break }
  }
  if (-not $exists) {
    $entries += $add
    Write-Host "Adding: $add"
  } else {
    Write-Host "Already present: $add"
  }
}

$newPath = ($entries -join ';')
Write-Host "`nNew USER PATH:"
Write-Host $newPath

# Use setx via cmd to set USER PATH (REG-only, system PATH untouched)
$argList = @('/c', 'setx', 'PATH', $newPath)
$p = Start-Process -FilePath 'cmd.exe' -ArgumentList $argList -NoNewWindow -Wait -PassThru
if ($p.ExitCode -ne 0) { throw "setx failed with exit code $($p.ExitCode)" }
Write-Host "SETX_OK"
