@echo off
setlocal EnableExtensions
title Path Cleaner

set "SCRIPT_BACKUP_TARGETS=path"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0assets\common_backup.ps1" -ScriptName "%~nx0" -Targets %SCRIPT_BACKUP_TARGETS%
if errorlevel 1 (
    echo [!] Backup guard failed.
    choice /C YN /N /M "Continue without backup? (Y/N): "
    if errorlevel 2 exit /b 1
)

echo ============================================
echo    PATH Environment Variable Cleaner
echo ============================================
echo.
echo This script will clean duplicate and invalid entries from PATH.
echo Administrator privileges are required.
echo.

:: Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: This script requires administrator privileges.
    echo Please run as administrator.
    pause
    exit /b 1
)

echo Creating backup of current PATH...
echo.

:: Backup current PATH to a file
for /f "tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path') do set "CURRENT_PATH=%%b"
echo %CURRENT_PATH% > "%TEMP%\path_backup.txt"
echo Backup saved to: %TEMP%\path_backup.txt
echo.

echo Analyzing PATH variable...
echo.

:: Use PowerShell with a script block
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0assets\path_cleaner_inline_1.ps1"

echo.
echo ============================================
echo    PATH Cleaner Complete!
echo ============================================
echo.
echo Note: You may need to restart applications for changes to take effect.
echo.
pause
