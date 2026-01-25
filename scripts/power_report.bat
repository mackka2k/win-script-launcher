@echo off
setlocal
title Power Consumption ^& Efficiency Report

echo ============================================
echo    Power Consumption ^& Efficiency Report
echo ============================================
echo.
echo Sis skriptas sugeneruos detalia ataskaita apie 
echo tavo kompiuterio energijos vartojima.
echo.

:: Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] KLAIDA: Reikalingos Administratoriaus teises!
    echo Paleiskite Script Launcher kaip Administratoriu.
    echo.
    pause
    exit /b 1
)

echo Pasirinkite ataskaitos tipa:
echo [1] Energijos efektyvumo analize (60 sek. skenavimas)
echo [2] Baterijos bukle (tik nesiojamiems kompiuteriams)
echo [3] Atsaukti
echo.

set /p opt="Pasirinkimas (1-3): "

if "%opt%"=="1" (
    echo.
    echo [!] Pradedamas 60 sekundziu stebejimas...
    echo Prasome neliesti kompiuterio, kol vyksta skenavimas.
    echo.
    powercfg /energy /output "%USERPROFILE%\Desktop\Energy_Report.html"
    if %errorlevel% leq 1 (
        echo.
        echo [OK] Ataskaita sugeneruota: Desktop\Energy_Report.html
        start "" "%USERPROFILE%\Desktop\Energy_Report.html"
    )
) else if "%opt%"=="2" (
    echo.
    echo [!] Generuojama baterijos ataskaita...
    powercfg /batteryreport /output "%USERPROFILE%\Desktop\Battery_Report.html"
    if %errorlevel% equ 0 (
        echo [OK] Ataskaita sugeneruota: Desktop\Battery_Report.html
        start "" "%USERPROFILE%\Desktop\Battery_Report.html"
    ) else (
        echo [!] KLAIDA: Nepavyko sugeneruoti. Tikriausiai naudojate stacionaru PC.
    )
) else (
    exit /b 0
)

echo.
echo ============================================
echo    Procesas baigtas.
echo ============================================
echo.
pause
exit /b
