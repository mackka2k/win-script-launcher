@echo off
setlocal EnableDelayedExpansion
title Port Killer Pro

echo ============================================
echo    Port Killer Pro
echo ============================================
echo.

:: Prompt for port number
set /p port="Iveskite PORTO numeri, kuri norite atlaisvinti: "

if "%port%"=="" (
    echo [!] Nenurodytas portas.
    pause
    exit /b 1
)

echo.
echo [!] Ieskoma proceso, naudojancio porta %port%...
echo.

:: Use netstat to find PID
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :%port% ^| findstr LISTENING') do (
    set pid=%%a
)

if "%pid%"=="" (
    echo [✓] Portas %port% yra LAISVAS (jokia programa jo nenaudoja).
) else (
    echo [!] RASTAS PROCESAS (PID: !pid!)
    echo.
    
    :: Show process info
    tasklist /FI "PID eq !pid!"
    echo.
    
    set /p kill="Ar norite NUZUDYTI ši procesa? (Y/N): "
    if /i "!kill!"=="Y" (
        taskkill /F /PID !pid!
        echo.
        echo [OK] Procesas sekmingai nuzudytas. Portas %port% dabar laisvas!
    ) else (
        echo [!] Veiksmas atsauktas.
    )
)

echo.
echo ============================================
echo    Pabaiga.
echo ============================================
echo.
pause
exit /b
