@echo off
cd /d "%~dp0"

echo ========================================
echo Installing Context Menu Tool
echo ========================================
echo.

REM Check for admin rights
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: Administrator privileges required!
    echo Please right-click this script and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

powershell -ExecutionPolicy Bypass -File "%~dp0install.ps1"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Installation failed!
    pause
    exit /b 1
)

echo.
pause
