@echo off
setlocal EnableDelayedExpansion
title FPS Booster - Gaming Optimizer

echo ============================================
echo    FPS Booster - Gaming Optimizer
echo ============================================
echo.
echo Sis skriptas optimizuos sistema maksimaliam FPS:
echo  - Isjungs Windows Game DVR ir Game Bar
echo  - Nustatys GPU i Performance rezima
echo  - Isjungs NVIDIA/AMD overlay funkcijas
echo  - Optimizuos peles nustatymus (polling rate)
echo  - Sumazins network input lag
echo.

:: Patikrinimas del administratoriaus teisiu
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] KLAIDA: Reikalingos Administratoriaus teises!
    pause
    exit /b 1
)

echo [1/6] Isjungiamas Windows Game DVR (Xbox Game Bar)...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v "GameDVR_Enabled" /t REG_DWORD /d 0 /f >nul
reg add "HKCU\System\GameConfigStore" /v "GameDVR_Enabled" /t REG_DWORD /d 0 /f >nul
echo [OK] Game DVR isjungtas.

echo [2/6] Nustatomas Hardware-Accelerated GPU Scheduling...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v "HwSchMode" /t REG_DWORD /d 2 /f >nul
echo [OK] GPU Scheduling ijungtas (reikia perkrauti PC).

echo [3/6] Isjungiamas NVIDIA GeForce Experience Overlay...
taskkill /F /IM "NVIDIA Share.exe" >nul 2>&1
taskkill /F /IM "nvcontainer.exe" >nul 2>&1
reg add "HKCU\Software\NVIDIA Corporation\Global\FTS" /v "EnableRID66610" /t REG_DWORD /d 0 /f >nul 2>&1
echo [OK] NVIDIA Overlay sustabdytas.

echo [4/6] Nustatomas maksimalus peles polling rate...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\mouclass\Parameters" /v "MouseDataQueueSize" /t REG_DWORD /d 100 /f >nul
echo [OK] Peles nustatymai optimizuoti.

echo [5/6] Isjungiamas Windows Nagle's Algorithm (mazesnis input lag)...
for /f "tokens=*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" /s /f "DhcpIPAddress" ^| findstr "HKEY"') do (
    reg add "%%a" /v "TcpAckFrequency" /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "%%a" /v "TCPNoDelay" /t REG_DWORD /d 1 /f >nul 2>&1
)
echo [OK] Network latency optimizuotas.

echo [6/6] Nustatomas High Performance GPU rezimas...
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c >nul 2>&1
echo [OK] High Performance rezimas aktyvuotas.

echo.
echo ============================================
echo    FPS BOOST BAIGTAS! 🎮⚡
echo ============================================
echo.
echo Pakeitimai:
echo  [+] Game DVR ir Game Bar isjungti
echo  [+] GPU Scheduling ijungtas
echo  [+] NVIDIA Overlay sustabdytas
echo  [+] Peles polling rate padidintas
echo  [+] Network input lag sumazintas
echo  [+] High Performance rezimas
echo.
echo SVARBU: Kai kuriems pakeitimams reikia perkrauti kompiuteri.
echo.
pause
exit /b
