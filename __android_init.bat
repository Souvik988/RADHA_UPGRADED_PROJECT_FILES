@echo off
setlocal
rem Android cmdline-tools bootstrap. Lays out:
rem   C:\Android\
rem     cmdline-tools\latest\
rem       bin\sdkmanager.bat   (entry point)
rem       lib\
rem     platform-tools\        (adb, fastboot)        [installed by sdkmanager]
rem     emulator\              (emulator binary)      [installed by sdkmanager]
rem     platforms\android-34\  (compile SDK)          [installed by sdkmanager]
rem     build-tools\34.0.0\    (aapt, zipalign)       [installed by sdkmanager]
rem     system-images\android-34\google_apis\x86_64\  (emulator image, ~1.0 GB)

set ANDROID_HOME=C:\Android
set CMD_TOOLS_DIR=%ANDROID_HOME%\cmdline-tools
set CMD_TOOLS_LATEST=%CMD_TOOLS_DIR%\latest
set CMD_TOOLS_ZIP=%TEMP%\android-cmdline-tools.zip
set CMD_TOOLS_URL=https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip

if not exist "%ANDROID_HOME%" mkdir "%ANDROID_HOME%"
if not exist "%CMD_TOOLS_DIR%" mkdir "%CMD_TOOLS_DIR%"

if exist "%CMD_TOOLS_LATEST%\bin\sdkmanager.bat" (
  echo CMDLINE_TOOLS_ALREADY_INSTALLED
  goto :verify
)

echo Downloading Android command-line tools from %CMD_TOOLS_URL%
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri '%CMD_TOOLS_URL%' -OutFile '%CMD_TOOLS_ZIP%'"
if not exist "%CMD_TOOLS_ZIP%" (
  echo DOWNLOAD_FAILED
  exit /b 1
)

echo Expanding into %CMD_TOOLS_DIR%
powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -Path '%CMD_TOOLS_ZIP%' -DestinationPath '%CMD_TOOLS_DIR%' -Force"
if not exist "%CMD_TOOLS_DIR%\cmdline-tools" (
  echo EXPAND_FAILED
  exit /b 1
)

rem Google ships the zip as 'cmdline-tools/...' but Flutter expects 'cmdline-tools/latest/...'
move "%CMD_TOOLS_DIR%\cmdline-tools" "%CMD_TOOLS_LATEST%" >nul

del "%CMD_TOOLS_ZIP%" >nul 2>&1

:verify
echo.
echo Verifying installation...
"%CMD_TOOLS_LATEST%\bin\sdkmanager.bat" --version
echo CMDLINE_TOOLS_DONE
endlocal
