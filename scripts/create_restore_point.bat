@echo off
setlocal
title Instant Restore Point

echo ============================================
echo    Instant Windows Restore Point
echo ============================================
echo.

:: Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] KLAIDA: Reikalingos Administratoriaus teises.
    echo Paleiskite Script Launcher kaip Administratoriu.
    echo.
    pause
    exit /b 1
)

echo [1/3] Tikrinama Sistemos apsauga...
:: Enable System Restore on C: just in case it was disabled
powershell -Command "Enable-ComputerRestore -Drive 'C:\' -ErrorAction SilentlyContinue"

echo [2/3] Konfiguruojami nustatymai...
:: Set frequency to 0 to allow multiple restore points in a short period
powershell -Command "Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\SystemRestore' -Name 'SystemRestorePointCreationFrequency' -Value 0 -ErrorAction SilentlyContinue"

echo [3/3] Kuriamas atkūrimo taškas...
echo (Tai gali užtrukti apie 30-60 sekundžių, prašome palaukti)
echo.

:: Create the actual restore point
powershell -Command "Checkpoint-Computer -Description \"Manual_Restore_Point_%DATE%_%TIME%\" -RestorePointType \"MODIFY_SETTINGS\""

if %errorlevel% equ 0 (
    echo.
    echo ============================================
    echo    ✅ Atkurimo taskas sukurtas sekmingai!
    echo ============================================
    echo Jei kas nors negerai su sistema, galesite grižti
    echo i sia akimirka per 'System Restore' meniu.
) else (
    echo.
    echo [!] KLAIDA: Nepavyko sukurti atkurimo tasko.
    echo Patikrinkite, ar diske yra pakankamai vietos.
)

echo.
pause
exit /b
