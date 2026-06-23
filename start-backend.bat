@echo off
title RADHA Backend Server
echo ============================================
echo   RADHA Backend API - Starting...
echo ============================================
echo.

cd /d "%~dp0radha_backend"

echo [1/2] Checking dependencies...
call pnpm install 2>nul || echo (deps already up to date)
echo.

echo [2/2] Starting RADHA API on http://localhost:3000/api/v1
echo.
echo Press Ctrl+C to stop the server.
echo ============================================
echo.

set NODE_ENV=development
set TS_NODE_TRANSPILE_ONLY=1
node -r ts-node/register/transpile-only -r tsconfig-paths/register src/main.api.ts

echo.
echo Server stopped. Press any key to close.
pause >nul
