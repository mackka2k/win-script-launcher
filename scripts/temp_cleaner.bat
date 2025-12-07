@echo off
echo ============================================
echo    Temporary Files Cleaner
echo ============================================
echo.
echo This script will clean all temporary files from your system.
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

echo Starting temporary files cleanup...
echo.

:: Clean User Temp folder
echo [1/5] Cleaning User Temp folder...
del /q /f /s "%TEMP%\*" 2>nul
for /d %%p in ("%TEMP%\*") do rmdir "%%p" /s /q 2>nul
echo Done.

:: Clean System Temp folder
echo [2/5] Cleaning System Temp folder...
del /q /f /s "C:\Windows\Temp\*" 2>nul
for /d %%p in ("C:\Windows\Temp\*") do rmdir "%%p" /s /q 2>nul
echo Done.

:: Clean Prefetch
echo [3/5] Cleaning Prefetch folder...
del /q /f /s "C:\Windows\Prefetch\*" 2>nul
echo Done.

:: Clean Recent Items
echo [4/5] Cleaning Recent Items...
del /q /f /s "%APPDATA%\Microsoft\Windows\Recent\*" 2>nul
for /d %%p in ("%APPDATA%\Microsoft\Windows\Recent\*") do rmdir "%%p" /s /q 2>nul
echo Done.

:: Clean Thumbnail Cache
echo [5/5] Cleaning Thumbnail Cache...
del /q /f /s "%LOCALAPPDATA%\Microsoft\Windows\Explorer\thumbcache_*.db" 2>nul
echo Done.

echo.
echo ============================================
echo    Cleanup Complete!
echo ============================================
echo.
echo All temporary files have been cleaned successfully.
echo.
pause
