@echo off
echo ============================================
echo    Icon Cache Rebuild
echo ============================================
echo.

echo This script will rebuild the Windows icon cache.
echo This fixes corrupted or missing desktop icons.
echo.
echo Your desktop icons will refresh after this process.
echo.
pause

echo.
echo Rebuilding icon cache...
echo.

:: Stop Windows Explorer
echo [1/4] Stopping Windows Explorer...
taskkill /f /im explorer.exe >nul 2>&1
echo Done.

:: Delete icon cache files
echo [2/4] Deleting icon cache files...
cd /d %userprofile%\AppData\Local\Microsoft\Windows\Explorer
attrib -h IconCache.db >nul 2>&1
del IconCache.db /f /q >nul 2>&1
del iconcache_*.db /f /q >nul 2>&1
del thumbcache_*.db /f /q >nul 2>&1
echo Done.

:: Clear thumbnail cache
echo [3/4] Clearing thumbnail cache...
del /f /s /q /a %LocalAppData%\Microsoft\Windows\Explorer\thumbcache_*.db >nul 2>&1
echo Done.

:: Restart Windows Explorer
echo [4/4] Restarting Windows Explorer...
start explorer.exe
echo Done.

echo.
echo ============================================
echo    Icon Cache Rebuilt!
echo ============================================
echo.
echo Your icon cache has been successfully rebuilt.
echo.
echo Changes applied:
echo [✓] Icon cache cleared
echo [✓] Thumbnail cache cleared
echo [✓] Windows Explorer restarted
echo.
echo Your desktop icons should now display correctly!
echo If icons still look wrong, try restarting your PC.
echo.
pause
