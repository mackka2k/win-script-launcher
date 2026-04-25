@echo off
setlocal EnableDelayedExpansion
title Ghost Driver Cleaner - System Hygiene 🧹
chcp 65001 >nul 2>&1

echo ============================================
echo    Ghost Driver Cleaner
echo ============================================
echo.
echo Sis skriptas suranda ir pashalina senus, nebenaudojamus
echo "vaiduokliskus" draiverius (irenginius, kurie nebeprijungti).
echo Tai gali padeti pagreitinti sistemos krovimasi ir istaisyti konfliktus.
echo.

:: Patikrinimas del administratoriaus teisiu
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] KLAIDA: BUTINOS Administratoriaus teises.
    pause
    exit /b 1
)

echo [1/2] Skenuojami atjungti irenginiai...
echo Tai gali uztrukti kelias sekundes...
echo.

:: Naudojame PowerShell, kad gautume sąrašą ir suskaičiuotume
powershell -NoProfile -File "%~dp0assets\ghost_driver_cleaner_inline_1.ps1"

echo.
echo Pasirinkite veiksma:
echo [1] PASALINTI visus atjungtus irenginius (Rekomenduojama)
echo [2] Tik skenuoti (nieko nedaryti)
echo [3] Iseiti
echo.
set /p opt="Pasirinkimas: "

if "%opt%"=="1" goto clean
exit /b

:clean
echo.
echo [!] Pradedamas valymas...
:: Naudojame pnputil, kad pašalintume atjungtus įrenginius
powershell -NoProfile -File "%~dp0assets\ghost_driver_cleaner_inline_2.ps1"

echo.
echo ============================================
echo    VALYMAS BAIGTAS!
echo ============================================
echo.
echo Visi nebenaudingi draiveriu irasai pashalinti.
echo.
pause
exit /b
