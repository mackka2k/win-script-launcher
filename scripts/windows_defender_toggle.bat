@echo off
setlocal EnableExtensions
title Windows Defender Toggle

set "SCRIPT_BACKUP_TARGETS=defender"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0assets\common_backup.ps1" -ScriptName "%~nx0" -Targets %SCRIPT_BACKUP_TARGETS%
if errorlevel 1 (
    echo [!] Backup guard failed.
    choice /C YN /N /M "Continue without backup? (Y/N): "
    if errorlevel 2 exit /b 1
)

echo ============================================
echo    Windows Defender Toggle
echo ============================================
echo.
echo This script allows you to enable or disable Windows Defender.
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

:menu
echo.
echo Checking current status...
echo.

:: Check current status
powershell -NoProfile -File "%~dp0assets\windows_defender_toggle_inline_1.ps1"

echo.
echo ============================================
echo    Options:
echo ============================================
echo.
echo 1. Disable Windows Defender (Real-time Protection)
echo 2. Enable Windows Defender (Real-time Protection)
echo 3. Disable All Protection (Real-time, Cloud, Samples)
echo 4. Enable All Protection (Full protection)
echo 5. Check Defender Status
echo 6. Exit
echo.
set /p choice="Enter your choice (1-6): "

if "%choice%"=="1" goto disable
if "%choice%"=="2" goto enable
if "%choice%"=="3" goto disableall
if "%choice%"=="4" goto enableall
if "%choice%"=="5" goto status
if "%choice%"=="6" goto end

echo Invalid choice. Please try again.
goto menu

:disable
echo.
echo Disabling Real-time Protection...
powershell -Command "Set-MpPreference -DisableRealtimeMonitoring $true" 2>nul
if %errorLevel% equ 0 (
    echo.
    echo Real-time Protection DISABLED successfully!
    echo.
    echo WARNING: Your computer is now less protected.
) else (
    echo.
    echo ERROR: Failed to disable. You may need to disable Tamper Protection first.
    echo Go to: Windows Security ^> Virus ^& threat protection ^> Manage settings
)
goto menu

:enable
echo.
echo Enabling Real-time Protection...
powershell -Command "Set-MpPreference -DisableRealtimeMonitoring $false" 2>nul
echo.
echo Real-time Protection ENABLED successfully!
goto menu

:disableall
echo.
echo Disabling ALL Windows Defender protection...
echo.
echo WARNING: This will disable all protection features!
set /p confirm="Are you sure? (Y/N): "
if /i not "%confirm%"=="Y" goto menu

powershell -NoProfile -File "%~dp0assets\windows_defender_toggle_inline_2.ps1" 2>nul

if %errorLevel% equ 0 (
    echo.
    echo All protection features DISABLED!
) else (
    echo.
    echo ERROR: Some features could not be disabled.
    echo You may need to disable Tamper Protection first.
)
goto menu

:enableall
echo.
echo Enabling ALL Windows Defender protection...
powershell -NoProfile -File "%~dp0assets\windows_defender_toggle_inline_3.ps1" 2>nul
echo.
echo All protection features ENABLED!
goto menu

:status
echo.
echo Detailed Status:
echo.
powershell -NoProfile -File "%~dp0assets\windows_defender_toggle_inline_4.ps1"
goto menu

:end
echo.
echo Exiting...
pause
