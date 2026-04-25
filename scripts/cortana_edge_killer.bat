@echo off
setlocal
title Cortana ^& Edge Killer
chcp 65001 >nul 2>&1


set "SCRIPT_BACKUP_TARGETS=registry services scheduled_tasks"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0assets\common_backup.ps1" -ScriptName "%~nx0" -Targets %SCRIPT_BACKUP_TARGETS%
if errorlevel 1 (
    echo [!] Backup guard failed.
    choice /C YN /N /M "Continue without backup? (Y/N): "
    if errorlevel 2 exit /b 1
)

echo ============================================
echo    Cortana ^& Edge Killer
echo ============================================
echo.
echo Sis skriptas sustabdys ir isjungs fono procesus:
echo - Cortana (Search Assistant)
echo - Microsoft Edge (Background Tasks ^& Update)
echo.

:: Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] KLAIDA: Reikalingos Administratoriaus teises.
    pause
    exit /b 1
)

echo [!] Stabdomi procesai...
echo.

:: Stop Edge Processes
taskkill /F /IM MicrosoftEdge.exe /T >nul 2>&1
taskkill /F /IM msedge.exe /T >nul 2>&1
taskkill /F /IM MicrosoftEdgeUpdate.exe /T >nul 2>&1
echo [OK] Microsoft Edge procesai sustabdyti.

:: Stop Cortana
taskkill /F /IM Cortana.exe /T >nul 2>&1
echo [OK] Cortana procesas sustabdytas.

echo.
echo [!] Uzrakinamas fono veikimas (Permanent Fix)...
echo.

:: Use PowerShell to kill everything and lock it down
powershell -File "%~dp0assets\cortana_edge_killer_inline_1.ps1"

echo.
echo ============================================
echo    Viskas nuzudyta ir uzrakinta! 💀🔒
echo ============================================
echo Po restarto Cortana ir Edge fone nebeturetu
echo naudoti tavo resursu.
echo.
pause
exit /b
