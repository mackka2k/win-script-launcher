@echo off
setlocal EnableDelayedExpansion
title NextDNS CLI PRO Guard 🦾🌑

echo ============================================
echo    NextDNS CLI PRO Guard (Branduolio Lygis)
echo ============================================
echo.
echo Pastebėta, kad atsisiuntėte NextDNS CLI versiją.
echo Tai yra "pro" įrankis, kuris veikia kaip Windows Service.
echo Jokių ikonų, jokių lengvų "Disable" mygtukų.
echo.

:: Patikrinimas del administratoriaus teisiu
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] KLAIDA: BUTINOS Administratoriaus teises.
    pause
    exit /b 1
)

set "sourceExe=C:\Users\Admin\Desktop\nextdns_1.46.0_windows_386\nextdns.exe"
set "targetDir=C:\Program Files\NextDNS-CLI"
set "targetExe=%targetDir%\nextdns.exe"

echo Pasirinkite veiksmą:
echo [1] ĮDIEGTI CLI kaip amžiną sargą (d92cad)
echo [2] Tikrinti būseną
echo [3] Pašalinti CLI sargą
echo [4] Išeiti
echo.
set /p opt="Pasirinkimas: "

if "%opt%"=="1" goto install
if "%opt%"=="2" goto status
if "%opt%"=="3" goto uninstall
exit /b

:install
echo.
if not exist "%sourceExe%" (
    echo [!] KLAIDA: Nerastas %sourceExe%
    echo Įsitikinkite, kad išpakavote NextDNS į:
    echo C:\Users\Admin\Desktop\nextdns_1.46.0_windows_386\
    pause
    exit /b
)

echo [1/4] Ruošiamas katalogas...
if not exist "%targetDir%" mkdir "%targetDir%"
copy /y "%sourceExe%" "%targetExe%" >nul

echo [2/4] Diegiama tarnyba (Service)...
"%targetExe%" install -config d92cad -report-client-info >nul 2>&1

echo [3/4] Paleidžiamas sargas...
"%targetExe%" start >nul 2>&1

echo [4/4] Konfigūruojama sistemos integracija...
"%targetExe%" setup >nul 2>&1

echo.
echo ============================================
echo       CLI SARGYBINIS AKTYVUOTAS! 🌑🛡️
echo ============================================
echo.
echo Tavo d92cad profilis veikia kaip WINDOWS SERVICE.
echo Tai techniškai stipriausias blokavimo būdas:
echo  - Nėra piktogramos systray (mažesnė pagunda).
echo  - DoH (DNS-over-HTTPS) šifruojamas srautas.
echo  - Automatiškai pasileidžia su Windows.
echo.
"%targetExe%" status
echo.
pause
exit /b

:status
echo.
if exist "%targetExe%" (
    "%targetExe%" status
) else (
    echo [!] CLI sargas neįdiegtas.
)
pause
exit /b

:uninstall
echo.
if exist "%targetExe%" (
    echo [!] Stabdomas ir šalinamas sargas...
    "%targetExe%" stop >nul 2>&1
    "%targetExe%" uninstall >nul 2>&1
    echo [OK] Išdiegta.
) else (
    echo [!] Failas nerastas.
)
pause
exit /b
