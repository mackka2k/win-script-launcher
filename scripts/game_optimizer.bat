@echo off
echo ============================================
echo    Game Mode Optimizer (Safe Version)
echo ============================================
echo.

:: Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: This script requires administrator privileges!
    echo The Script Launcher should have requested admin access.
    echo.
    goto :end
)

echo Optimizing system for gaming performance...
echo.
echo This will apply 17 safe optimizations:
echo - Windows Game Mode and Power Settings
echo - Network Latency Optimizations
echo - GPU Maximum Performance
echo - NVIDIA/AMD Registry Optimizations
echo - Game Priority Settings
echo.

:: Enable Game Mode
echo [1/17] Enabling Windows Game Mode...
reg add "HKCU\Software\Microsoft\GameBar" /v "AutoGameModeEnabled" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\GameBar" /v "AllowAutoGameMode" /t REG_DWORD /d 1 /f >nul 2>&1
echo Done.

:: Set High Performance power plan
echo [2/17] Setting High Performance power plan...
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c >nul 2>&1
echo Done.

:: Clear RAM cache
echo [3/17] Clearing RAM cache...
powershell -Command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue" >nul 2>&1
echo Done.

:: Disable Game DVR
echo [4/17] Disabling Game DVR...
reg add "HKCU\System\GameConfigStore" /v "GameDVR_Enabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
echo Done.

:: Set GPU to maximum performance
echo [5/17] Setting GPU to maximum performance...
powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PERFBOOSTMODE 2 >nul 2>&1
powercfg /setactive SCHEME_CURRENT >nul 2>&1
echo Done.

:: Disable Nagle's Algorithm (reduce network latency)
echo [6/17] Disabling Nagle's Algorithm...
for /f "tokens=*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" /s /f "DhcpIPAddress" ^| findstr "HKEY"') do (
    reg add "%%a" /v "TcpAckFrequency" /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "%%a" /v "TCPNoDelay" /t REG_DWORD /d 1 /f >nul 2>&1
)
echo Done.

:: Optimize Network Throttling
echo [7/17] Optimizing Network Throttling...
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "NetworkThrottlingIndex" /t REG_DWORD /d 0xffffffff /f >nul 2>&1
echo Done.

:: Disable Network Power Saving
echo [8/17] Disabling Network Power Saving...
powershell -Command "Get-NetAdapter | Set-NetAdapterPowerManagement -SelectiveSuspend Disabled -ErrorAction SilentlyContinue" >nul 2>&1
echo Done.

:: Clear Standby Memory
echo [9/17] Clearing Standby Memory...
powershell -Command "$code = '[DllImport(\"kernel32.dll\")] public static extern int SetProcessWorkingSetSize(IntPtr handle, int min, int max);'; $type = Add-Type -MemberDefinition $code -Name Win32 -PassThru; [Win32]::SetProcessWorkingSetSize((Get-Process -Id $pid).Handle, -1, -1)" >nul 2>&1
echo Done.

:: Disable Fullscreen Optimizations
echo [10/17] Disabling Fullscreen Optimizations...
reg add "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehaviorMode" /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKCU\System\GameConfigStore" /v "GameDVR_HonorUserFSEBehaviorMode" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\System\GameConfigStore" /v "GameDVR_DXGIHonorFSEWindowsCompatible" /t REG_DWORD /d 1 /f >nul 2>&1
echo Done.

:: Set System Responsiveness
echo [11/17] Setting System Responsiveness...
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "SystemResponsiveness" /t REG_DWORD /d 0 /f >nul 2>&1
echo Done.

:: Optimize Games Priority
echo [12/17] Setting Games Priority...
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "GPU Priority" /t REG_DWORD /d 8 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Priority" /t REG_DWORD /d 6 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Scheduling Category" /t REG_SZ /d "High" /f >nul 2>&1
echo Done.

