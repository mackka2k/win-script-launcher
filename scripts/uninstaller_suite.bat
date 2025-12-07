@echo off
setlocal EnableDelayedExpansion
title Portable Uninstaller Suite

:: Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: This script requires administrator privileges.
    echo Please run as administrator.
    pause
    exit /b 1
)

:menu
cls
echo ============================================
echo    Portable Uninstaller Suite
echo ============================================
echo.
echo [1] Geek Uninstaller (Recommended)
echo     - FAST, single executable
echo     - Cleans leftovers automatically
echo.
echo [2] Revo Uninstaller (Free Portable)
echo     - Powerful scanning modes
echo     - Industry standard for years
echo.
echo [3] Clean Up (Remove downloaded tools)
echo [4] Exit
echo.
echo ============================================
set /p choice="Select an option (1-4): "

if "%choice%"=="1" goto geek
if "%choice%"=="2" goto revo
if "%choice%"=="3" goto cleanup
if "%choice%"=="4" exit
goto menu

:geek
cls
echo ============================================
echo    Geek Uninstaller
echo ============================================
echo.
set "DOWNLOAD_DIR=%TEMP%\PortableUninstallers"
if not exist "%DOWNLOAD_DIR%" mkdir "%DOWNLOAD_DIR%"
set "ZIP_FILE=%DOWNLOAD_DIR%\geek.zip"
set "EXTRACT_DIR=%DOWNLOAD_DIR%\Geek"

echo [1/3] Downloading Geek Uninstaller...
echo.
set "TOOL_URL=https://geekuninstaller.com/geek.zip"
powershell -Command "& { $ProgressPreference = 'SilentlyContinue'; try { Invoke-WebRequest -Uri '%TOOL_URL%' -OutFile '%ZIP_FILE%' -UseBasicParsing; Write-Host 'Download complete!' -ForegroundColor Green } catch { Write-Host 'Download failed!' -ForegroundColor Red; exit 1 } }"

if not exist "%ZIP_FILE%" (
    pause
    goto menu
)

echo.
echo [2/3] Extracting...
powershell -Command "Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%EXTRACT_DIR%' -Force"

echo.
echo [3/3] Launching...
echo.
if exist "%EXTRACT_DIR%\geek.exe" (
    start "" "%EXTRACT_DIR%\geek.exe"
) else (
    echo Could not find geek.exe.
    start "" "%EXTRACT_DIR%"
)
pause
goto menu

:revo
cls
echo ============================================
echo    Revo Uninstaller (Free Portable)
echo ============================================
echo.
set "DOWNLOAD_DIR=%TEMP%\PortableUninstallers"
if not exist "%DOWNLOAD_DIR%" mkdir "%DOWNLOAD_DIR%"
set "ZIP_FILE=%DOWNLOAD_DIR%\revo.zip"
set "EXTRACT_DIR=%DOWNLOAD_DIR%\Revo"

echo [1/3] Downloading Revo Uninstaller...
echo.
:: Revo Portable URL from official site
set "TOOL_URL=https://www.revouninstaller.com/download-portable-free"
powershell -Command "& { $ProgressPreference = 'SilentlyContinue'; try { Invoke-WebRequest -Uri '%TOOL_URL%' -OutFile '%ZIP_FILE%' -UseBasicParsing; Write-Host 'Download complete!' -ForegroundColor Green } catch { Write-Host 'Download failed!' -ForegroundColor Red; exit 1 } }"

if not exist "%ZIP_FILE%" (
    pause
    goto menu
)

echo.
echo [2/3] Extracting...
powershell -Command "Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%EXTRACT_DIR%' -Force"

echo.
echo [3/3] Launching...
echo.
:: Usually extracts to a folder like RevoUninstaller_Portable
:: Check for RevoUPort.exe inside subfolders if needed
if exist "%EXTRACT_DIR%\RevoUninstaller_Portable\RevoUPort.exe" (
    start "" "%EXTRACT_DIR%\RevoUninstaller_Portable\RevoUPort.exe"
) else (
    :: Try to find any exe or open folder
    echo Searching for executable...
    for /r "%EXTRACT_DIR%" %%f in (RevoUPort.exe) do start "" "%%f" & goto found
    echo Executable not found. Opening folder.
    start "" "%EXTRACT_DIR%"
    :found
)
pause
goto menu

:cleanup
cls
echo ============================================
echo    Cleanup
echo ============================================
echo.
set "DOWNLOAD_DIR=%TEMP%\PortableUninstallers"
if exist "%DOWNLOAD_DIR%" (
    echo Removing %DOWNLOAD_DIR%...
    rmdir /s /q "%DOWNLOAD_DIR%"
    echo Done.
) else (
    echo Nothing to clean.
)
echo.
pause
goto menu
