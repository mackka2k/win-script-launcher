@echo off
setlocal EnableDelayedExpansion
title Portable Privacy Suite

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
echo    Portable Privacy Suite
echo ============================================
echo.
echo [1] O&O ShutUp10++ (Highly Recommended)
echo     - The gold standard for Windows 10/11 telemetry
echo     - Single executable, safe, and powerful
echo.
echo [2] WPD (Windows Privacy Dashboard)
echo     - Clean UI, manages firewall and privacy
echo.
echo [3] Clean Up (Remove downloaded tools)
echo [4] Exit
echo.
echo ============================================
set /p choice="Select an option (1-4): "

if "%choice%"=="1" goto oosu
if "%choice%"=="2" goto wpd
if "%choice%"=="3" goto cleanup
if "%choice%"=="4" exit
goto menu

:oosu
cls
echo ============================================
echo    O&O ShutUp10++
echo ============================================
echo.
set "DOWNLOAD_DIR=%TEMP%\PortablePrivacy"
if not exist "%DOWNLOAD_DIR%" mkdir "%DOWNLOAD_DIR%"
set "TARGET_FILE=%DOWNLOAD_DIR%\OOSU10.exe"

echo [1/2] Downloading O&O ShutUp10++...
echo.
set "TOOL_URL=https://dl5.oo-software.com/files/ooshutup10/OOSU10.exe"
powershell -Command "& { $ProgressPreference = 'SilentlyContinue'; try { Invoke-WebRequest -Uri '%TOOL_URL%' -OutFile '%TARGET_FILE%' -UseBasicParsing; Write-Host 'Download complete!' -ForegroundColor Green } catch { Write-Host 'Download failed!' -ForegroundColor Red; exit 1 } }"

if not exist "%TARGET_FILE%" (
    pause
    goto menu
)

echo.
echo [2/2] Launching...
echo.
start "" "%TARGET_FILE%"
pause
goto menu

:wpd
cls
echo ============================================
echo    WPD (Windows Privacy Dashboard)
echo ============================================
echo.
set "DOWNLOAD_DIR=%TEMP%\PortablePrivacy"
if not exist "%DOWNLOAD_DIR%" mkdir "%DOWNLOAD_DIR%"
set "ZIP_FILE=%DOWNLOAD_DIR%\wpd.zip"
set "EXTRACT_DIR=%DOWNLOAD_DIR%\WPD"

echo [1/3] Downloading WPD...
echo.
set "TOOL_URL=https://wpd.app/get/latest.zip"
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
:: WPD exe name acts like "WPD.exe" usually
if exist "%EXTRACT_DIR%\WPD.exe" (
    start "" "%EXTRACT_DIR%\WPD.exe"
) else (
    echo Could not find WPD.exe in extracted files.
    echo Opening folder instead...
    start "" "%EXTRACT_DIR%"
)
pause
goto menu

:cleanup
cls
echo ============================================
echo    Cleanup
echo ============================================
echo.
set "DOWNLOAD_DIR=%TEMP%\PortablePrivacy"
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
