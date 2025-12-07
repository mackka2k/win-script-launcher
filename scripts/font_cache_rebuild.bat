@echo off
echo ============================================
echo    Font Cache Rebuild
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

echo This script will rebuild the Windows font cache.
echo This fixes font rendering and display issues.
echo.
pause

echo.
echo Rebuilding font cache...
echo.

:: Stop font cache service
echo [1/5] Stopping Windows Font Cache Service...
net stop FontCache >nul 2>&1
echo Done.

:: Delete font cache files
echo [2/5] Deleting font cache files...
del /f /s /q "%WinDir%\ServiceProfiles\LocalService\AppData\Local\FontCache\*.*" >nul 2>&1
del /f /q "%WinDir%\System32\FNTCACHE.DAT" >nul 2>&1
echo Done.

:: Clear font cache from user profile
echo [3/5] Clearing user font cache...
del /f /s /q "%LocalAppData%\Microsoft\Windows\Fonts\*.*" >nul 2>&1
echo Done.

:: Restart font cache service
echo [4/5] Restarting Windows Font Cache Service...
net start FontCache >nul 2>&1
echo Done.

:: Restart Windows Explorer
echo [5/5] Restarting Windows Explorer...
taskkill /f /im explorer.exe >nul 2>&1
start explorer.exe
echo Done.

echo.
echo ============================================
echo    Font Cache Rebuilt!
echo ============================================
echo.
echo Your font cache has been successfully rebuilt.
echo.
echo Changes applied:
echo [✓] Font cache service restarted
echo [✓] Font cache files deleted
echo [✓] User font cache cleared
echo [✓] Windows Explorer restarted
echo.
echo Font rendering should now be fixed!
echo Restart your PC if issues persist.
echo.
pause
