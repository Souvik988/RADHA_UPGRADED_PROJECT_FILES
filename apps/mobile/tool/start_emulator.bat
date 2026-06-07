@echo off
setlocal

rem RADHA mobile - Android emulator launcher.
rem Boots the RadhaPixel AVD in the background and waits for adb to report
rem the device as "device" (not "offline"). Pairs with mobile-mcp + the
rem mcp_mobile_mcp_* tools used by the Option D smoke test path.
rem
rem Prereqs: JDK 17 at C:\Java\jdk-17, Android SDK at C:\Android, an AVD
rem named "RadhaPixel". See ANDROID_SETUP_TROUBLESHOOTING.md if anything
rem below fails.

echo.
echo ============================================
echo  RADHA Mobile - Android emulator launcher
echo ============================================
echo.

set "JAVA_HOME=C:\Java\jdk-17"
set "ANDROID_HOME=C:\Android"
set "AVD_NAME=RadhaPixel"
set "WAIT_SECS=120"

rem [1/4] Validate JAVA_HOME
echo [1/4] Checking JAVA_HOME at %JAVA_HOME% ...
if not exist "%JAVA_HOME%\bin\java.exe" (
    echo ERROR: java.exe not found at %JAVA_HOME%\bin\java.exe
    echo        Install JDK 17 to C:\Java\jdk-17 or update this script.
    echo        See ANDROID_SETUP_TROUBLESHOOTING.md for the install steps.
    exit /b 1
)
echo   JAVA_HOME OK.

rem [2/4] Validate ANDROID_HOME and core SDK folders
echo [2/4] Checking ANDROID_HOME at %ANDROID_HOME% ...
if not exist "%ANDROID_HOME%\platform-tools\adb.exe" (
    echo ERROR: adb.exe not found at %ANDROID_HOME%\platform-tools\adb.exe
    echo        Install Android SDK platform-tools under C:\Android.
    echo        See ANDROID_SETUP_TROUBLESHOOTING.md.
    exit /b 1
)
if not exist "%ANDROID_HOME%\emulator\emulator.exe" (
    echo ERROR: emulator.exe not found at %ANDROID_HOME%\emulator\emulator.exe
    echo        Install the Android SDK "emulator" package via sdkmanager.
    echo        See ANDROID_SETUP_TROUBLESHOOTING.md.
    exit /b 1
)
if not exist "%ANDROID_HOME%\cmdline-tools\latest\bin" (
    echo WARNING: cmdline-tools\latest\bin missing - sdkmanager/avdmanager unavailable.
    echo          See ANDROID_SETUP_TROUBLESHOOTING.md to finish the SDK setup.
)
echo   ANDROID_HOME OK.

set "PATH=%ANDROID_HOME%\platform-tools;%ANDROID_HOME%\cmdline-tools\latest\bin;%ANDROID_HOME%\emulator;%PATH%"

rem [3/4] Boot the AVD in the background
echo [3/4] Booting AVD "%AVD_NAME%" in the background ...
start /B "" "%ANDROID_HOME%\emulator\emulator.exe" -avd %AVD_NAME% -no-snapshot-save -no-audio
if errorlevel 1 (
    echo ERROR: failed to launch emulator.exe.
    exit /b 1
)

rem [4/4] Wait for adb to report the device as "device"
echo [4/4] Waiting up to %WAIT_SECS%s for adb to report a "device" status ...
set /a ELAPSED=0
:waitloop
for /f "skip=1 tokens=1,2" %%a in ('"%ANDROID_HOME%\platform-tools\adb.exe" devices') do (
    if /I "%%b"=="device" (
        echo.
        echo Emulator is up.
        echo   device-id: %%a
        echo   API base URL for app: http://10.0.2.2:3000/api/v1
        echo.
        echo Next: run apps\mobile\tool\install_apk_to_emulator.bat
        endlocal & exit /b 0
    )
)
timeout /t 3 /nobreak >nul
set /a ELAPSED+=3
if %ELAPSED% LSS %WAIT_SECS% goto waitloop

echo ERROR: emulator did not reach "device" status within %WAIT_SECS%s.
echo        Check the emulator window or run: adb devices
echo        See ANDROID_SETUP_TROUBLESHOOTING.md for recovery steps.
endlocal & exit /b 2
