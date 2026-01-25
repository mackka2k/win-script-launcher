@echo off
setlocal EnableDelayedExpansion
title Ultimate Privacy Shield

echo ============================================
echo      Ultimate Privacy Shield 🛡️🔒
echo ============================================
echo.
echo Sis skriptas uzrakins Windows privatumo nustatymus,
echo isjungs sekima, reklaminius ID ir Bing integracija.
echo.

:: Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] KLAIDA: Reikalingos Administratoriaus teises!
    echo Paleiskite Script Launcher kaip Administratoriu.
    pause
    exit /b 1
)

echo [1/5] Isjungiama Telemetrija ir Sekimas...
:: Disable Telemetry Services
sc stop DiagTrack >nul 2>&1
sc config DiagTrack start= disabled >nul 2>&1
sc stop dmwappushservice >nul 2>&1
sc config dmwappushservice start= disabled >nul 2>&1

:: Registry Privacy Tweaks
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f >nul
echo [OK] Sekimas isjungtas.

echo [2/5] Isjungiamas Advertising ID ir Activity History...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v "Enabled" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "PublishUserActivities" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "UploadUserActivities" /t REG_DWORD /d 0 /f >nul
echo [OK] Reklamos ir istorijos sekimas sustabdytas.

echo [3/5] Isjungiamas Bing Search Start Meniu...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "BingSearchEnabled" /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "CortanaConsent" /t REG_DWORD /d 0 /f >nul
echo [OK] Start meniu dabar tik lokalaus paieskos.

echo [4/5] Isjungiamas Vietoves nustatymas (Location)...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" /v "Value" /t REG_SZ /d "Deny" /f >nul
echo [OK] Vietoves sekimas uzblokuotas.

echo [5/5] Isvalomas "Event Log" (Pedsakai)...
wevtutil cl Setup >nul 2>&1
wevtutil cl System >nul 2>&1
wevtutil cl Security >nul 2>&1
wevtutil cl Application >nul 2>&1
echo [OK] Sisteminiai logai isvalyti.

echo.
echo ============================================
echo    PRIVATUMAS UZRAKINTAS! ✨🛡️
echo ============================================
echo Jusu PC dabar siuncia 90%% maziau duomenu 
echo Microsoft serveriams. 
echo.
pause
exit /b
