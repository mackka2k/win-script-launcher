@echo off
setlocal EnableDelayedExpansion
title Mouse Acceleration Killer - 1:1 Precision

echo ============================================
echo    Mouse Acceleration Killer
echo ============================================
echo.
echo Sis skriptas pilnai isjungia Windows peles pagreiti (acceleration):
echo  - Panaikina "Enhance pointer precision"
echo  - Nustato 1:1 peles kreive (SmoothMouseXCurve/YCurve)
echo  - Optimizuoja registro nustatymus tiksliam taikymuisi
echo.

:: Patikrinimas del administratoriaus teisiu
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] KLAIDA: BUTINOS Administratoriaus teises.
    pause
    exit /b 1
)

echo [1/3] Isjungiami standartiniai pagreicio parametrai...
reg add "HKCU\Control Panel\Mouse" /v "MouseSpeed" /t REG_SZ /d "0" /f >nul
reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold1" /t REG_SZ /d "0" /f >nul
reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold2" /t REG_SZ /d "0" /f >nul
echo [OK] Standartinis pagreitis isjungtas.

echo [2/3] Taikoma 1:1 peles kreive (Registry Fix)...
:: Šios vertės atitinka "MarkC Mouse Fix" - pilnas pagreičio pašalinimas
reg add "HKCU\Control Panel\Mouse" /v "SmoothMouseXCurve" /t REG_BINARY /d 0000000000000000c0cc0c0000000000806619000000000040003300000000000000660000000000 /f >nul
reg add "HKCU\Control Panel\Mouse" /v "SmoothMouseYCurve" /t REG_BINARY /d 0000000000000000000038000000000000007000000000000000a800000000000000e00000000000 /f >nul
echo [OK] Kreive nustatyta i tiesine (1:1).

echo [3/3] Optimizuojamas MouseDataQueueSize...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\mouclass\Parameters" /v "MouseDataQueueSize" /t REG_DWORD /d 100 /f >nul
echo [OK] Duomenu eiles dydis optimizuotas (mazesnis lagas).

echo.
echo ============================================
echo    PELĖS OPTIMIZAVIMAS BAIGTAS! 🎯⚡
echo ============================================
echo.
echo Pakeitimai isigalios po kompiuterio perkrovimo arba 
echo po to, kai perkrausite Explorer.
echo.
echo Rekomendacija: Patikrinkite, ar zaidimuose "Raw Input" yra IJUNGTAS.
echo.
pause
exit /b
