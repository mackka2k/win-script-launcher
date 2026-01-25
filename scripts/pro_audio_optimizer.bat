@echo off
setlocal
title Pro Audio ^& Mic Optimizer

echo ============================================
echo    Pro Audio ^& Mic Optimizer
echo ============================================
echo.
echo Sis skriptas pritaikys profesionalius audio nustatymus:
echo - Isjungs garso apribojimus (Registry)
echo - Padidins Audio serviso prioriteta (Latency fix)
echo - Atidarys skydelius galutiniam suderinimui
echo.

:: Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] KLAIDA: Reikalingos Administratoriaus teises!
    pause
    exit /b 1
)

echo [1/3] Optimizuojami registro nustatymai...

:: 1. Set Pro Audio priority in registry
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Pro Audio" /v "GPU Priority" /t REG_DWORD /d 8 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Pro Audio" /v "Priority" /t REG_DWORD /d 6 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Pro Audio" /v "Scheduling Category" /t REG_SZ /d "High" /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Pro Audio" /v "SFIO Priority" /t REG_SZ /d "High" /f >nul

:: 2. Disable Absolute Volume (fixes some headset volume sync issues)
reg add "HKLM\SYSTEM\ControlSet001\Control\Bluetooth\Audio\AVRCP\CT" /v "DisableAbsoluteVolume" /t REG_DWORD /d 1 /f >nul 2>&1

echo [OK] Registro tweaks pritaikyti.
echo.

echo [2/3] Perkrunamas Audio variklis...
net stop Audiosrv /y >nul 2>&1
net start Audiosrv >nul 2>&1
echo [OK] Windows Audio servisas perkrautas.
echo.

echo [3/3] Atidaromi valdymo skydeliai...
echo.
echo REKOMENDACIJA:
echo 1. Ausinems: Pasirinkite 24-bit, 48000Hz (arba daugiau).
echo 2. Microfonui: Nustatykite Volume i 80-90, palikite "Enhancements" ijungtus (jie padeda).
echo.

:: Open Classic Sound Dialogs
control mmsys.cpl,,0
control mmsys.cpl,,1

echo ============================================
echo    Optimizavimas baigtas! 🎧🎤
echo ============================================
echo Patikrinkite atsidariusius langus ir nustatykite
echo maksimalia kokybe (Advanced tab).
echo.
pause
exit /b
