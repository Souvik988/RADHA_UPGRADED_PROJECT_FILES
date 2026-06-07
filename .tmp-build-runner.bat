@echo off
setlocal
set JAVA_HOME=C:\Java\jdk-17
set ANDROID_HOME=C:\Android
set ANDROID_SDK_ROOT=C:\Android
set PATH=%JAVA_HOME%\bin;C:\Android\platform-tools;C:\Android\cmdline-tools\latest\bin;C:\Android\emulator;%PATH%
cd /d "c:\Users\sayan\Downloads\RADHA_UPGRADED_PROJECT_FILES new\RADHA_UPGRADED_PROJECT_FILES\apps\mobile"
echo === BUILD RUNNER ===
C:\src\flutter\bin\dart.bat run build_runner build --delete-conflicting-outputs
echo === EXIT %ERRORLEVEL% ===
