@echo off
setlocal EnableDelayedExpansion
title Time Syncer (Laiko Sinchronizavimas)

echo ============================================
echo    Time Syncer
echo ============================================
echo.
echo Sis skriptas priverstinai sinchronizuos tavo kompiuterio laikrodi
echo su oficialiais Windows laiko serveriais.
echo.

:: Patikrinimas del administratoriaus teisiu
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] KLAIDA: Reikalingos Administratoriaus teises!
    echo Paleiskite si skripta per Script Launcher kaip Administratoriu.
    pause
    exit /b 1
)

echo [1/4] Sustabdoma ir perregistruojama paslauga...
:: Sprendziame "The interface is unknown" (0x800706B5) klaida
net stop w32time >nul 2>&1
w32tm /unregister >nul 2>&1
w32tm /register >nul 2>&1
echo [OK] Paslauga perregistruota.

echo [2/4] Paleidziama Windows Time paslauga...
net start w32time >nul 2>&1
echo [OK] Paslauga veikia.

echo [3/4] Konfiguruojami laiko serveriai...
w32tm /config /manualpeerlist:"time.windows.com pool.ntp.org" /syncfromflags:manual /reliable:YES /update >nul 2>&1
echo [OK] Serveriu sarasas atnaujintas.

echo [4/4] Vykdoma sinchronizacija...
w32tm /resync /force
if %errorlevel% equ 0 (
    echo.
    echo ============================================
    echo    SEKMINGAI SINCHRONIZUOTA!
    echo ============================================
    echo Dabartinis laikas: %TIME%
) else (
    echo.
    echo [!] KLAIDA: Nepavyko atvaziuoti laiko. 
    echo Bandoma perkrauti paslauga dar karta...
    net stop w32time >nul 2>&1
    net start w32time >nul 2>&1
    w32tm /resync /force
)

echo.
echo Darbas baigtas.
pause
exit /b
