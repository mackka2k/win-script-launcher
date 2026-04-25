@echo off
setlocal EnableDelayedExpansion
title Task Killer Extreme 💀💥
chcp 65001 >nul 2>&1

echo ============================================
echo    Task Killer Extreme 💀💥
echo ============================================
echo.
echo Isveskite proceso pavadinima, kuri norite "nuzudyti"
echo (pvz.: chrome, discord, gta5, explorer)
echo.

:input
set /p target="Proceso pavadinimas: "

if "!target!"=="" (
    echo [!] Ivestis negali buti tuscia.
    goto input
)

echo.
echo [!] Bandoma uzbaigti visus !target! procesus...
taskkill /f /im !target!.exe /t

if %errorlevel% equ 0 (
    echo.
    echo [OK] Visi !target! procesai sekmingai uzbaigti.
) else (
    echo.
    echo [!] KLAIDA: Nepavyko rasti arba uzdaryti !target!.
    echo Patikrinkite pavadinima ir bandykite dar karta.
)

echo.
echo Ar norite "nuzudyti" dar viena procesą? (Y/N)
set /p again="Pasirinkimas: "
if /i "!again!"=="Y" goto input

echo.
echo Išeinama...
pause
exit /b
