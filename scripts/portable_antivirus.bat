@echo off
setlocal EnableDelayedExpansion
title Portable Security Suite

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
echo    Portable Security Suite
echo ============================================
echo.
echo [1] Dr.Web CureIt! (Anti-Virus Scanner)
echo     - Best for general cleaning
echo     * Includes "Chameleon Mode" (Randomized Filename)
echo.
echo [2] RKill (Process Terminator)
echo     - Run this FIRST if malware blocks scanners
echo     - Kills known malware processes
echo.
echo [3] Clean Up (Remove downloaded tools)
echo [4] Exit
echo.
echo ============================================
set /p choice="Select an option (1-4): "

if "%choice%"=="1" goto drweb
if "%choice%"=="2" goto rkill
if "%choice%"=="3" goto cleanup
if "%choice%"=="4" exit
goto menu

:drweb
cls
echo ============================================
echo    Dr.Web CureIt!
echo ============================================
echo.
set "DOWNLOAD_DIR=%TEMP%\PortableAV"
if not exist "%DOWNLOAD_DIR%" mkdir "%DOWNLOAD_DIR%"

:: Generate random filename for Chameleon Mode
set "chars=ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
set "randname="
for /L %%i in (1,1,8) do (
    set /a "idx=!random! %% 36"
    for %%j in (!idx!) do set "randname=!randname!!chars:~%%j,1!"
)
set "TARGET_FILE=%DOWNLOAD_DIR%\!randname!.exe"

echo [1/3] Generated random filename: !randname!.exe (Anti-Block)
echo [2/3] Downloading Dr.Web CureIt...
echo.

set "AV_URL=https://download.geo.drweb.com/pub/drweb/cureit/drweb-cureit.exe"
powershell -Command "& { $ProgressPreference = 'SilentlyContinue'; try { Invoke-WebRequest -Uri '%AV_URL%' -OutFile '%TARGET_FILE%' -UseBasicParsing; Write-Host 'Download complete!' -ForegroundColor Green } catch { Write-Host 'Download failed!' -ForegroundColor Red; exit 1 } }"

if not exist "%TARGET_FILE%" (
    pause
    goto menu
)

echo.
echo [3/3] Launching Dr.Web...
echo.
start "" "%TARGET_FILE%"
echo Scanner is running. You can close this window or return to menu.
echo.
pause
goto menu

:rkill
cls
echo ============================================
echo    RKill (Malware Process Terminator)
echo ============================================
echo.
set "DOWNLOAD_DIR=%TEMP%\PortableAV"
if not exist "%DOWNLOAD_DIR%" mkdir "%DOWNLOAD_DIR%"
set "TARGET_FILE=%DOWNLOAD_DIR%\rkill.exe"

echo [1/2] Downloading RKill...
echo.

:: RKill (renamed to iExplore.exe to bypass blocks, common trick)
set "RKILL_URL=https://download.bleepingcomputer.com/grinler/rkill.exe"

powershell -Command "& { $ProgressPreference = 'SilentlyContinue'; try { Invoke-WebRequest -Uri '%RKILL_URL%' -OutFile '%TARGET_FILE%' -UserAgent 'Mozilla/5.0' -UseBasicParsing; Write-Host 'Download complete!' -ForegroundColor Green } catch { Write-Host 'Download failed! Malware might be blocking the connection.' -ForegroundColor Red; exit 1 } }"

if not exist "%TARGET_FILE%" (
    echo.
    echo attempting mirror...
    :: Fallback to a renamed version mechanism if possible, but for now simple retry
    pause
    goto menu
)

echo.
echo [2/2] Running RKill...
echo A log file will open when finished.
echo.
"%TARGET_FILE%"
pause
goto menu

:cleanup
cls
echo ============================================
echo    Cleanup
echo ============================================
echo.
set "DOWNLOAD_DIR=%TEMP%\PortableAV"
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
