@echo off
setlocal
set ADB=C:\Android\platform-tools\adb.exe
set NAME=%~1
if "%NAME%"=="" set NAME=current
%ADB% -s emulator-5554 shell screencap -p /sdcard/_radha.png >nul 2>&1
%ADB% -s emulator-5554 pull /sdcard/_radha.png "c:\Users\sayan\Downloads\RADHA_UPGRADED_PROJECT_FILES new\RADHA_UPGRADED_PROJECT_FILES\.tmp-shots\%NAME%.png" >nul 2>&1
echo SAVED .tmp-shots\%NAME%.png
