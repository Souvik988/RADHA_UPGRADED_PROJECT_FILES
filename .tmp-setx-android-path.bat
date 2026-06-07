@echo off
setlocal EnableExtensions

REM Read current USER PATH (HKCU\Environment\Path) into USERPATH, leaving system PATH alone.
set "USERPATH="
for /f "skip=2 tokens=2,*" %%A in ('reg query "HKCU\Environment" /v Path 2^>nul') do set "USERPATH=%%B"

REM Build NEW additions
set "ADD1=C:\Android\cmdline-tools\latest\bin"
set "ADD2=C:\Android\platform-tools"
set "ADD3=C:\Android\emulator"

set "NEWPATH=%USERPATH%"
if defined NEWPATH (
  echo ;%NEWPATH%; | findstr /I /C:";%ADD1%;" >nul || set "NEWPATH=%NEWPATH%;%ADD1%"
  echo ;%NEWPATH%; | findstr /I /C:";%ADD2%;" >nul || set "NEWPATH=%NEWPATH%;%ADD2%"
  echo ;%NEWPATH%; | findstr /I /C:";%ADD3%;" >nul || set "NEWPATH=%NEWPATH%;%ADD3%"
) else (
  set "NEWPATH=%ADD1%;%ADD2%;%ADD3%"
)

echo Updating USER PATH to:
echo %NEWPATH%

setx PATH "%NEWPATH%"
endlocal
