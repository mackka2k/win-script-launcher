@echo off
setlocal EnableDelayedExpansion
title Windows Update Fixer 🛠️🔄

echo ============================================
echo    Windows Update Fixer 🛠️🔄
echo ============================================
echo.
echo Sis skriptas sutvarkys Windows Update klaidas:
echo 1. Sustabdys tarnybas
echo 2. Isvalys talpyklas (Cache)
echo 3. Paleis viska is naujo
echo.

:: Patikrinimas del administratoriaus teisiu
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] KLAIDA: Reikalingos Administratoriaus teises!
    echo Paleiskite si skripta per Script Launcher kaip Administratoriu.
    pause
    exit /b 1
)

echo [1/3] Stabdomos Windows Update tarnybos...
net stop wuauserv >nul 2>&1
net stop cryptSvc >nul 2>&1
net stop bits >nul 2>&1
net stop msiserver >nul 2>&1
echo [OK] Tarnybos sustabdytos.

echo [2/3] Valomos atnaujinimu talpyklos (SoftwareDistribution)...
:: Pervadiname aplankus, kad Windows sukurtu naujus
if exist "%windir%\SoftwareDistribution" (
    ren "%windir%\SoftwareDistribution" SoftwareDistribution.old >nul 2>&1
    if %errorlevel% neq 0 (
        rmdir /s /q "%windir%\SoftwareDistribution" >nul 2>&1
    )
)
if exist "%windir%\System32\catroot2" (
    ren "%windir%\System32\catroot2" catroot2.old >nul 2>&1
    if %errorlevel% neq 0 (
        rmdir /s /q "%windir%\System32\catroot2" >nul 2>&1
    )
)
echo [OK] Cache isvalyta.

echo [3/3] Paleidziamos tarnybos is naujo...
net start wuauserv >nul 2>&1
net start cryptSvc >nul 2>&1
net start bits >nul 2>&1
net start msiserver >nul 2>&1
echo [OK] Sistemos darbas atstatytas.

echo.
echo ============================================
echo    SUTVARKYTA! ✨
echo ============================================
echo Patikrinkite Windows Update nustatymus dabar.
echo.
pause
exit /b
