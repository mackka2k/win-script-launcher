@echo off
setlocal EnableDelayedExpansion
title Firewall Basic Hardener - Inbound Defense 🛡️⚓

echo ============================================
echo    Firewall Basic Hardener
echo ============================================
echo.
echo Sis skriptas pritaikys rekomenduojamus saugumo 
echo nustatymus tavo Windows Firewall Inbound srautui:
echo  - Uzblokuos nereikalaujama prisijungimo bandoma is isores.
echo  - Isjungs nesaugu Ping (ICMP) reagavima.
echo  - Blokuos SMB (failu dalinimosi) prieiga is interneto.
echo  - Isjungs Remote Assistance ir kitus "backdoors".
echo.

:: Patikrinimas del administratoriaus teisiu
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] KLAIDA: BUTINOS Administratoriaus teises.
    pause
    exit /b 1
)

echo [1/4] Aktyvuojamas Firewall visiems profiliams...
netsh advfirewall set allprofiles state on >nul
echo [OK] Firewall ijungtas.

echo [2/4] Nustatoma bazinė Inbound politika (Block by default)...
:: Nustatome, kad pagal nutylėjimą viskas, kas neleidžiama - blokuojama.
netsh advfirewall set allprofiles firewallpolicy blockinbound,allowoutbound >nul
echo [OK] Visi nezinomi įeinantys ryšiai dabar blokuojami.

echo [3/4] Uždrausiamas ICMP (Ping) iš išorės...
:: Tai paslepia tavo kompiuteri nuo paprasto tinklo skenavimo
netsh advfirewall firewall add rule name="Block-ICMP-Inbound" protocol=icmpv4 dir=in action=block >nul 2>&1
echo [OK] Kompiuteris neberedaguos i "Ping" užklausas.

echo [4/4] Uždrausiami rizikingi servisai (SMB, Remote)...
:: Blokuojame SMB (445 portą), kad išvengtume Ransomware plitimo per tinklą
netsh advfirewall firewall add rule name="Block-SMB-Inbound" protocol=TCP localport=445 dir=in action=block >nul 2>&1
:: Isjungiame Remote Assistance (trukis, per kuri gali prisijungti pagalba)
reg add "HKLM\System\CurrentControlSet\Control\Remote Assistance" /v "fAllowToGetHelp" /t REG_DWORD /d 0 /f >nul
echo [OK] Rizikingi kanalai uždaryti.

echo.
echo ============================================
echo     firewall_basic_hardener.bat - BAIGTA! 🛡️🚀
echo ============================================
echo.
echo Tavo sistema dabar yra saugesnė "Inbound" lygiu.
echo Pastaba: Jei naudoji vietinį failų dalinimąsi tarp 
echo savo kompiuterių, gali tekti rankiniu būdu 
echo leisti SMB savo vietiniame tinkle.
echo.
pause
exit /b
