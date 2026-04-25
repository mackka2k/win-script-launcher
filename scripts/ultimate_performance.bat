@echo off
setlocal EnableExtensions
title Ultimate Performance Plan Activator
chcp 65001 >nul 2>&1


set "SCRIPT_BACKUP_TARGETS=power"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0assets\common_backup.ps1" -ScriptName "%~nx0" -Targets %SCRIPT_BACKUP_TARGETS%
if errorlevel 1 (
    echo [!] Backup guard failed.
    choice /C YN /N /M "Continue without backup? (Y/N): "
    if errorlevel 2 exit /b 1
)

echo ============================================
echo   Ultimate Performance Plan Activator
echo ============================================
echo.

:: Simple execution using PowerShell for better stability
powershell -File "%~dp0assets\ultimate_performance_inline_1.ps1"

echo.
echo ============================================
echo   Process Finished.
echo ============================================
echo.
pause
exit /b
