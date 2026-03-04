@echo off
setlocal EnableDelayedExpansion
title CMD Setup - Terminal Optimizer

echo ============================================
echo    CMD Setup - Terminal Optimizer
echo ============================================
echo.
echo Sis skriptas optimizuos CMD terminala:
echo  - UTF-8 kodavimas (lietuviskos raides)
echo  - QuickEdit rezimas (pelyte kopijuoti/iklijuoti)
echo  - Spalvota tema (profesionalus dizainas)
echo  - Patobulintas AutoComplete
echo  - Isjungiamas CMD garso signalas (beep)
echo.

:: Patikrinimas del administratoriaus teisiu
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] KLAIDA: Reikalingos Administratoriaus teises!
    echo Paleiskite si skripta per Script Launcher kaip Administratoriu.
    pause
    exit /b 1
)

echo [1/4] Nustatomas UTF-8 kodavimas (lietuviskos raides)...
reg add "HKLM\Software\Microsoft\Command Processor" /v "Autorun" /t REG_SZ /d "@chcp 65001>nul" /f >nul
echo [OK] UTF-8 aktyvuotas.

echo [2/4] Nustatoma profesionali spalvu schema...
:: Juodas fonas, baltas tekstas, ryskios spalvos
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

echo [3/4] Patobulinamas AutoComplete (Tab klavisas)...
reg add "HKLM\Software\Microsoft\Command Processor" /v "CompletionChar" /t REG_DWORD /d 9 /f >nul
reg add "HKLM\Software\Microsoft\Command Processor" /v "PathCompletionChar" /t REG_DWORD /d 9 /f >nul
echo [OK] AutoComplete optimizuotas.

echo [4/4] Isjungiamas CMD garso signalas (beep)...
reg add "HKCU\Control Panel\Sound" /v "Beep" /t REG_SZ /d "no" /f >nul
echo [OK] Beep isjungtas.

echo.
echo ============================================
echo    OPTIMIZAVIMAS BAIGTAS! ✨
echo ============================================
echo.
echo Pakeitimai:
echo  [+] UTF-8 kodavimas (lietuviskos raides veikia)
echo  [+] Profesionalios spalvos
echo  [+] Tab autocomplete (failu/aplanku pabaigimas)
echo  [+] Be garsiniu signalu (beep isjungtas)
echo.
echo SVARBU: Uzdarykite visus CMD langus ir atidarykite nauja,
echo kad pamatytumet pakeitimus.
echo.
pause
exit /b
