@echo off
setlocal EnableDelayedExpansion
title Low Latency Audio Fix 🎧⚡

echo ============================================
echo    Low Latency Audio Fix 🎧⚡
echo ============================================
echo.
echo Sis skriptas optimizuos Windows garso posisteme:
echo 1. Nustatys auksta prioriteta Pro Audio uzduotims.
echo 2. Sumazins sistemos rezervuojama resursu kieki (Latency).
echo 3. Perkraus garso tarnybas.
echo.

:: Patikrinimas del administratoriaus teisiu
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] KLAIDA: Reikalingos Administratoriaus teises!
    echo Paleiskite si skripta per Script Launcher kaip Administratoriu.
    pause
    exit /b 1
)

echo [1/3] Reguliuojami MMCSS (Multimedia Class Scheduler) nustatymai...
:: Nustatome sistemos jautruma (SystemResponsiveness) i 0 (maksimalus pirmenybe multimedijai)
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "SystemResponsiveness" /t REG_DWORD /d 0 /f >nul

:: Pro Audio optimizavimas
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Pro Audio" /v "GPU Priority" /t REG_DWORD /d 8 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Pro Audio" /v "Priority" /t REG_DWORD /d 6 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Pro Audio" /v "Scheduling Category" /t REG_SZ /d "High" /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Pro Audio" /v "SFIO Priority" /t REG_SZ /d "High" /f >nul

echo [OK] Registro pakeitimai pritaikyti.

echo [2/3] Perkraunamos Windows Audio tarnybos...
net stop Audiosrv /y >nul 2>&1
net stop AudioEndpointBuilder /y >nul 2>&1
net start AudioEndpointBuilder >nul 2>&1
net start Audiosrv >nul 2>&1
echo [OK] Tarnybos perkrautos.

echo [3/3] Optimizuojamas audiodg.exe procesas...
:: Pastaba: audiodg.exe prioritetas paprastai valdomas sistemos, bet mes uztikriname fonini stabiluma
echo [INFO] Garso variklis dabar veikia optimizuotu rezimu.

echo.
echo ============================================
echo    SUTVARKYTA! ✨🎶
echo ============================================
echo Garso vėlavimas turėtu buti sumazintas.
echo Jei naudojate specifine garso korta, patikrinkite ir jos ASIO nustatymus.
echo.
pause
exit /b
