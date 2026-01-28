@echo off
setlocal EnableDelayedExpansion
title Driver Backup Tool

echo ============================================
echo    Driver Backup Tool
echo ============================================
echo.
echo Sis skriptas sukurs visų įdiegtu draiveriu atsargine kopija.
echo Naudinga pries Windows reinstaliavima arba atnaujinima.
echo.

:: Patikrinimas del administratoriaus teisiu
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] KLAIDA: Reikalingos Administratoriaus teises!
    echo Paleiskite si skripta per Script Launcher kaip Administratoriu.
    pause
    exit /b 1
)

:: Nustatome backup aplanką
set "backup_dir=%USERPROFILE%\Desktop\Driver_Backup_%date:~-4%%date:~3,2%%date:~0,2%_%time:~0,2%%time:~3,2%"
set "backup_dir=%backup_dir: =0%"

echo Backup aplankas: %backup_dir%
echo.

echo [1/3] Kuriamas backup aplankas...
mkdir "%backup_dir%" 2>nul
if %errorLevel% neq 0 (
    echo [!] KLAIDA: Nepavyko sukurti aplanko.
    pause
    exit /b 1
)
echo [OK] Aplankas sukurtas.

echo [2/3] Eksportuojami draiveriaiį (tai gali uztrukti 1-3 min.)...
echo.
dism /online /export-driver /destination:"%backup_dir%"

if %errorLevel% equ 0 (
    echo.
    echo [OK] Draiveriaiį sekmingai eksportuoti!
) else (
    echo.
    echo [!] ISPEJIMAS: Kai kurie draiveriaiį gali buti neeksportuoti.
)

echo [3/3] Kuriamas draiveriu sarasas (driver_list.txt)...
powershell -NoProfile -Command "Get-WmiObject Win32_PnPSignedDriver | Select-Object DeviceName, DriverVersion, Manufacturer, DriverDate | Out-File -FilePath '%backup_dir%\driver_list.txt' -Encoding UTF8"
echo [OK] Sarasas sukurtas.

echo.
echo ============================================
echo    BACKUP BAIGTAS! ✨
echo ============================================
echo.
echo Backup vieta: %backup_dir%
echo.
echo Faile rasite:
echo  - Visus .inf draiveriu failus
echo  - driver_list.txt (detali informacija)
echo.
echo Kaip atkurti draiverius:
echo  1. Device Manager ^> Update Driver
echo  2. Browse my computer ^> Let me pick
echo  3. Pasirinkite backup aplanką
echo.
echo Atidaromas backup aplankas...
start "" "%backup_dir%"
echo.
pause
exit /b
