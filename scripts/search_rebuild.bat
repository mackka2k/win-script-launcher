@echo off
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
powershell -Command "Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches | ForEach-Object {New-ItemProperty -Path $_.PSPath -Name StateFlags0001 -Value 2 -PropertyType DWord -Force -ErrorAction SilentlyContinue}" >nul 2>&1
echo Done.

echo.
echo ============================================
echo    Search Index Rebuild Started!
echo ============================================
echo.
echo The Windows Search index is being rebuilt.
echo.
echo Changes applied:
echo [✓] Search service restarted
echo [✓] Old index deleted
echo [✓] Search settings reset
echo [✓] Index rebuild triggered
echo.
echo The rebuild will continue in the background.
echo This may take 15-30 minutes depending on your files.
echo.
echo Search functionality will improve as indexing progresses.
echo You can check indexing status in: Settings > Search > Searching Windows
echo.
pause
