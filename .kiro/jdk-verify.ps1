$ErrorActionPreference = 'Stop'
$out = & 'C:\Java\jdk-17\bin\java.exe' -version 2>&1 | Out-String
$out | Set-Content -Path 'C:\Java\jdk-17\.java-version.txt' -Encoding ASCII
Write-Host "===BEGIN==="
Write-Host $out
Write-Host "===END==="
