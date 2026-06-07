$ErrorActionPreference = 'Continue'
$start = Get-Date
$maxIterations = 60
$jdkMarker = 'C:\Java\jdk-17\.radha-jdk-installed'
$cmdMarker = 'C:\Android\cmdline-tools\latest\.radha-cmdline-tools-installed'

for ($i = 1; $i -le $maxIterations; $i++) {
    $jdkOk = Test-Path $jdkMarker
    $cmdOk = Test-Path $cmdMarker
    $elapsed = [int]((Get-Date) - $start).TotalSeconds
    Write-Host "[$elapsed s][iter $i/$maxIterations] JDK=$jdkOk CMDLINE=$cmdOk"
    if ($jdkOk -and $cmdOk) {
        Write-Host "READY: both markers present after $elapsed seconds."
        exit 0
    }
    # Show some hints about what is happening
    if (Test-Path 'C:\Java') {
        $jdkContents = (Get-ChildItem 'C:\Java' -Force -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name) -join ','
        Write-Host "  C:\Java contents: $jdkContents"
    }
    if (Test-Path 'C:\Android') {
        $androidContents = (Get-ChildItem 'C:\Android' -Force -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name) -join ','
        Write-Host "  C:\Android contents: $androidContents"
    }
    Start-Sleep -Seconds 30
}

Write-Host "TIMEOUT: still missing after $maxIterations iterations (~30 min)"
Write-Host "  JDK marker: $jdkMarker -> $(Test-Path $jdkMarker)"
Write-Host "  CMDLINE marker: $cmdMarker -> $(Test-Path $cmdMarker)"
exit 1
