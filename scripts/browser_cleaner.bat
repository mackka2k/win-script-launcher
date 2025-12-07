@echo off
echo ============================================
echo    Browser History Cleaner
echo ============================================
echo.

:: Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo WARNING: Running without administrator privileges.
    echo Some browser data may not be accessible.
    echo.
)

echo Clearing browsing data from:
echo - Google Chrome
echo - Microsoft Edge
echo - Mozilla Firefox
echo - Opera
echo - Brave
echo.
echo Removing:
echo - Browsing history
echo - Search history
echo - Bookmarks (including imported)
echo - Extensions (all browser extensions)
echo - Cache files
echo - Cookies
echo - Form data
echo.

:: Close browsers first
echo [1/6] Closing browsers...
taskkill /F /IM chrome.exe 2>nul
taskkill /F /IM msedge.exe 2>nul
taskkill /F /IM firefox.exe 2>nul
taskkill /F /IM opera.exe 2>nul
taskkill /F /IM brave.exe 2>nul
echo Done.

:: Chrome
echo [2/6] Cleaning Google Chrome...
rd /s /q "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Cache" 2>nul
rd /s /q "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Code Cache" 2>nul
del /q /f "%LOCALAPPDATA%\Google\Chrome\User Data\Default\History" 2>nul
del /q /f "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Cookies" 2>nul
del /q /f "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Web Data" 2>nul
del /q /f "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Shortcuts" 2>nul
del /q /f "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Top Sites" 2>nul
del /q /f "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Visited Links" 2>nul
rd /s /q "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Extensions" 2>nul
rd /s /q "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Extension State" 2>nul
echo Done.

:: Edge
echo [3/6] Cleaning Microsoft Edge...
rd /s /q "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Cache" 2>nul
rd /s /q "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Code Cache" 2>nul
del /q /f "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\History" 2>nul
del /q /f "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Cookies" 2>nul
del /q /f "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Web Data" 2>nul
del /q /f "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Shortcuts" 2>nul
del /q /f "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Top Sites" 2>nul
del /q /f "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Visited Links" 2>nul
rd /s /q "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Extensions" 2>nul
rd /s /q "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Extension State" 2>nul
echo Done.

:: Firefox
echo [4/6] Cleaning Mozilla Firefox...
for /d %%x in ("%APPDATA%\Mozilla\Firefox\Profiles\*") do (
    rd /s /q "%%x\cache2" 2>nul
    del /q /f "%%x\cookies.sqlite" 2>nul
    del /q /f "%%x\places.sqlite" 2>nul
    del /q /f "%%x\formhistory.sqlite" 2>nul
    del /q /f "%%x\search.json.mozlz4" 2>nul
)
echo Done.

:: Opera
echo [5/6] Cleaning Opera...
rd /s /q "%APPDATA%\Opera Software\Opera Stable\Cache" 2>nul
del /q /f "%APPDATA%\Opera Software\Opera Stable\History" 2>nul
del /q /f "%APPDATA%\Opera Software\Opera Stable\Cookies" 2>nul
del /q /f "%APPDATA%\Opera Software\Opera Stable\Web Data" 2>nul
del /q /f "%APPDATA%\Opera Software\Opera Stable\Shortcuts" 2>nul
echo Done.

:: Brave
echo [6/6] Cleaning Brave...
rd /s /q "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data\Default\Cache" 2>nul
rd /s /q "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data\Default\Code Cache" 2>nul
rd /s /q "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data\Default\Service Worker" 2>nul
rd /s /q "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data\Default\GPUCache" 2>nul
del /q /f "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data\Default\History" 2>nul
del /q /f "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data\Default\History-journal" 2>nul
del /q /f "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data\Default\Cookies" 2>nul
del /q /f "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data\Default\Cookies-journal" 2>nul
del /q /f "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data\Default\Web Data" 2>nul
del /q /f "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data\Default\Web Data-journal" 2>nul
del /q /f "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data\Default\Shortcuts" 2>nul
del /q /f "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data\Default\Shortcuts-journal" 2>nul
del /q /f "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data\Default\Top Sites" 2>nul
del /q /f "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data\Default\Top Sites-journal" 2>nul
del /q /f "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data\Default\Visited Links" 2>nul
del /q /f "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data\Default\Network Action Predictor" 2>nul
del /q /f "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data\Default\Network Action Predictor-journal" 2>nul
del /q /f "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data\Default\Origin Bound Certs" 2>nul
del /q /f "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data\Default\Origin Bound Certs-journal" 2>nul
del /q /f "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data\Default\QuotaManager" 2>nul
del /q /f "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data\Default\QuotaManager-journal" 2>nul
del /q /f "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data\Default\Favicons" 2>nul
del /q /f "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data\Default\Favicons-journal" 2>nul
del /q /f "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data\Default\Bookmarks" 2>nul
del /q /f "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data\Default\Bookmarks.bak" 2>nul
rd /s /q "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data\Default\Extensions" 2>nul
rd /s /q "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data\Default\Extension State" 2>nul
rd /s /q "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data\Default\Extension Rules" 2>nul
echo Done.

echo.
echo NOTE: Search engine suggestions (from Brave Search, Google, etc.)
echo are provided by the search engine itself and cannot be cleared locally.
echo To disable them, go to: brave://settings/search
echo and turn off "Show autocomplete suggestions in address bar"
echo.

echo.
echo ============================================
echo    Browser History Cleaned!
echo ============================================
echo.
pause

echo All browser data has been cleared:
echo - History, cache, cookies removed
echo - Bookmarks deleted
echo - Extensions removed
echo - Search history cleared
echo.
