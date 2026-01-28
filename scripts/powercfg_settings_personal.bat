@echo off
setlocal EnableDelayedExpansion
title Asmeniniai Sistemos Nustatymai (Personal Setup)

echo ============================================
echo    Asmeniniai Sistemos Nustatymai 🛠️✨
echo ============================================
echo.
for /f "tokens=*" %%a in ('powershell -NoProfile -Command "Get-Date -Format 'HH:mm yyyy/M/d'"') do set datetime=%%a
echo Dabartinis laikas: %datetime%
echo.

:: 1. Patikrinimas del administratoriaus teisiu
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] KLAIDA: Reikalingos Administratoriaus teises!
    echo Paleiskite si skripta per Script Launcher kaip Administratoriu.
    pause
    exit /b 1
)

echo [1/6] Regiono ir Laiko nustatymai...
:: Laiko zona (Vilnius)
tzutil /s "FLE Standard Time" >nul
:: Regionas: Lietuva
reg add "HKCU\Control Panel\International\Geo" /v "Name" /t REG_SZ /d "LT" /f >nul
reg add "HKCU\Control Panel\International\Geo" /v "Nation" /t REG_SZ /d "141" /f >nul

:: --- Sistemos Laiko/Datos Formatas ---
:: Data: 2026/1/29
reg add "HKCU\Control Panel\International" /v "sShortDate" /t REG_SZ /d "yyyy/M/d" /f >nul
reg add "HKCU\Control Panel\International" /v "sLongDate" /t REG_SZ /d "yyyy 'm.' MMMM d 'd.'" /f >nul
:: Laikas: 23:00
reg add "HKCU\Control Panel\International" /v "sShortTime" /t REG_SZ /d "HH:mm" /f >nul
reg add "HKCU\Control Panel\International" /v "sTimeFormat" /t REG_SZ /d "HH:mm:ss" /f >nul

echo [OK] Laiko zona nustatyta i (UTC+02:00) Vilnius.
echo [OK] Regionas nustatytas i Lietuva.
echo [OK] Sistemos laiko formatas nustatytas i HH:mm yyyy/M/d.

echo [2/6] Maitinimo (Power) optimizavimas...
:: Isjungiamas disko isjungimas (AC)
powercfg -change -disk-timeout-ac 0 >nul
:: Isjungiamas USB selective suspend (AC)
powercfg /SETACVALUEINDEX SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 >nul
:: Isjungiama hibernacija
powercfg /hibernate off >nul
:: Monitoriaus isjungimas: Niekada (AC)
powercfg -Change monitor-timeout-ac 0 >nul
:: Miegas (Standby): Niekada (AC)
powercfg /change standby-timeout-ac 0 >nul
:: Wi-Fi maksimalus pajėgumas (AC)
powercfg /SETACVALUEINDEX SCHEME_CURRENT 19cbb8fa-5279-450e-9fac-8a3d5fedd0c1 12bbebe6-58d6-4636-95bb-3217ef867c1a 0 >nul
:: PCIe Link State: Off (AC)
powercfg /SETACVALUEINDEX SCHEME_CURRENT 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 0 >nul
echo [OK] Energijos planai optimizuoti maksimaliam nasumui (AC).

echo [3/6] Nereikalingu paslaugu (Services) isjungimas...
:: Windows Imaging Acquisition
sc stop "StiSvc" >nul 2>&1
sc config "StiSvc" start=disabled >nul 2>&1
:: Data Usage Service
sc stop "DusmSvc" >nul 2>&1
sc config "DusmSvc" start=disabled >nul 2>&1
:: Downloaded Maps Manager
sc stop "MapsBroker" >nul 2>&1
sc config "MapsBroker" start=disabled >nul 2>&1
:: Edge Update
sc stop "edgeupdate" >nul 2>&1
sc config "edgeupdate" start=disabled >nul 2>&1
echo [OK] Isjungtos nereikalingos fono paslaugos.

echo [4/6] Privatumo ir Telemetrijos blokavimas...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "MaxTelemetryAllowed" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\PolicyManager\default\System\AllowExperimentation" /v "value" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v "Enabled" /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoSearchInternetInStartMenu" /t REG_DWORD /d 1 /f >nul
echo [OK] Telemetrija ir sekimas isjungti.

echo [5/6] Sistemos patobulinimai (Tweaks)...
:: Ilgi failu keliai (Long Paths)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v "LongPathsEnabled" /t REG_DWORD /d 1 /f >nul
:: Windows 10 stiliaus desinio klaviso meniu (Classic Context Menu)
reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /ve /d "" /f >nul
:: Windows Update aktyvios valandos (07-23)
reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "ActiveHoursStart" /t REG_DWORD /d 7 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "ActiveHoursEnd" /t REG_DWORD /d 23 /f >nul
echo [OK] Sistemos patobulinimai pritaikyti.

echo [6/6] Laikinu failu valymas...
del /s /f /q %temp%\*.* >nul 2>&1
del /s /f /q %WinDir%\temp\*.* >nul 2>&1
rmdir /s /q "C:\Windows\Prefetch" >nul 2>&1 
:: Thumbcache valymas priverstinai
del /F /S /Q /A %LocalAppData%\Microsoft\Windows\Explorer\thumbcache_*.db >nul 2>&1
echo [OK] Sistemos siuksles isvalytos.

echo.
echo ============================================
echo    SANKA BAIGTA! ✨🚀
echo ============================================
echo.
echo 1. Laikas: Vilnius (UTC+02:00)
echo 2. Power: Diskas, Monitorius, Miegas - NIEKADA (AC)
echo 3. Service: Isjungti Imaging, Maps, EdgeUpdate
echo 4. UI: Windows 10 stiliaus Context Menu
echo 5. Privacy: Telemetrija isjungta
echo.
echo Patarimas: Jei norite naudoti siuos nustatymus ir su baterija (DC),
echo redaguokite skripta pridėdami DC nustatymus.
echo.
pause
exit /b