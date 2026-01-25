@echo off
setlocal
title Discord Stealth Cleaner

echo ============================================
echo      Discord Stealth Cleaner 🕵️‍♂️🔒
echo ============================================
echo.
echo Sis skriptas pasalins visus Discord pedsakus 
echo tavo kompiuteryje (HWID pedsakai, cache, ID).
echo.

:: Check for admin
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] KLAIDA: Reikalingos Administratoriaus teises!
    pause
    exit /b 1
)

echo [1/4] Uzdaromas Discord...
taskkill /F /IM discord.exe /T >nul 2>&1
echo [OK] Procesai sustabdyti.

echo [2/4] Naikinami tapatybes failai (Tokens ^& HWID trackers)...
:: Delete Discord folders in AppData and LocalAppData
powershell -Command "Remove-Item -Path \"$env:APPDATA\discord\" -Recurse -Force -ErrorAction SilentlyContinue"
powershell -Command "Remove-Item -Path \"$env:LOCALAPPDATA\Discord\" -Recurse -Force -ErrorAction SilentlyContinue"
powershell -Command "Remove-Item -Path \"$env:LOCALAPPDATA\discord_canary\" -Recurse -Force -ErrorAction SilentlyContinue"
echo [OK] Visi ID aplankai istrinti.

echo [3/4] Valoma tinklo talpykla...
ipconfig /flushdns >nul
echo [OK] DNS isvalytas.

echo.
echo ============================================
echo    VALYMAS BAIGTAS! ✨
echo ============================================
echo.
echo SVARBU JUSU SAUGUMUI:
echo 1. Pries pajungiant nauja Discord, BUTINAI:
echo    - Pasikeisk MAC adresa (naudok 'mac_address_changer.bat')
echo    - Jei imanoma, perkrauk routeri (kad pasikeistu IP)
echo 2. NAUDOK narsykles (Brave) "Private Window" pirmajam prisijungimui.
echo 3. Tik tada instaliuok Discord is naujo.
echo.
pause
exit /b
