@echo off
echo ============================================
echo    IP Information
echo ============================================
echo.

echo Gathering network information...
echo.

:: Get computer name
echo ============================================
echo    Computer Information
echo ============================================
echo Computer Name: %COMPUTERNAME%
echo User Name: %USERNAME%
echo.

:: Get network adapter information
echo ============================================
echo    Network Adapters
echo ============================================
ipconfig | findstr /C:"Ethernet adapter" /C:"Wireless LAN adapter" /C:"Wi-Fi adapter"
echo.

:: Get IP addresses
echo ============================================
echo    IP Addresses
echo ============================================
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /C:"IPv4 Address"') do echo Local IPv4:%%a
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /C:"IPv6 Address"') do echo Local IPv6:%%a
echo.

:: Get default gateway
echo ============================================
echo    Gateway
echo ============================================
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /C:"Default Gateway"') do echo Default Gateway:%%a
echo.

:: Get DNS servers
echo ============================================
echo    DNS Servers
echo ============================================
ipconfig /all | findstr /C:"DNS Servers"
echo.

:: Get public IP
echo ============================================
echo    Public IP Address
echo ============================================
echo Fetching public IP...
powershell -Command "(Invoke-WebRequest -Uri 'https://api.ipify.org' -UseBasicParsing).Content" 2>nul
if %errorlevel% neq 0 (
    echo Unable to fetch public IP. Check internet connection.
)
echo.

:: Get MAC address
echo ============================================
echo    MAC Addresses
echo ============================================
getmac /v /fo list | findstr /C:"Physical Address" /C:"Connection Name"
echo.

:: Network statistics
echo ============================================
echo    Network Statistics
echo ============================================
netstat -e
echo.

:: Active connections
echo ============================================
echo    Active Connections (Top 10)
echo ============================================
netstat -n | findstr ESTABLISHED | more +0
echo.

:: DNS cache
echo ============================================
echo    DNS Cache (Sample)
echo ============================================
ipconfig /displaydns | findstr /C:"Record Name" | more +0
echo.

echo ============================================
echo    Information Complete!
echo ============================================
echo.
pause
