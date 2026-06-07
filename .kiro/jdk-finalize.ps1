$ErrorActionPreference = 'Stop'

# 1. Set JAVA_HOME at user scope (persists, doesn't require admin)
[Environment]::SetEnvironmentVariable('JAVA_HOME', 'C:\Java\jdk-17', 'User')
Write-Host "JAVA_HOME (User) = $([Environment]::GetEnvironmentVariable('JAVA_HOME','User'))"

# 2. Append C:\Java\jdk-17\bin to USER PATH if not already present
$userPath = [Environment]::GetEnvironmentVariable('PATH', 'User')
if (-not $userPath) { $userPath = '' }
$jdkBin = 'C:\Java\jdk-17\bin'
$parts = $userPath.Split(';') | Where-Object { $_ -ne '' }
if ($parts -notcontains $jdkBin) {
    if ($userPath -ne '' -and -not $userPath.EndsWith(';')) { $userPath += ';' }
    $userPath += $jdkBin
    [Environment]::SetEnvironmentVariable('PATH', $userPath, 'User')
    Write-Host "Appended $jdkBin to USER PATH"
} else {
    Write-Host "USER PATH already contains $jdkBin"
}

# 3. Marker file
$marker = 'C:\Java\jdk-17\.radha-jdk-installed'
'done' | Set-Content -Path $marker -Encoding ASCII
if (Test-Path $marker) {
    Write-Host "Marker file: $marker  size=$((Get-Item $marker).Length) bytes"
} else {
    throw "Failed to create marker file"
}

# 4. Final summary
Write-Host "---SUMMARY---"
Write-Host "JAVA_HOME=$([Environment]::GetEnvironmentVariable('JAVA_HOME','User'))"
Write-Host "Marker=$marker"
Write-Host "java.exe=$(Test-Path 'C:\Java\jdk-17\bin\java.exe')"
