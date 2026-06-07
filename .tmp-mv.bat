@echo off
cd /d "c:\Users\sayan\Downloads\RADHA_UPGRADED_PROJECT_FILES new\RADHA_UPGRADED_PROJECT_FILES"
if not exist "assets\v2\mockup" mkdir "assets\v2\mockup"
move /y "assets\mockups\%~1" "assets\v2\mockup\%~2"
echo DONE_%ERRORLEVEL%