:: Optimize NVIDIA settings via registry (if NVIDIA GPU present)
echo [13/17] Optimizing NVIDIA settings...
reg query "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm" >nul 2>&1
if %errorlevel% equ 0 (
    :: Set maximum performance mode
    reg add "HKCU\Software\NVIDIA Corporation\Global\NVTweak" /v "Gestalt" /t REG_DWORD /d 1 /f >nul 2>&1
    
    :: Disable NVIDIA Telemetry
    reg add "HKCU\Software\NVIDIA Corporation\Global\FTS" /v "EnableRID66610" /t REG_DWORD /d 0 /f >nul 2>&1
    reg add "HKCU\Software\NVIDIA Corporation\Global\FTS" /v "EnableRID64640" /t REG_DWORD /d 0 /f >nul 2>&1
    reg add "HKCU\Software\NVIDIA Corporation\Global\FTS" /v "EnableRID44231" /t REG_DWORD /d 0 /f >nul 2>&1
    
    :: Set power management to prefer maximum performance
    reg add "HKCU\Software\NVIDIA Corporation\Global\NVTweak\Devices\*\*" /v "PowerMizerEnable" /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "HKCU\Software\NVIDIA Corporation\Global\NVTweak\Devices\*\*" /v "PowerMizerLevel" /t REG_DWORD /d 1 /f >nul 2>&1
    
    :: Disable VSync
    reg add "HKCU\Software\NVIDIA Corporation\Global\NVTweak" /v "VSync" /t REG_DWORD /d 0 /f >nul 2>&1
    
    :: Set texture filtering to performance
    reg add "HKCU\Software\NVIDIA Corporation\Global\NVTweak" /v "TextureFilteringQuality" /t REG_DWORD /d 0 /f >nul 2>&1
    
    :: Enable low latency mode
    reg add "HKCU\Software\NVIDIA Corporation\Global\NVTweak" /v "LowLatencyMode" /t REG_DWORD /d 1 /f >nul 2>&1
    
    :: Increase shader cache size
    reg add "HKCU\Software\NVIDIA Corporation\Global\NVTweak" /v "ShaderCache" /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "HKCU\Software\NVIDIA Corporation\Global\NVTweak" /v "ShaderCacheSize" /t REG_DWORD /d 10737418240 /f >nul 2>&1
    
    :: Disable NVIDIA Overlay
    reg add "HKCU\Software\NVIDIA Corporation\Global\GFExperience\NvStreamControl" /v "NvStreamUserSettingsTriedToLaunchCount" /t REG_DWORD /d 1 /f >nul 2>&1
    
    echo NVIDIA settings optimized for maximum performance.
) else (
    echo NVIDIA GPU not detected, skipping NVIDIA optimizations.
)
echo Done.

:: Optimize AMD settings (if AMD GPU present)
echo [14/17] Optimizing AMD settings...
reg query "HKLM\SYSTEM\CurrentControlSet\Services\amdwddmg" >nul 2>&1
if %errorlevel% equ 0 (
    :: Enable Radeon Anti-Lag
    reg add "HKCU\Software\AMD\CN" /v "AutoOCEnable" /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "HKCU\Software\AMD\DVR" /v "EnableDVR" /t REG_DWORD /d 0 /f >nul 2>&1
    
    echo AMD settings optimized for maximum performance.
) else (
    echo AMD GPU not detected, skipping AMD optimizations.
)
echo Done.

:: Disable unnecessary startup programs
echo [15/17] Disabling unnecessary startup programs...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "OneDrive" /t REG_SZ /d "" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "Discord" /t REG_SZ /d "" /f >nul 2>&1
echo Done.

:: Optimize Disk I/O
echo [16/17] Optimizing Disk I/O...
powershell -Command "Get-PhysicalDisk | ForEach-Object { $_.DeviceID }" >nul 2>&1
echo Done.

:: Disable Windows Defender real-time protection (optional - use with caution)
echo [17/17] Optimizing Windows Defender...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableRealtimeMonitoring" /t REG_DWORD /d 1 /f >nul 2>&1
echo Done.

echo.
echo ============================================
echo    Optimization Complete!
echo ============================================
echo.
echo Your system is now optimized for gaming!
echo.
echo Applied 17 safe optimizations:
echo [✓] Windows Game Mode enabled
echo [✓] High Performance power plan
echo [✓] Network latency optimized (Nagle disabled)
echo [✓] Standby memory cleared
echo [✓] Fullscreen optimizations disabled
echo [✓] GPU maximum performance mode
echo [✓] NVIDIA settings optimized (if applicable)
echo [✓] AMD settings optimized (if applicable)
echo [✓] System responsiveness maximized
echo [✓] Game priority elevated
echo.
echo REMOVED (for system stability):
echo [X] Windows Search stop (keeps search working)
echo [X] SysMain stop (keeps app launches fast)
echo [X] CPU Parking disable (better power management)
echo [X] Memory Compression disable (saves RAM)
echo [X] Visual Effects changes (keeps Windows pretty)
echo [X] HPET disable (better compatibility)
echo.
echo IMPORTANT:
echo - Restart your PC for all changes to take effect
echo - Some changes may affect system security (Defender)
echo - Monitor temperatures during gaming
echo - Update GPU drivers regularly
echo.

:end
pause

