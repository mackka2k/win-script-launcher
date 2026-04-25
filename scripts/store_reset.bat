@echo off
setlocal EnableExtensions
title Store Reset

set "SCRIPT_BACKUP_TARGETS=appx"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0assets\common_backup.ps1" -ScriptName "%~nx0" -Targets %SCRIPT_BACKUP_TARGETS%
if errorlevel 1 (
    echo [!] Backup guard failed.
    choice /C YN /N /M "Continue without backup? (Y/N): "
    if errorlevel 2 exit /b 1
)

echo ============================================
echo    Windows Store Reset
echo ============================================
echo.

echo This script will reset the Microsoft Store.
echo This fixes download issues and Store errors.
echo.
echo The Store will close and reopen automatically.
echo.
pause

echo.
echo Resetting Microsoft Store...
echo.

:: Reset Windows Store
echo [1/3] Resetting Microsoft Store app...
wsreset.exe
echo Done.

:: Clear Store cache
echo [2/3] Clearing Store cache...
powershell -Command "Get-AppxPackage *WindowsStore* | Reset-AppxPackage" >nul 2>&1
echo Done.

:: Re-register Store
echo [3/3] Re-registering Microsoft Store...
powershell -Command "Get-AppxPackage *WindowsStore* | Foreach {Add-AppxPackage -DisableDevelopmentMode -Register \"$($_.InstallLocation)\AppXManifest.xml\"}" >nul 2>&1
echo Done.

echo.
echo ============================================
echo    Store Reset Complete!
echo ============================================
echo.
echo The Microsoft Store has been reset.
echo.
echo Changes applied:
echo [OK] Store cache cleared
echo [OK] Store app reset
echo [OK] Store re-registered
echo.
echo The Store should now work properly!
echo Try downloading apps again.
echo.
pause
