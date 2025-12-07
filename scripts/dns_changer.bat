@echo off
echo ============================================
echo    DNS Changer
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

:: Get active network adapter
echo Detecting active network adapter...
for /f "tokens=3*" %%i in ('netsh interface show interface ^| findstr /C:"Connected"') do set "ADAPTER=%%j"

if "%ADAPTER%"=="" (
    echo ERROR: No active network adapter found!
    echo.
    pause
    exit /b 1
)

echo Active adapter: %ADAPTER%
echo.
echo ============================================
echo    Select DNS Provider
echo ============================================
echo.
echo [1] Google DNS (8.8.8.8 / 8.8.4.4)
echo     - Fast and reliable
echo     - Good for general use
echo.
echo [2] Cloudflare DNS (1.1.1.1 / 1.0.0.1)
echo     - Fastest DNS resolver
echo     - Privacy-focused
echo     - Best for gaming (low latency)
echo.
echo [3] OpenDNS (208.67.222.222 / 208.67.220.220)
echo     - Family-friendly filtering
echo     - Phishing protection
echo.
echo [4] Quad9 DNS (9.9.9.9 / 149.112.112.112)
echo     - Security-focused
echo     - Blocks malicious domains
echo.
echo [5] AdGuard DNS (94.140.14.14 / 94.140.15.15)
echo     - Blocks ads and trackers
echo     - Privacy protection
echo.
echo [6] Automatic (DHCP)
echo     - Use router's DNS
echo     - Reset to default
echo.
echo [0] Cancel
echo.

choice /c 1234560 /n /m "Enter your choice (1-6 or 0): "
set CHOICE=%errorlevel%

if %CHOICE%==7 goto :end
if %CHOICE%==6 goto :auto
if %CHOICE%==5 goto :adguard
if %CHOICE%==4 goto :quad9
if %CHOICE%==3 goto :opendns
if %CHOICE%==2 goto :cloudflare
if %CHOICE%==1 goto :google

:google
echo.
echo Setting Google DNS...
netsh interface ip set dns name="%ADAPTER%" static 8.8.8.8 primary >nul
netsh interface ip add dns name="%ADAPTER%" 8.8.4.4 index=2 >nul
set "DNS_NAME=Google DNS"
set "PRIMARY=8.8.8.8"
set "SECONDARY=8.8.4.4"
goto :success

:cloudflare
echo.
echo Setting Cloudflare DNS...
netsh interface ip set dns name="%ADAPTER%" static 1.1.1.1 primary >nul
netsh interface ip add dns name="%ADAPTER%" 1.0.0.1 index=2 >nul
set "DNS_NAME=Cloudflare DNS"
set "PRIMARY=1.1.1.1"
set "SECONDARY=1.0.0.1"
goto :success

:opendns
echo.
echo Setting OpenDNS...
netsh interface ip set dns name="%ADAPTER%" static 208.67.222.222 primary >nul
netsh interface ip add dns name="%ADAPTER%" 208.67.220.220 index=2 >nul
set "DNS_NAME=OpenDNS"
set "PRIMARY=208.67.222.222"
set "SECONDARY=208.67.220.220"
goto :success

:quad9
echo.
echo Setting Quad9 DNS...
netsh interface ip set dns name="%ADAPTER%" static 9.9.9.9 primary >nul
netsh interface ip add dns name="%ADAPTER%" 149.112.112.112 index=2 >nul
set "DNS_NAME=Quad9 DNS"
set "PRIMARY=9.9.9.9"
set "SECONDARY=149.112.112.112"
goto :success

:adguard
echo.
echo Setting AdGuard DNS...
netsh interface ip set dns name="%ADAPTER%" static 94.140.14.14 primary >nul
netsh interface ip add dns name="%ADAPTER%" 94.140.15.15 index=2 >nul
set "DNS_NAME=AdGuard DNS"
set "PRIMARY=94.140.14.14"
set "SECONDARY=94.140.15.15"
goto :success

:auto
echo.
echo Setting DNS to Automatic (DHCP)...
netsh interface ip set dns name="%ADAPTER%" dhcp >nul
echo.
echo ============================================
echo    DNS Reset to Automatic!
echo ============================================
echo.
echo Your DNS is now set to automatic (DHCP).
echo You will use your router's DNS settings.
echo.
goto :flush

:success
echo Done.
echo.
echo ============================================
echo    DNS Changed Successfully!
echo ============================================
echo.
echo Provider: %DNS_NAME%
echo Primary DNS: %PRIMARY%
echo Secondary DNS: %SECONDARY%
echo Adapter: %ADAPTER%
echo.

:flush
echo Flushing DNS cache...
ipconfig /flushdns >nul
echo Done.
echo.
echo Your new DNS settings are now active!
echo.
pause

:end
pause

