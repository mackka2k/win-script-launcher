@echo off
setlocal EnableExtensions
title SSD Health Checker

echo ============================================
echo    SSD Health Checker
echo ============================================
echo.

:: Patikrinimas del administratoriaus teisiu
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] ISPEJIMAS: Rekomenduojamos Administratoriaus teises.
    echo.
)

echo Tikrinama SSD/NVMe disku busena...
echo.

:: Supaprastinta versija - rodome tik tai, ka Windows tikrai gali pateikti
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0assets\ssd_lifetime_checker_inline_1.ps1"

echo.
echo ============================================
echo Jei matote "N/A" - tai normalu daugeliui NVMe disku.
echo Windows API neturi pilnos prieigos prie SMART duomenu.
echo.
echo Rekomenduojama: Atsisiuskite gamintojo programa detaliai statistikai.
echo ============================================
echo.
pause
exit /b
