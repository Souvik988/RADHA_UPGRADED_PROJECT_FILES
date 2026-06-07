@echo off
setlocal
set JAVA_HOME=C:\Java\jdk-17
set ANDROID_HOME=C:\Android
set ANDROID_SDK_ROOT=C:\Android
set PATH=%JAVA_HOME%\bin;C:\Android\platform-tools;C:\Android\cmdline-tools\latest\bin;C:\Android\emulator;%PATH%
cd /d "c:\Users\sayan\Downloads\RADHA_UPGRADED_PROJECT_FILES new\RADHA_UPGRADED_PROJECT_FILES\apps\mobile"
echo === JAVA: ===
java -version 2>&1
echo === FLUTTER BUILD ===
C:\src\flutter\bin\flutter.bat build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1
echo === EXIT %ERRORLEVEL% ===
