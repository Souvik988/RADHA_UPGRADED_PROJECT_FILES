# Run once as Administrator to add Flutter to system PATH permanently
$flutterBin = "C:\src\flutter\bin"
$machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
if ($machinePath -notlike "*$flutterBin*") {
    [Environment]::SetEnvironmentVariable("Path", "$machinePath;$flutterBin", "Machine")
    Write-Host "SUCCESS: Flutter added to SYSTEM PATH" -ForegroundColor Green
    Write-Host "Flutter will work in ALL new terminals from now on." -ForegroundColor Green
} else {
    Write-Host "Flutter already on SYSTEM PATH." -ForegroundColor Yellow
}
flutter --version
