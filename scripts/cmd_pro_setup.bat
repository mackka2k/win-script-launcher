@echo off
setlocal EnableDelayedExpansion
title CMD Pro Setup - Terminal Optimizer

echo ============================================
echo    CMD Pro Setup - Terminal Optimizer
echo ============================================
echo.
echo Sis skriptas optimizuos CMD terminala:
echo  - UTF-8 kodavimas (lietuviskos raides)
echo  - Git Bash spalvos (tamsus fonas, zalias tekstas)
echo.

:: Patikrinimas del administratoriaus teisiu
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] KLAIDA: Reikalingos Administratoriaus teises!
    echo Paleiskite si skripta per Script Launcher kaip Administratoriu.
    pause
    exit /b 1
)

echo [1/3] Nustatomas UTF-8 kodavimas (lietuviskos raides)...
reg add "HKLM\Software\Microsoft\Command Processor" /v "Autorun" /t REG_SZ /d "@chcp 65001>nul" /f >nul
echo [OK] UTF-8 aktyvuotas.

echo [2/3] Nustatoma Git Bash spalvu schema...
:: Tamsus fonas (#000000), zalias tekstas (#00FF00) kaip Git Bash
reg add "HKCU\Console" /v "ColorTable00" /t REG_DWORD /d 0x00000000 /f >nul
reg add "HKCU\Console" /v "ColorTable01" /t REG_DWORD /d 0x00800000 /f >nul
reg add "HKCU\Console" /v "ColorTable02" /t REG_DWORD /d 0x0000AA00 /f >nul
reg add "HKCU\Console" /v "ColorTable03" /t REG_DWORD /d 0x00AAAA00 /f >nul
reg add "HKCU\Console" /v "ColorTable04" /t REG_DWORD /d 0x000000AA /f >nul
reg add "HKCU\Console" /v "ColorTable05" /t REG_DWORD /d 0x00AA00AA /f >nul
reg add "HKCU\Console" /v "ColorTable06" /t REG_DWORD /d 0x0000AAAA /f >nul
reg add "HKCU\Console" /v "ColorTable07" /t REG_DWORD /d 0x00AAAAAA /f >nul
reg add "HKCU\Console" /v "ColorTable08" /t REG_DWORD /d 0x00555555 /f >nul
reg add "HKCU\Console" /v "ColorTable09" /t REG_DWORD /d 0x00FF5555 /f >nul
reg add "HKCU\Console" /v "ColorTable10" /t REG_DWORD /d 0x0000FF00 /f >nul
reg add "HKCU\Console" /v "ColorTable11" /t REG_DWORD /d 0x00FFFF55 /f >nul
reg add "HKCU\Console" /v "ColorTable12" /t REG_DWORD /d 0x005555FF /f >nul
reg add "HKCU\Console" /v "ColorTable13" /t REG_DWORD /d 0x00FF55FF /f >nul
reg add "HKCU\Console" /v "ColorTable14" /t REG_DWORD /d 0x0055FFFF /f >nul
reg add "HKCU\Console" /v "ColorTable15" /t REG_DWORD /d 0x00FFFFFF /f >nul
:: Tamsus fonas (juodas), zalias tekstas
reg add "HKCU\Console" /v "ScreenColors" /t REG_DWORD /d 0x0002 /f >nul
reg add "HKCU\Console" /v "PopupColors" /t REG_DWORD /d 0x00F0 /f >nul
echo [OK] Git Bash spalvos nustatytos.

echo [3/3] Isjungiamas CMD garso signalas (beep)...
reg add "HKCU\Control Panel\Sound" /v "Beep" /t REG_SZ /d "no" /f >nul
echo [OK] Beep isjungtas.

echo.
echo ============================================
echo    OPTIMIZAVIMAS BAIGTAS! ✨
echo ============================================
echo.
echo Pakeitimai:
echo  [+] UTF-8 kodavimas (lietuviskos raides veikia)
echo  [+] Git Bash spalvos (tamsus fonas, zalias tekstas)
echo  [+] Be garsiniu signalu
echo.
echo SVARBU: Uzdarykite visus CMD langus ir atidarykite nauja,
echo kad pamatytumet pakeitimus.
echo.
pause
exit /b
