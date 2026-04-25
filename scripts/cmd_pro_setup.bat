@echo off
setlocal EnableDelayedExpansion
title CMD Setup - Terminal Optimizer


set "SCRIPT_BACKUP_TARGETS=registry"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0assets\common_backup.ps1" -ScriptName "%~nx0" -Targets %SCRIPT_BACKUP_TARGETS%
if errorlevel 1 (
    echo [!] Backup guard failed.
    choice /C YN /N /M "Continue without backup? (Y/N): "
    if errorlevel 2 exit /b 1
)

echo ============================================
echo    CMD Setup - Terminal Optimizer
echo ============================================
echo.
echo Sis skriptas optimizuos CMD terminala:
echo  - UTF-8 kodavimas (lietuviskos raides)
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

echo [1/3] Nustatomas UTF-8 kodavimas (lietuviskos raides)...
reg add "HKLM\Software\Microsoft\Command Processor" /v "Autorun" /t REG_SZ /d "@chcp 65001>nul" /f >nul
echo [OK] UTF-8 aktyvuotas.

echo [2/3] Patobulinamas AutoComplete (Tab klavisas)...
reg add "HKLM\Software\Microsoft\Command Processor" /v "CompletionChar" /t REG_DWORD /d 9 /f >nul
reg add "HKLM\Software\Microsoft\Command Processor" /v "PathCompletionChar" /t REG_DWORD /d 9 /f >nul
echo [OK] AutoComplete optimizuotas.

echo [3/3] Isjungiamas CMD garso signalas (beep)...
reg add "HKCU\Control Panel\Sound" /v "Beep" /t REG_SZ /d "no" /f >nul
echo [OK] Beep isjungtas.

echo.
echo ============================================
echo    OPTIMIZAVIMAS BAIGTAS!
echo ============================================
echo.
echo Pakeitimai:
echo  [+] UTF-8 kodavimas (lietuviskos raides veikia)
echo  [+] Tab autocomplete (failu/aplanku pabaigimas)
echo  [+] Be garsiniu signalu (beep isjungtas)

echo.
echo SVARBU: Uzdarykite visus CMD langus ir atidarykite nauja,
echo kad pamatytumet pakeitimus.
echo.
pause
exit /b
