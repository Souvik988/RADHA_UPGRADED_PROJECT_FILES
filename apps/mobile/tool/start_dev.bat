@echo off
setlocal

rem RADHA mobile - convenience launcher for Chrome dev runs.
rem Run from any directory; this script cd's into apps\mobile relative to itself.

echo.
echo ============================================
echo  RADHA Mobile - dev launcher (Flutter Web)
echo ============================================
echo.

rem [1/3] Docker check
echo [1/3] Checking Docker...
docker ps >nul 2>&1
if errorlevel 1 (
    echo ERROR: Docker is not running. Start Docker Desktop and retry.
    exit /b 1
)
echo   Docker OK.
echo.

rem [2/3] Reminder: Postgres 5433 + Redis 6380
echo [2/3] Make sure Postgres 5433 + Redis 6380 are up:
echo     cd ..\..  ^&^&  docker compose up -d
echo.

rem [3/3] Reminder: backend on :3000
echo [3/3] Make sure the NestJS backend is running on http://localhost:3000:
echo     cd ..\..  ^&^&  pnpm server:dev
echo.

echo If those are ready, starting Flutter on Chrome now...
echo.

rem Move to apps\mobile (this script lives at apps\mobile\tool\start_dev.bat).
pushd "%~dp0\.."
if errorlevel 1 (
    echo ERROR: could not cd into apps\mobile.
    exit /b 1
)

rem Verify Flutter is available at the expected path.
if not exist "C:\src\flutter\bin\flutter.bat" (
    echo ERROR: Flutter not found at C:\src\flutter\bin\flutter.bat
    echo Update this script if your Flutter SDK lives elsewhere.
    popd
    exit /b 1
)

"C:\src\flutter\bin\flutter.bat" run -d chrome --dart-define=API_BASE_URL=http://localhost:3000/api/v1
set FLUTTER_EXIT=%errorlevel%

popd
endlocal & exit /b %FLUTTER_EXIT%
