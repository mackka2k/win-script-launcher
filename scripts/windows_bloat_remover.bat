@echo off
setlocal
title Windows Bloatware Remover


set "SCRIPT_BACKUP_TARGETS=appx"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0assets\common_backup.ps1" -ScriptName "%~nx0" -Targets %SCRIPT_BACKUP_TARGETS%
if errorlevel 1 (
    echo [!] Backup guard failed.
    choice /C YN /N /M "Continue without backup? (Y/N): "
    if errorlevel 2 exit /b 1
)

echo ============================================
echo    Windows Bloatware Remover
echo ============================================
echo.
echo Sis skriptas istrins nereikalingas Windows programas:
echo [Solitaire, News, Weather, Feedback Hub, Tips, Maps, etc.]
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

echo [!] ISPEJIMAS: Programos bus istrintos visam laikui.
set /p proceed="Ar tikrai norite testi? (Y/N): "
if /i not "%proceed%"=="Y" (
    echo Atsaukta.
    pause
    exit /b 0
)

echo.
echo  Isinstaliuojamos siuksles...
echo.

:: List of common Windows bloatware IDs
powershell -File "%~dp0assets\windows_bloat_remover_inline_1.ps1"

echo.
echo ============================================
echo    Valymas baigtas!
echo ============================================
echo.
pause
exit /b
