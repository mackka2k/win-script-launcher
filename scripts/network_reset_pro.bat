@echo off
setlocal EnableDelayedExpansion
title Network Reset PRO

echo ============================================
echo    Network Reset PRO
echo ============================================
echo.
echo Sis skriptas atliks pilna tinklo nustatymų atstatymą:
echo  - Winsock reset (TCP/IP stack)
echo  - IP konfiguracija (release/renew)
echo  - DNS cache isvalymas
echo  - Firewall taisykliu atstatymas
echo  - Network adapters reset
echo  - Proxy nustatymų isvalymas
echo.
echo ISPEJIMAS: Po sio skripto reikes perkrauti kompiuteri!
echo.

:: Patikrinimas del administratoriaus teisiu
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] KLAIDA: Reikalingos Administratoriaus teises!
    pause
    exit /b 1
)

pause
echo.

echo [1/10] Atstatomas Winsock katalogas...
netsh winsock reset
echo [OK] Winsock atstatytas.

echo [2/10] Atstatomas TCP/IP stack...
netsh int ip reset
echo [OK] TCP/IP atstatytas.

echo [3/10] Atleidžiamas dabartinis IP adresas...
ipconfig /release >nul
echo [OK] IP adresas atleistas.

echo [4/10] Atnaujinamas IP adresas...
ipconfig /renew >nul
echo [OK] IP adresas atnaujintas.

echo [5/10] Valoma DNS talpykla...
ipconfig /flushdns >nul
echo [OK] DNS cache isvalytas.

echo [6/10] Atstatomi Windows Firewall nustatymai...
netsh advfirewall reset >nul
echo [OK] Firewall atstatytas i numatytuosius nustatymus.

echo [7/10] Isjungiami ir vel ijungiami tinklo adapteriai...
powershell -NoProfile -Command "Get-NetAdapter | Where-Object {$_.Status -eq 'Up'} | Restart-NetAdapter"
echo [OK] Adapteriai perkrauti.

echo [8/10] Valomi proxy nustatymai...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v "ProxyEnable" /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v "ProxyServer" /t REG_SZ /d "" /f >nul
echo [OK] Proxy nustatymai isvalyti.

echo [9/10] Atstatomi NetBIOS nustatymai...
nbtstat -R >nul
nbtstat -RR >nul
echo [OK] NetBIOS atstatytas.

echo [10/10] Valoma ARP talpykla...
arp -d * >nul 2>&1
echo [OK] ARP cache isvalytas.

echo.
echo ============================================
echo    NETWORK RESET BAIGTAS! 🌐✨
echo ============================================
echo.
echo Atlikti veiksmai:
echo  [+] Winsock katalogas atstatytas
echo  [+] TCP/IP stack atstatytas
echo  [+] IP adresas atnaujintas
echo  [+] DNS cache isvalytas
echo  [+] Firewall taisykles atstatytos
echo  [+] Tinklo adapteriai perkrauti
echo  [+] Proxy nustatymai isvalyti
echo  [+] NetBIOS ir ARP cache isvalyti
echo.
echo SVARBU: PRIVALOMA perkrauti kompiuteri, kad pakeitimai isigaliotų!
echo.
set /p reboot="Ar norite perkrauti dabar? (T/N): "
if /i "%reboot%"=="T" (
    echo Kompiuteris bus perkrautas po 10 sekundziu...
    shutdown /r /t 10 /c "Network Reset baigtas - perkraunama sistema"
) else (
    echo Nepamirskite perkrauti kompiuterio rankiniu budu!
)
echo.
pause
exit /b
