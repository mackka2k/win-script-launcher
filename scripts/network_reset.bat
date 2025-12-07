@echo off
echo ============================================
echo    Network Reset Tool
echo ============================================
echo.
echo This script will completely reset your network settings.
echo Administrator privileges are required.
echo.
echo WARNING: This will disconnect you from the internet temporarily.
echo You may need to reconnect to WiFi after completion.
echo.

:: Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: This script requires administrator privileges.
    echo Please run as administrator.
    pause
    exit /b 1
)

echo Press any key to continue or close this window to cancel...
pause >nul

echo.
echo Starting network reset...
echo.

:: Reset IP Configuration
echo [1/6] Releasing IP configuration...
ipconfig /release >nul 2>&1
echo Done.

:: Flush DNS Cache
echo [2/6] Flushing DNS cache...
ipconfig /flushdns >nul 2>&1
echo Done.

:: Reset Winsock
echo [3/6] Resetting Winsock catalog...
netsh winsock reset >nul 2>&1
echo Done.

:: Reset TCP/IP Stack
echo [4/6] Resetting TCP/IP stack...
netsh int ip reset >nul 2>&1
echo Done.

:: Renew IP Configuration
echo [5/6] Renewing IP configuration...
ipconfig /renew >nul 2>&1
echo Done.

:: Reset Firewall
echo [6/6] Resetting Windows Firewall...
netsh advfirewall reset >nul 2>&1
echo Done.

echo.
echo ============================================
echo    Network Reset Complete!
echo ============================================
echo.
echo Your network has been reset successfully.
echo Please restart your computer for all changes to take effect.
echo.
pause
