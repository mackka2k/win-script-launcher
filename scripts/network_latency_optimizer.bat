@echo off
setlocal EnableDelayedExpansion
title Network Latency Optimizer (Ping Booster)

echo ============================================
echo    Network Latency Optimizer 🚀⚡
echo ============================================
echo.
echo Sis skriptas optimizuos tinklo nustatymus:
echo - Isjungs Nagle's algoritma (mazesnis velavimas)
echo - Panaikins tinklo droseliavima (Throttling)
echo - Optimizuos TCP parametrus zaidimams
echo.

:: Patikrinimas del administratoriaus teisiu
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] KLAIDA: Reikalingos Administratoriaus teises!
    echo Paleiskite si skripta per Script Launcher kaip Administratoriu.
    pause
    exit /b 1
)

echo [1/4] Optimizuojami TCP nustatymai...
:: TCP Globaliniai nustatymai
netsh int tcp set global autotuninglevel=normal >nul 2>&1
netsh int tcp set global chimney=enabled >nul 2>&1
netsh int tcp set global dca=enabled >nul 2>&1
netsh int tcp set global netdma=enabled >nul 2>&1
netsh int tcp set global ecncapability=disabled >nul 2>&1
netsh int tcp set global timestamps=disabled >nul 2>&1
netsh int tcp set global rss=enabled >nul 2>&1
echo [OK] TCP parametrai atnaujinti.

echo [2/4] Naikinamas Network Throttling...
:: Isjungiamas tinklo droseliavimas multimedijai
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "NetworkThrottlingIndex" /t REG_DWORD /d 0xffffffff /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "SystemResponsiveness" /t REG_DWORD /d 0 /f >nul 2>&1
echo [OK] Ribojimai pašalinti.

echo [3/4] Isjungiamas Nagle's algoritmas...
:: Randame aktyvias tinklo sasajas ir pritaikome TcpAckFrequency/TCPNoDelay
for /f "tokens=3" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkCards" /s ^| findstr /i "ServiceName"') do (
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\%%a" /v "TcpAckFrequency" /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\%%a" /v "TCPNoDelay" /t REG_DWORD /d 1 /f >nul 2>&1
)
echo [OK] Nagle's algoritmas išjungtas (Low Latency Mode).

echo [4/4] Valoma DNS talpykla...
ipconfig /flushdns >nul 2>&1
echo [OK] DNS isvalytas.

echo.
echo ============================================
echo    OPTIMIZAVIMAS BAIGTAS! ✨🎮
echo ============================================
echo Rekomenduojama perkrauti kompiuteri (Restart),
echo kad visi nustatymai isituinkintu.
echo.
pause
exit /b
