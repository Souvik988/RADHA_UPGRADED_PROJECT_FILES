@echo off
set "JAVA_HOME=C:\Java\jdk-17"
set "PATH=C:\Java\jdk-17\bin;%PATH%"
echo JAVA_HOME=[%JAVA_HOME%]
if exist "%JAVA_HOME%\bin\java.exe" (echo java.exe FOUND) else (echo java.exe MISSING)
"C:\Android\cmdline-tools\latest\bin\sdkmanager.bat" --version
echo EXITCODE=%errorlevel%
