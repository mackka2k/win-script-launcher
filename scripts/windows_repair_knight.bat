@echo off
setlocal EnableDelayedExpansion
title Windows Repair Knight 🛡️🛠️

echo ============================================
echo    Windows Repair Knight 🛡️🛠️
echo ============================================
echo.
echo Sis skriptas atliks pilna sistemos patikra ir taisymą:
echo 1. DISM - Sutvarkys Windows atvaizdą (Image)
echo 2. SFC - Sutvarkys pazeistus sisteminius failus
echo.

:: Patikrinimas del administratoriaus teisiu
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] KLAIDA: Reikalingos Administratoriaus teises!
    echo Paleiskite si skripta per Script Launcher kaip Administratoriu.
    pause
    exit /b 1
)

echo [1/3] Paleidziama DISM (ScanHealth)...
dism /online /cleanup-image /scanhealth
echo.

echo [2/3] Paleidziama DISM (RestoreHealth)...
echo (Tai gali uztrukti kelias minutes, prasome palaukti)
dism /online /cleanup-image /restorehealth
echo.

echo [3/3] Paleidziama SFC (System File Checker)...
sfc /scannow
echo.

echo ============================================
echo    REMTAS BAIGTAS! ✨
echo ============================================
echo Jei SFC rado klaidu ir jas sutvarke, 
echo rekomenduojama perkrauti kompiuteri.
echo.
pause
exit /b
