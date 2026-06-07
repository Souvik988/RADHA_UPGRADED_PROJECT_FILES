@echo off
set ADB=C:\Android\platform-tools\adb.exe
set APK=c:\Users\sayan\Downloads\RADHA_UPGRADED_PROJECT_FILES new\RADHA_UPGRADED_PROJECT_FILES\apps\mobile\build\app\outputs\flutter-apk\app-debug.apk
echo Installing "%APK%"
"%ADB%" install -r "%APK%"
echo === EXIT %ERRORLEVEL% ===
