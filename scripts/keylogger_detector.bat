@echo off
setlocal EnableDelayedExpansion
title Keylogger ^& Spyware Detector
chcp 65001 >nul 2>&1

echo ============================================
echo    Keylogger ^& Spyware Detector
echo ============================================
echo.
echo Sis skriptas atlieka bazine sistemos patikra
echo ieskant itartinu procesu ir jungciu.
echo.

:: Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] KLAIDA: Būtinos Administratoriaus teisės geresnei patikrai.
    pause
    exit /b 1
)

echo [1/3] Tikrinami aktyvūs tinklo ryšiai (itartini portai)...
powershell -File "%~dp0assets\keylogger_detector_inline_1.ps1"

echo.
echo [2/3] Ieskoma procesu be gamintojo (unidentified)...
powershell -Command "Get-Process | Where-Object { $_.Company -eq $null } | Select-Object Name, Id, Path | Format-Table"

echo.
echo [3/3] Tikrinami zinomi itartini procesai...
set "suspicious=log.exe logger.exe keyboard.exe spy.exe hook.exe capture.exe"
set "found=0"

for %%s in (%suspicious%) do (
    tasklist /FI "IMAGENAME eq %%s" 2>NUL | find /I /N "%%s">NUL
    if "!ERRORLEVEL!"=="0" (
        echo [!] RASTAS ITARTINAS PROCESAS: %%s
        set "found=1"
    )
)

if "%found%"=="0" (
    echo [OK] Zinomu paprastu keyloggeriu nerasta.
)

echo.
echo ============================================
echo    Patikra baigta. 🕵
echo ============================================
echo Pastaba: Sis skriptas yra bazine apsauga.
echo Rezultatus turi ivertinti pats.
echo.
pause
exit /b
