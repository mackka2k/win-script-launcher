@echo off
setlocal EnableDelayedExpansion
title CMD Setup - Terminal Optimizer

echo ============================================
echo    CMD Setup - Terminal Optimizer
echo ============================================
echo.
echo Sis skriptas optimizuos CMD terminala:
echo  - UTF-8 kodavimas (lietuviskos raides)
echo  - Spalvota tema (profesionalus dizainas)
echo  - Patobulintas AutoComplete
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

echo [2/3] Nustatoma profesionali spalvu schema...
:: Juodas fonas, baltas tekstas, ryskios spalvos
reg add "HKCU\Console" /v "ColorTable00" /t REG_DWORD /d 0x00000000 /f >nul
reg add "HKCU\Console" /v "ColorTable07" /t REG_DWORD /d 0x00CCCCCC /f >nul
reg add "HKCU\Console" /v "ScreenColors" /t REG_DWORD /d 0x0007 /f >nul
reg add "HKCU\Console" /v "PopupColors" /t REG_DWORD /d 0x00F5 /f >nul
echo [OK] Spalvos sutvarkytos.

echo [3/3] Patobulinamas AutoComplete (Tab klavisas)...
reg add "HKLM\Software\Microsoft\Command Processor" /v "CompletionChar" /t REG_DWORD /d 9 /f >nul
reg add "HKLM\Software\Microsoft\Command Processor" /v "PathCompletionChar" /t REG_DWORD /d 9 /f >nul
echo [OK] AutoComplete optimizuotas.

echo.
echo ============================================
echo    OPTIMIZAVIMAS BAIGTAS! ✨
echo ============================================
echo.
echo Pakeitimai:
echo  [+] UTF-8 kodavimas (lietuviskos raides veikia)
echo  [+] Profesionalios spalvos
echo  [+] Tab autocomplete (failu/aplanku pabaigimas)
echo.
echo SVARBU: Uzdarykite visus CMD langus ir atidarykite nauja,
echo kad pamatytumet pakeitimus.
echo.
pause
exit /b
