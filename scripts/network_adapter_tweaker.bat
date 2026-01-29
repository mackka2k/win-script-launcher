@echo off
setlocal EnableDelayedExpansion
title Network Adapter Tweaker - Pro Performance 🌐⚡

echo ============================================
echo    Network Adapter Tweaker
echo ============================================
echo.
echo Sis skriptas optimizuos tavo tinklo adapterius:
echo  - Isjungs Energy Efficient Ethernet (EEE)
echo  - Isjungs Green Ethernet
echo  - Isjungs Power Management (taupymo rezimus)
echo  - Isjungs Interrupt Moderation (mazesnis lagas)
echo  - Isjungs Flow Control
echo.

:: Patikrinimas del administratoriaus teisiu
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] KLAIDA: BUTINOS Administratoriaus teises.
    echo Paleiskite si skripta per Script Launcher kaip Administratoriu.
    pause
    exit /b 1
)

echo [1/3] Identifikuojami tinklo adapteriai...
echo.

:: Naudojame PowerShell, kad atliktume gilius vairuotojo lygio pakeitimus
powershell -NoProfile -Command "Get-NetAdapter | Where-Object Status -eq 'Up' | ForEach-Object { ^
    $name = $_.Name; ^
    Write-Host \"Optimizuojamas adapteris: $name\" -ForegroundColor Cyan; ^
    ^
    # 1. Isjungti Power Management (kompiuteris negali isjungti irenginio)
    try { Disable-NetAdapterPowerManagement -Name $name -ErrorAction SilentlyContinue; Write-Host \"  [+] Power Management: DISABLED\" } catch {}; ^
    ^
    # 2. Isjungti Energy Efficient Ethernet
    try { Set-NetAdapterAdvancedProperty -Name $name -DisplayName '*EnergyEfficientEthernet' -DisplayValue 'Disabled' -ErrorAction SilentlyContinue; Write-Host \"  [+] Energy Efficient Ethernet: DISABLED\" } catch {}; ^
    ^
    # 3. Isjungti Green Ethernet (jei yra)
    try { Set-NetAdapterAdvancedProperty -Name $name -DisplayName '*GreenEthernet' -DisplayValue 'Disabled' -ErrorAction SilentlyContinue; Write-Host \"  [+] Green Ethernet: DISABLED\" } catch {}; ^
    ^
    # 4. Isjungti Interrupt Moderation (sumazina latency, bet siek tiek padidina CPU apkrova)
    try { Set-NetAdapterAdvancedProperty -Name $name -DisplayName '*InterruptModeration' -DisplayValue 'Disabled' -ErrorAction SilentlyContinue; Write-Host \"  [+] Interrupt Moderation: DISABLED\" } catch {}; ^
    ^
    # 5. Isjungti Flow Control 
    try { Set-NetAdapterAdvancedProperty -Name $name -DisplayName '*FlowControl' -DisplayValue 'Disabled' -ErrorAction SilentlyContinue; Write-Host \"  [+] Flow Control: DISABLED\" } catch {}; ^
    ^
    # 6. Isjungti Wake on Magic Packet / Pattern Match
    try { Set-NetAdapterAdvancedProperty -Name $name -DisplayName '*WakeOnMagicPacket' -DisplayValue 'Disabled' -ErrorAction SilentlyContinue; Write-Host \"  [+] Wake on Magic Packet: DISABLED\" } catch {}; ^
    try { Set-NetAdapterAdvancedProperty -Name $name -DisplayName '*WakeOnPattern' -DisplayValue 'Disabled' -ErrorAction SilentlyContinue; Write-Host \"  [+] Wake on Pattern Match: DISABLED\" } catch {}; ^
    ^
    Write-Host \"--- Done with $name ---\" -ForegroundColor Gray; ^
}"

echo.
echo [2/3] Optimizuojami TCP/IP parametrai per Netsh...
netsh int tcp set global autotuninglevel=normal >nul 2>&1
netsh int tcp set global chimney=enabled >nul 2>&1
netsh int tcp set global dca=enabled >nul 2>&1
netsh int tcp set global netdma=enabled >nul 2>&1
netsh int tcp set global congestionprovider=ctcp >nul 2>&1
netsh int tcp set global ecncapability=disabled >nul 2>&1
echo [OK] TCP/IP nustatymai atnaujinti.

echo [3/3] Valoma DNS talpykla...
ipconfig /flushdns >nul
echo [OK] DNS isvalytas.

echo.
echo ============================================
echo    TINKLO OPTIMIZAVIMAS BAIGTAS! 🌐🚀
echo ============================================
echo.
echo Pakeitimai pritaikyti visiems aktyviems adapteriams.
echo Rekomenduojama perkrauti kompiuteri, kad visi 
echo draiveriu lygio pakeitimai pilnai isigaliotu.
echo.
pause
exit /b
