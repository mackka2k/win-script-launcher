@echo off
echo ============================================
echo    SSD Optimizer
echo ============================================
echo.

:: Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: This script requires administrator privileges!
    echo Please run as Administrator.
    echo.
    pause
    exit /b 1
)

echo This script will optimize your SSD for better performance and longevity.
echo.
echo Optimizations:
echo - Run TRIM command
echo - Disable defragmentation on SSDs
echo - Disable Superfetch (if not already disabled)
echo - Disable Prefetch on SSDs
echo - Enable TRIM scheduling
echo.

echo [1/5] Running TRIM command...
defrag C: /L >nul 2>&1
echo Done.

echo [2/5] Disabling automatic defragmentation on SSDs...
schtasks /Change /TN "\Microsoft\Windows\Defrag\ScheduledDefrag" /Disable >nul 2>&1
echo Done.

echo [3/5] Optimizing Superfetch for SSD...
sc config SysMain start=disabled >nul 2>&1
sc stop SysMain >nul 2>&1
echo Done.

echo [4/5] Disabling Prefetch on SSD...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnablePrefetcher" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnableSuperfetch" /t REG_DWORD /d 0 /f >nul 2>&1
echo Done.

echo [5/5] Enabling TRIM scheduling...
fsutil behavior set DisableDeleteNotify 0 >nul 2>&1
echo Done.

echo.
echo ============================================
echo    SSD Optimization Complete!
echo ============================================
echo.
echo Applied optimizations:
echo [✓] TRIM command executed
echo [✓] Automatic defragmentation disabled
echo [✓] Superfetch disabled (reduces SSD wear)
echo [✓] Prefetch disabled for SSD
echo [✓] TRIM scheduling enabled
echo.
echo Your SSD is now optimized for:
echo - Better performance
echo - Longer lifespan
echo - Reduced unnecessary writes
echo.
echo NOTE: These settings are specifically for SSDs.
echo Do NOT use this script on traditional hard drives (HDDs).
echo.
pause
