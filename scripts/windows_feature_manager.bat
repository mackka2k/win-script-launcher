@echo off
setlocal EnableDelayedExpansion
title Windows Feature Manager 💻⚙️

echo ============================================
echo    Windows Feature Manager 💻⚙️
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
echo [1] Sarasas įjungtų funkcijų (Enabled)
echo [2] Sarasas visų galimų funkcijų
echo [3] Ijungti funkciją (reikes pavadinimo)
echo [4] Isjungti funkciją (reikes pavadinimo)
echo [5] Išeiti
echo.
set /p opt="Pasirinkimas: "

if "%opt%"=="1" goto list_enabled
if "%opt%"=="2" goto list_all
if "%opt%"=="3" goto enable_feat
if "%opt%"=="4" goto disable_feat
if "%opt%"=="5" exit /b
goto menu

:list_enabled
echo.
echo [!] Renkamos ijungtos funkcijos...
dism /online /get-features /format:table | findstr /i "Enabled"
echo.
pause
goto menu

:list_all
echo.
echo [!] Visas funkcijų sarasas:
dism /online /get-features /format:table
echo.
pause
goto menu

:enable_feat
echo.
echo Iveskite funkcijos pavadinimą (pvz.: Microsoft-Hyper-V-All):
set /p feat="Pavadinimas: "
if "!feat!"=="" goto menu
echo [!] Ijungiamas !feat!...
dism /online /enable-feature /featurename:!feat! /all
echo.
pause
goto menu

:disable_feat
echo.
echo Iveskite funkcijos pavadinimą (pvz.: Internet-Explorer-Optional-amd64):
set /p feat="Pavadinimas: "
if "!feat!"=="" goto menu
echo [!] Isjungiamas !feat!...
dism /online /disable-feature /featurename:!feat!
echo.
pause
goto menu
