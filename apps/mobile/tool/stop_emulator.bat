@echo off
setlocal

rem RADHA mobile - clean shutdown for the Android emulator started by
rem start_emulator.bat. Tries the graceful adb path first; if adb is
rem hung or unresponsive, falls back to taskkill on emulator.exe.

echo.
echo ============================================
echo  RADHA Mobile - stop Android emulator
echo ============================================
echo.

set "ANDROID_HOME=C:\Android"
set "PATH=%ANDROID_HOME%\platform-tools;%PATH%"

rem [1/2] Graceful: ask the emulator to power down via adb.
echo [1/2] Sending "emu kill" to emulator-5554 via adb ...
if not exist "%ANDROID_HOME%\platform-tools\adb.exe" (
    echo WARNING: adb.exe not found at %ANDROID_HOME%\platform-tools\adb.exe
    echo          Skipping graceful shutdown, going straight to taskkill.
    goto taskkill
)
"%ANDROID_HOME%\platform-tools\adb.exe" -s emulator-5554 emu kill
if errorlevel 1 (
    echo   adb emu kill returned a non-zero exit code; will fall back.
) else (
    echo   adb emu kill issued.
)

rem Give the emulator process a few seconds to exit cleanly.
timeout /t 5 /nobreak >nul

tasklist /FI "IMAGENAME eq emulator.exe" 2>nul | find /I "emulator.exe" >nul
if errorlevel 1 (
    echo   emulator.exe is no longer running. Done.
    endlocal & exit /b 0
)

:taskkill
rem [2/2] Fallback: force-kill emulator.exe if it's still around.
echo [2/2] Forcing taskkill on emulator.exe ...
taskkill /F /IM emulator.exe >nul 2>&1
if errorlevel 1 (
    echo WARNING: taskkill could not find emulator.exe. It may already be gone.
    endlocal & exit /b 0
)

echo   emulator.exe terminated.
endlocal & exit /b 0
