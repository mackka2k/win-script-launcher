@echo off
setlocal EnableDelayedExpansion
title Restore Point Manager 🕒🛡️

echo ============================================
echo    Restore Point Manager 🕒🛡️
echo ============================================
echo.

:: Patikrinimas del administratoriaus teisiu
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] KLAIDA: Reikalingos Administratoriaus teises!
    echo Paleiskite si skripta per Script Launcher kaip Administratoriu.
    pause
    exit /b 1
)

:menu
echo Pasirinkite veiksmas:
echo [1] Perziureti esamus atkūrimo taškus
echo [2] Sukurti naują atkūrimo tašką
echo [3] Atidaryti sistemos atkūrimo valdymo langą (UI)
echo [4] Išeiti
echo.
set /p opt="Pasirinkimas: "

if "%opt%"=="1" goto list
if "%opt%"=="2" goto create
if "%opt%"=="3" goto open_ui
if "%opt%"=="4" exit /b
goto menu

:list
echo.
echo [!] Ieskoma atkūrimo taškų...
powershell -NoProfile -Command "Get-ComputerRestorePoint | Select-Object SequenceNumber, Description, @{Label='Date';Expression={$_.CreationTime}}, RestorePointType | Format-Table -AutoSize"
echo.
pause
goto menu

:create
echo.
echo Iveskite atkūrimo taško pavadinimą:
set /p desc="Pavadinimas: "
if "!desc!"=="" set "desc=Manual Restore Point"

echo [!] Kuriamas atkūrimo taškas: !desc!...
powershell -NoProfile -Command "Checkpoint-Computer -Description '!desc!' -RestorePointType 'MODIFY_SETTINGS'"
if %errorlevel% equ 0 (
    echo [OK] Atkūrimo taškas sėkmingai sukurtas.
) else (
    echo [!] KLAIDA: Nepavyko sukurti taško. Isitikinkite, kad System Protection ijungta.
)
echo.
pause
goto menu

:open_ui
echo.
echo [!] Atidaromas System Properties...
start systempropertiesprotection
goto menu
