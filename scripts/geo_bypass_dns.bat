@echo off
setlocal EnableDelayedExpansion
title Geo-Bypass DNS Switcher

echo ============================================
echo    Geo-Bypass DNS Switcher
echo ============================================
echo.

:: Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] KLAIDA: Būtinos Administratoriaus teisės tinklo nustatymams keisti.
    pause
    exit /b 1
)

echo Dabartinė DNS būsena:
powershell -Command "Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object { $_.ServerAddresses -ne $null } | Select-Object InterfaceAlias, ServerAddresses"
echo.

echo Pasirinkite DNS serverį:
echo [1] Cloudflare (1.1.1.1, 1.0.0.1) - Greitis ir Privatumas
echo [2] Google (8.8.8.8, 8.8.4.4) - Patikimumas
echo [3] Quad9 (9.9.9.9) - Padidintas Saugumas
echo [4] AUTOMATINIS (DHCP) - Grįžti į tiekėjo nustatymus
echo [5] Atšaukti
echo.

set /p opt="Pasirinkimas (1-5): "

if "%opt%"=="1" (
    set "dns1=1.1.1.1"
    set "dns2=1.0.0.1"
    set "name=Cloudflare"
) else if "%opt%"=="2" (
    set "dns1=8.8.8.8"
    set "dns2=8.8.4.4"
    set "name=Google"
) else if "%opt%"=="3" (
    set "dns1=9.9.9.9"
    set "dns2=149.112.112.112"
    set "name=Quad9"
) else if "%opt%"=="4" (
    echo.
    echo 🔄 Grąžinami automatiniai nustatymai...
    powershell -Command "Get-NetIPInterface -AddressFamily IPv4 | Where-Object { $_.ConnectionState -eq 'Connected' } | ForEach-Object { Set-DnsClientServerAddress -InterfaceAlias $_.InterfaceAlias -ResetServerAddresses }"
    echo [OK] DNS nustatytas į automatinį.
    pause
    exit /b 0
) else (
    exit /b 0
)

echo.
echo 🚀 Nustatomas %name% DNS...

:: Apply DNS to all active network adapters
powershell -Command "Get-NetIPInterface -AddressFamily IPv4 | Where-Object { $_.ConnectionState -eq 'Connected' } | ForEach-Object { Set-DnsClientServerAddress -InterfaceAlias $_.InterfaceAlias -ServerAddresses ('%dns1%', '%dns2%') }"

:: Flush DNS Cache to apply changes immediately
ipconfig /flushdns >nul

echo.
echo ============================================
echo    ✅ %name% DNS aktyvuotas!
echo ============================================
echo DNS talpykla išvalyta. Naršymas dabar saugesnis.
echo.
pause
exit /b
