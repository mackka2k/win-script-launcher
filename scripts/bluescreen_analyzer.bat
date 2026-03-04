@echo off
setlocal enabledelayedexpansion
title Bluescreen (BSOD) Analyzer
chcp 65001 >nul 2>&1

echo ============================================
echo    Bluescreen (BSOD) Analyzer
echo ============================================
echo.
echo Sis skriptas analizuoja Windows BSOD
echo (Blue Screen of Death) istoriją ir minidump failus.
echo.

:: Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] KLAIDA: Reikalingos Administratoriaus teises!
    echo Paleiskite Script Launcher kaip Administratoriu.
    echo.
    pause
    exit /b 1
)

echo Pasirinkite veiksma:
echo [1] BSOD istorija is Event Log (greita)
echo [2] Minidump failu analize (detali)
echo [3] Paskutiniu crash statistika
echo [4] Atsaukti
echo.

set /p opt="Pasirinkimas (1-4): "

if "%opt%"=="4" exit /b 0
if "%opt%"=="1" goto :event_log
if "%opt%"=="2" goto :minidump
if "%opt%"=="3" goto :statistics
goto :invalid

:event_log
echo.
echo ============================================
echo    BSOD istorija is Event Log
echo ============================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0assets\bsod_event_log.ps1"
goto :done

:minidump
echo.
echo ============================================
echo    Minidump failu analize
echo ============================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0assets\bsod_minidump.ps1"
goto :done

:statistics
echo.
echo ============================================
echo    Crash statistika
echo ============================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0assets\bsod_statistics.ps1"
goto :done

:invalid
echo [!] Neteisingas pasirinkimas.

:done
echo.
echo ============================================
echo    Procesas baigtas.
echo ============================================
echo.
pause
exit /b
