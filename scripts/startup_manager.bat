@echo off
setlocal EnableDelayedExpansion
title Ultimate Startup Manager

echo ============================================
echo    Ultimate Startup Manager
echo ============================================
echo.
echo [1/2] Vykdomas pilnas auditas...
echo.

:: Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] WARNING: Not running as Administrator.
    echo Some system-wide entries may be hidden.
    echo.
)

:: PowerShell logic to perform audit AND provide cleaning interface
powershell -File "%~dp0assets\startup_manager_inline_1.ps1"

echo.
echo ============================================
echo    Procesas baigtas.
echo ============================================
echo Atnaujinkite sarasa, jei norite matyti pokycius.
echo.
pause
exit /b
