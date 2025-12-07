@echo off
echo ============================================
echo    Windows System Cleanup Script
echo ============================================
echo.
echo This script will clean up temporary files and system cache.
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

echo Starting cleanup process...
echo.

:: Clean Windows Temp folder
echo [1/7] Cleaning Windows Temp folder...
del /q /f /s "%TEMP%\*" 2>nul
for /d %%p in ("%TEMP%\*") do rmdir "%%p" /s /q 2>nul
echo Done.

:: Clean System Temp folder
echo [2/7] Cleaning System Temp folder...
del /q /f /s "C:\Windows\Temp\*" 2>nul
for /d %%p in ("C:\Windows\Temp\*") do rmdir "%%p" /s /q 2>nul
echo Done.

:: Clean Prefetch
echo [3/7] Cleaning Prefetch...
del /q /f /s "C:\Windows\Prefetch\*" 2>nul
echo Done.

:: Clean Windows Update Cache
echo [4/7] Cleaning Windows Update Cache...
net stop wuauserv >nul 2>&1
del /q /f /s "C:\Windows\SoftwareDistribution\Download\*" 2>nul
for /d %%p in ("C:\Windows\SoftwareDistribution\Download\*") do rmdir "%%p" /s /q 2>nul
net start wuauserv >nul 2>&1
echo Done.

:: Clean Recycle Bin
echo [5/7] Emptying Recycle Bin...
rd /s /q %systemdrive%\$Recycle.bin 2>nul
echo Done.

:: Clean Browser Caches (Edge, Chrome)
echo [6/7] Cleaning Browser Caches...
:: Edge Cache
del /q /f /s "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Cache\*" 2>nul
for /d %%p in ("%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Cache\*") do rmdir "%%p" /s /q 2>nul

:: Chrome Cache
del /q /f /s "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Cache\*" 2>nul
for /d %%p in ("%LOCALAPPDATA%\Google\Chrome\User Data\Default\Cache\*") do rmdir "%%p" /s /q 2>nul
echo Done.

:: Clean Windows Error Reports
echo [7/7] Cleaning Windows Error Reports...
del /q /f /s "C:\ProgramData\Microsoft\Windows\WER\ReportQueue\*" 2>nul
for /d %%p in ("C:\ProgramData\Microsoft\Windows\WER\ReportQueue\*") do rmdir "%%p" /s /q 2>nul
echo Done.



echo.
echo ============================================
echo    Cleanup Complete!
echo ============================================
echo.
echo Your system has been cleaned up successfully.
echo You may need to restart your computer for all changes to take effect.
echo.
pause
