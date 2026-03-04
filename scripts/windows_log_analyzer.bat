@echo off
setlocal enabledelayedexpansion
title Windows Log Analyzer
chcp 65001 >nul 2>&1

echo ============================================
echo    Windows Log Analyzer
echo ============================================
echo.
echo Sis skriptas analizuoja Windows Event Viewer
echo ir parodo svarbius errors/warnings.
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
echo [1] Klaidos per paskutines 24 valandas
echo [2] Klaidos per paskutine savaite
echo [3] Kritiniu klaidu suvestine (visu laiku)
echo [4] Daugiausiai besikartojancio klaidos (TOP 15)
echo [5] Eksportuoti ataskaita i faila
echo [6] Atsaukti
echo.

set /p opt="Pasirinkimas (1-6): "

if "%opt%"=="6" exit /b 0
if "%opt%"=="1" (
    set "hours=24"
    set "label=24 valandas"
    goto :recent_errors
)
if "%opt%"=="2" (
    set "hours=168"
    set "label=savaite"
    goto :recent_errors
)
if "%opt%"=="3" goto :critical
if "%opt%"=="4" goto :top_repeating
if "%opt%"=="5" goto :export
goto :invalid

:recent_errors
echo.
echo ============================================
echo    Klaidos per paskutine(-es) %label%
echo ============================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0assets\log_recent_errors.ps1" %hours%
goto :done

:critical
echo.
echo ============================================
echo    Kritiniu klaidu suvestine
echo ============================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0assets\log_critical_summary.ps1"
goto :done

:top_repeating
echo.
echo ============================================
echo    TOP 15 besikartojancio klaidos
echo ============================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0assets\log_top_repeating.ps1"
goto :done

:export
echo.
echo ============================================
echo    Eksportas i faila
echo ============================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0assets\log_export.ps1"
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
