@echo off
setlocal EnableDelayedExpansion
title CMD Pro Setup - Terminal Optimizer

echo ============================================
echo    CMD Pro Setup - Terminal Optimizer
echo ============================================
echo.
echo Sis skriptas optimizuos CMD terminala:
echo  - UTF-8 kodavimas (lietuviskos raides)
echo  - QuickEdit rezimas (pelyte kopijuoti/iklijuoti)
echo  - Spalvota tema (profesionalus dizainas)
echo  - Patobulintas AutoComplete
echo  - Consolas sriftas
echo.

:: Patikrinimas del administratoriaus teisiu
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] KLAIDA: Reikalingos Administratoriaus teises!
    echo Paleiskite si skripta per Script Launcher kaip Administratoriu.
    pause
    exit /b 1
)

echo [1/6] Nustatomas UTF-8 kodavimas (lietuviskos raides)...
reg add "HKLM\Software\Microsoft\Command Processor" /v "Autorun" /t REG_SZ /d "@chcp 65001>nul" /f >nul
echo [OK] UTF-8 aktyvuotas.

echo [2/6] Ijungiamas QuickEdit rezimas (pelyte kopijuoti)...
reg add "HKCU\Console" /v "QuickEdit" /t REG_DWORD /d 1 /f >nul
echo [OK] QuickEdit aktyvuotas.

echo [3/6] Nustatoma profesionali spalvu schema...
:: Juodas fonas, baltas tekstas, ryskios spalvos
reg add "HKCU\Console" /v "ColorTable00" /t REG_DWORD /d 0x00000000 /f >nul
reg add "HKCU\Console" /v "ColorTable07" /t REG_DWORD /d 0x00CCCCCC /f >nul
reg add "HKCU\Console" /v "ScreenColors" /t REG_DWORD /d 0x0007 /f >nul
reg add "HKCU\Console" /v "PopupColors" /t REG_DWORD /d 0x00F5 /f >nul
echo [OK] Spalvos sutvarkytos.

echo [4/6] Patobulinamas AutoComplete (Tab klavisas)...
reg add "HKLM\Software\Microsoft\Command Processor" /v "CompletionChar" /t REG_DWORD /d 9 /f >nul
reg add "HKLM\Software\Microsoft\Command Processor" /v "PathCompletionChar" /t REG_DWORD /d 9 /f >nul
echo [OK] AutoComplete optimizuotas.

echo [5/6] Isjungiamas CMD garso signalas (beep)...
reg add "HKCU\Control Panel\Sound" /v "Beep" /t REG_SZ /d "no" /f >nul
echo [OK] Beep isjungtas.

echo [6/6] Nustatomas geresnis sriftas (Consolas)...
reg add "HKCU\Console" /v "FaceName" /t REG_SZ /d "Consolas" /f >nul
reg add "HKCU\Console" /v "FontSize" /t REG_DWORD /d 0x00140000 /f >nul
reg add "HKCU\Console" /v "FontWeight" /t REG_DWORD /d 400 /f >nul
echo [OK] Sriftas pakeistas.

echo.
echo ============================================
echo    OPTIMIZAVIMAS BAIGTAS! ✨
echo ============================================
echo.
echo Pakeitimai:
echo  [+] UTF-8 kodavimas (lietuviskos raides veikia)
echo  [+] QuickEdit (pelyte pazymeti ir kopijuoti)
echo  [+] Profesionalios spalvos
echo  [+] Tab autocomplete (failu/aplanku pabaigimas)
echo  [+] Consolas sriftas (aiškesnis)
echo  [+] Be garsiniu signalu
echo.
echo SVARBU: Uzdarykite visus CMD langus ir atidarykite nauja,
echo kad pamatytumet pakeitimus.
echo.
pause
exit /b
