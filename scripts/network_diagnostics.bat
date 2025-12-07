@echo off
echo ============================================
echo    Network Diagnostics Script
echo ============================================
echo.

:: Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo WARNING: Some commands require administrator privileges.
    echo.
)

echo [1/6] Testing Internet Connectivity...
ping -n 4 8.8.8.8
echo.

echo [2/6] DNS Resolution Test...
nslookup google.com
echo.

echo [3/6] Network Configuration...
ipconfig /all
echo.

echo [4/6] Active Network Connections...
netstat -ano | findstr ESTABLISHED
echo.

echo [5/6] Route Table...
route print
echo.

echo [6/6] Network Adapter Status...
netsh interface show interface
echo.

echo ============================================
echo    Diagnostics Complete!
echo ============================================
pause
