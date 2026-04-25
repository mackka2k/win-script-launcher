@echo off
setlocal EnableExtensions
title Search Rebuild

set "SCRIPT_BACKUP_TARGETS=registry files"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0assets\common_backup.ps1" -ScriptName "%~nx0" -Targets %SCRIPT_BACKUP_TARGETS%
if errorlevel 1 (
    echo [!] Backup guard failed.
    choice /C YN /N /M "Continue without backup? (Y/N): "
    if errorlevel 2 exit /b 1
)

echo ============================================
echo    Windows Search Rebuild
echo ============================================
echo.

:: Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: This script requires administrator privileges!
    echo Please run as Administrator.
    echo.
    pause
    exit /b 1
)

echo This script will rebuild the Windows Search index.
echo This fixes search not working and improves search speed.
echo.
echo WARNING: This process may take several minutes.
echo The search index will be rebuilt in the background.
echo.
pause

echo.
echo Rebuilding Windows Search index...
echo.

:: Stop Windows Search service
echo [1/5] Stopping Windows Search service...
net stop WSearch >nul 2>&1
echo Done.

:: Delete search index files
echo [2/5] Deleting old search index...
del /f /s /q "%ProgramData%\Microsoft\Search\Data\Applications\Windows\Windows.edb" >nul 2>&1
rd /s /q "%ProgramData%\Microsoft\Search\Data\Applications\Windows" >nul 2>&1
echo Done.

:: Reset search settings
echo [3/5] Resetting search settings...
reg delete "HKLM\SOFTWARE\Microsoft\Windows Search" /v SetupCompletedSuccessfully /f >nul 2>&1
echo Done.

:: Restart Windows Search service
echo [4/5] Restarting Windows Search service...
net start WSearch >nul 2>&1
echo Done.

:: Trigger index rebuild
echo [5/5] Triggering index rebuild...
powershell -File "%~dp0assets\search_rebuild_inline_1.ps1" >nul 2>&1
echo Done.

echo.
echo ============================================
echo    Search Index Rebuild Started!
echo ============================================
echo.
echo The Windows Search index is being rebuilt.
echo.
echo Changes applied:
echo [OK] Search service restarted
echo [OK] Old index deleted
echo [OK] Search settings reset
echo [OK] Index rebuild triggered
echo.
echo The rebuild will continue in the background.
echo This may take 15-30 minutes depending on your files.
echo.
echo Search functionality will improve as indexing progresses.
echo You can check indexing status in: Settings ^> Search ^> Searching Windows
echo.
pause
