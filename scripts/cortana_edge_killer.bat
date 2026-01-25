@echo off
setlocal
title Cortana ^& Edge Killer

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
powershell -Command "Get-Process -Name msedge, Cortana -ErrorAction SilentlyContinue | Stop-Process -Force; $null = Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' -Name 'SearchboxTaskbarMode' -Value 0 -ErrorAction SilentlyContinue; $null = Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Name 'AllowCortana' -Value 0 -ErrorAction SilentlyContinue; $null = Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\MicrosoftEdge\Main' -Name 'AllowPrelaunch' -Value 0 -ErrorAction SilentlyContinue; $null = Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate' -Name 'Allowsxs' -Value 0 -ErrorAction SilentlyContinue; Get-Service -Name edgeupdate, edgeupdatem -ErrorAction SilentlyContinue | Set-Service -StartupType Disabled; Get-ScheduledTask -TaskName *EdgeUpdate* -ErrorAction SilentlyContinue | Disable-ScheduledTask; Write-Host 'Servisai, Taskai ir Registras užrakinti.' -ForegroundColor Green"

echo.
echo ============================================
echo    Viskas nuzudyta ir uzrakinta! 💀🔒
echo ============================================
echo Po restarto Cortana ir Edge fone nebeturetu
echo naudoti tavo resursu.
echo.
pause
exit /b
