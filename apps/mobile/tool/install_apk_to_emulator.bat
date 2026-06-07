@echo off
setlocal

rem RADHA mobile - build, install, and launch the debug APK on a running
rem Android emulator. Assumes start_emulator.bat has already booted the
rem RadhaPixel AVD and adb reports it as "device".
rem
rem API base URL is hard-pinned to http://10.0.2.2:3000/api/v1 - that's
rem the emulator's loopback alias for the host's localhost where the
rem NestJS backend runs (pnpm server:dev on port 3000).
rem
rem Launch component is com.radha.radha_mobile/.MainActivity, derived
rem from android/app/build.gradle.kts (applicationId) and AndroidManifest
rem (the only exported activity).

echo.
echo ============================================
echo  RADHA Mobile - install APK to emulator
echo ============================================
echo.

set "JAVA_HOME=C:\Java\jdk-17"
set "ANDROID_HOME=C:\Android"
set "FLUTTER_BAT=C:\src\flutter\bin\flutter.bat"
set "PACKAGE=com.radha.radha_mobile"
set "ACTIVITY=%PACKAGE%/.MainActivity"
set "APK_PATH=build\app\outputs\flutter-apk\app-debug.apk"
set "API_BASE_URL=http://10.0.2.2:3000/api/v1"

set "PATH=%ANDROID_HOME%\platform-tools;%ANDROID_HOME%\cmdline-tools\latest\bin;%ANDROID_HOME%\emulator;%PATH%"

rem Move to apps\mobile (this script lives at apps\mobile\tool\install_apk_to_emulator.bat).
pushd "%~dp0\.."
if errorlevel 1 (
    echo ERROR: could not cd into apps\mobile.
    exit /b 1
)

rem [1/4] Verify an emulator is attached
echo [1/4] Checking adb for an attached device ...
"%ANDROID_HOME%\platform-tools\adb.exe" get-state >nul 2>&1
if errorlevel 1 (
    echo ERROR: no device reported by adb. Run start_emulator.bat first.
    popd
    exit /b 1
)
echo   Device attached.

rem [2/4] Build the debug APK with the emulator-friendly API base URL
echo [2/4] Building debug APK (--dart-define=API_BASE_URL=%API_BASE_URL%) ...
if not exist "%FLUTTER_BAT%" (
    echo ERROR: Flutter not found at %FLUTTER_BAT%. Update this script if your SDK lives elsewhere.
    popd
    exit /b 1
)
"%FLUTTER_BAT%" build apk --debug --dart-define=API_BASE_URL=%API_BASE_URL%
if errorlevel 1 (
    echo ERROR: flutter build apk failed. See output above.
    popd
    exit /b 1
)
if not exist "%APK_PATH%" (
    echo ERROR: expected APK at %APK_PATH% but it was not produced.
    popd
    exit /b 1
)
echo   APK built: %APK_PATH%

rem [3/4] Install (replacing any existing copy)
echo [3/4] Installing APK on emulator (adb install -r) ...
"%ANDROID_HOME%\platform-tools\adb.exe" install -r "%APK_PATH%"
if errorlevel 1 (
    echo ERROR: adb install failed. See output above.
    popd
    exit /b 1
)
echo   Install OK.

rem [4/4] Launch the app
echo [4/4] Launching %ACTIVITY% ...
"%ANDROID_HOME%\platform-tools\adb.exe" shell am start -n %ACTIVITY%
if errorlevel 1 (
    echo ERROR: adb shell am start failed.
    popd
    exit /b 1
)

echo.
echo App launched. Drive the smoke checklist via mobile-mcp:
echo   mcp_mobile_mcp_mobile_take_screenshot
echo   mcp_mobile_mcp_mobile_list_elements_on_screen
echo.

popd
endlocal & exit /b 0
