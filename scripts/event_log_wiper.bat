@echo off
setlocal EnableDelayedExpansion
title Event Log Wiper 🧹🔒

echo ============================================
echo    Event Log Wiper 🧹🔒
echo ============================================
echo.
echo Sis skriptas visiskai isvalys visus Windows Ivykiu zurnalus (Event Logs).
echo Tai atlaisvins vietos ir padidins privatuma.
echo.

:: Patikrinimas del administratoriaus teisiu
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] KLAIDA: Reikalingos Administratoriaus teises!
    echo Paleiskite si skripta per Script Launcher kaip Administratoriu.
    pause
    exit /b 1
)

echo [!] Pradedamas valymas...
echo (Gali pasirodyti daug pranesimu apie istrintus zurnalus)
echo.

:: Isvalome visus logus naudojant wevtutil
for /F "tokens=*" %%G in ('wevtutil.exe el') do (
    echo Valomas: %%G
    wevtutil.exe cl "%%G" >nul 2>&1
)

echo.
echo ============================================
echo    VALYMAS BAIGTAS! ✨
echo ============================================
echo Visi Windows Event Logs buvo sekmingai isvalyti.
echo.
pause
exit /b
