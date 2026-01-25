@echo off
setlocal
title Winget Auto-Updater

echo ============================================
echo    Winget Universal Auto-Updater
echo ============================================
echo.

:: Check winget
winget --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Winget nerastas.
    pause
    exit /b
)

echo [!] Ieskoma atnaujinimu...
echo.

:: Show upgrades
winget upgrade

echo.
echo --------------------------------------------
echo Ar norite atnaujinti VISAS sias programas?
echo --------------------------------------------
set /p "ans=Iveskite Y (taip) arba N (ne): "

if /i "%ans%"=="Y" (
    echo.
    echo 🚀 Vykdomas atnaujinimas... Prasome neuzdaryti lango.
    echo.
    winget upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements
    echo.
    echo ============================================
    echo    ✅ Viskas atnaujinta sekmingai!
    echo ============================================
) else (
    echo.
    echo [!] Atnaujinimas atsauktas.
)

echo.
pause
exit /b
