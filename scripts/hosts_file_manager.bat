@echo off
setlocal EnableDelayedExpansion
title Hosts File Manager 📝📂

echo ============================================
echo    Hosts File Manager 📝📂
echo ============================================
echo.

:: Patikrinimas del administratoriaus teisiu
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] KLAIDA: Reikalingos Administratoriaus teises!
    echo Paleiskite si skripta per Script Launcher kaip Administratoriu.
    pause
    exit /b 1
)

set "hosts_path=%SystemRoot%\System32\drivers\etc\hosts"

:menu
echo Pasirinkite veiksma:
echo [1] Uzblokuoti svetaine (Ivesti adresa)
echo [2] Atidaryti hosts failą redagavimui (Notepad)
echo [3] Iseiti
echo.
set /p opt="Pasirinkimas: "

if "%opt%"=="1" goto block
if "%opt%"=="2" goto open_manual
if "%opt%"=="3" exit /b
goto menu

:block
echo.
echo Iveskite svetaines adresa, kuri norite uzblokuoti (pvz.: facebook.com):
set /p domain="Adresas: "

if "!domain!"=="" goto menu

:: Pridedame ir www versija automatiskai
echo.
echo [!] Blokuojama !domain!...

:: Tikriname ar jau yra
findstr /i /c:"!domain!" "%hosts_path%" >nul
if %errorlevel% equ 0 (
    echo [!] Sis adresas jau yra blokuojamas arba paminetas faile.
) else (
    echo 0.0.0.0 !domain! >> "%hosts_path%"
    echo 0.0.0.0 www.!domain! >> "%hosts_path%"
    echo [OK] Svetaine sekmingai uzblokuota sistemos lygiu.
    
    :: Isvalome DNS cache, kad pakeitimas suveiktu iskarto
    ipconfig /flushdns >nul
    echo [OK] DNS talpykla isvalyta.
)

echo.
pause
goto menu

:open_manual
echo.
echo [!] Atidaromas failas: !hosts_path!
echo Po redagavimo issaugokite (Ctrl+S).
echo.
start notepad.exe "!hosts_path!"
goto menu
