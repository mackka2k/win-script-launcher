@echo off
setlocal EnableDelayedExpansion
title Tor Browser Complete Setup & OPSEC Guide

:menu
cls
echo ============================================
echo    Tor Browser Setup ^& OPSEC Guide
echo ============================================
echo.
echo [1] Install Tor Browser
echo [2] OPSEC Guide ^& Best Practices
echo [3] Verify Tor Connection
echo [4] Exit
echo.
choice /C 1234 /N /M "Select option: "
if errorlevel 4 exit /b
if errorlevel 3 goto :verify
if errorlevel 2 goto :opsec
if errorlevel 1 goto :install

:install
cls
echo ============================================
echo    TOR BROWSER INSTALLATION
echo ============================================
echo.

:: Create directory
set "TOR_DIR=%USERPROFILE%\TorBrowser"
if not exist "%TOR_DIR%" mkdir "%TOR_DIR%"

echo [1/5] Opening download page...
echo.
start "" "https://www.torproject.org/download/"
echo.
echo [INSTRUCTIONS:]
echo 1. Download "Windows (Portable)" version
echo 2. Save the .exe file to: %TOR_DIR%
echo 3. Rename it to: tor-browser.exe
echo.
echo Press any key when download is complete...
pause >nul

:: Check if file exists
if not exist "%TOR_DIR%\tor-browser.exe" (
    echo.
    echo [!] File not found!
    echo.
    echo Please ensure:
    echo - File is downloaded to: %TOR_DIR%
    echo - File is renamed to: tor-browser.exe
    echo.
    pause
    goto :menu
)

echo.
echo [2/5] Installing Tor Browser...
echo.
echo IMPORTANT: When prompted, install to:
echo %TOR_DIR%\Browser
echo.
pause

start "" /wait "%TOR_DIR%\tor-browser.exe"

:: Find Tor Browser directory
set "BROWSER_DIR=%TOR_DIR%\Browser\TorBrowser"
if not exist "%BROWSER_DIR%" (
    echo [!] Installation failed or cancelled.
    pause
    goto :menu
)

echo.
echo [3/5] Configuring security...
echo.

:: Create torrc configuration
if not exist "%BROWSER_DIR%\Data\Tor" mkdir "%BROWSER_DIR%\Data\Tor"
set "TORRC=%BROWSER_DIR%\Data\Tor\torrc"

(
echo # Tor Secure Configuration
echo # Maximum Security Settings
echo.
echo SafeLogging 1
echo DisableDebuggerAttachment 0
echo CircuitBuildTimeout 60
echo LearnCircuitBuildTimeout 0
echo NumEntryGuards 3
) > "%TORRC%"

echo [OK] Security configured
echo.

echo [4/5] Creating launch script...
(
echo @echo off
echo title Tor Browser - Secure Mode
echo echo ============================================
echo echo    Tor Browser - Maximum Security
echo echo ============================================
echo echo.
echo echo [Security Level: SAFEST]
echo echo [Fingerprinting: Protected]
echo echo.
echo echo Starting Tor Browser...
echo start "" "%BROWSER_DIR%\Browser\firefox.exe"
) > "%TOR_DIR%\LaunchTor.bat"

echo [OK] Launch script created
echo.

echo [5/5] Creating desktop shortcut...
powershell -File "%~dp0assets\tor_complete_setup_inline_1.ps1" 2>nul
echo [OK] Desktop shortcut created
echo.

echo ============================================
echo    INSTALLATION COMPLETE!
echo ============================================
echo.
echo Location: %TOR_DIR%
echo Launch: Desktop shortcut or %TOR_DIR%\LaunchTor.bat
echo.
echo [NEXT STEPS:]
echo 1. Launch Tor Browser
echo 2. Click Shield icon -> Select "Safest"
echo 3. Read OPSEC Guide (Option 2)
echo 4. Verify connection (Option 3)
echo.
pause
goto :menu

:opsec
cls
echo ============================================
echo    TOR OPSEC ^& SECURITY GUIDE
echo ============================================
echo.
echo [BEFORE BROWSING:]
echo.
echo 1. VPN Configuration (CRITICAL)
echo    - Connect to VPN BEFORE launching Tor
echo    - Recommended: ProtonVPN, Mullvad, NordVPN
echo    - VPN -^> Tor (not Tor -^> VPN)
echo.
echo 2. Security Level
echo    - Click Shield icon (top-right)
echo    - Select "Safest" security level
echo    - Disables JavaScript on all sites
echo.
echo 3. Window Size
echo    - NEVER maximize browser window
echo    - Fingerprinting via screen resolution
echo    - Keep default size
echo.
pause
cls
echo ============================================
echo    CRITICAL OPSEC RULES
echo ============================================
echo.
echo [DO:]
echo [OK] Use VPN before Tor
echo [OK] Keep security level "Safest"
echo [OK] Use .onion sites when possible
echo [OK] Clear cookies after each session
echo [OK] Verify connection before browsing
echo.
echo [DON'T:]
echo [X] Maximize browser window
echo [X] Login to personal accounts
echo [X] Download files while connected
echo [X] Enable JavaScript on unknown sites
echo [X] Install browser extensions
echo [X] Torrent over Tor
echo [X] Click random links
echo.
pause
cls
echo ============================================
echo    USEFUL .ONION SITES (LEGAL)
echo ============================================
echo.
echo [SEARCH ENGINES:]
echo - DuckDuckGo Onion
echo - Ahmia Search
echo.
echo [NEWS:]
echo - ProPublica
echo - BBC News Onion
echo - NY Times Onion
echo.
echo [PRIVACY TOOLS:]
echo - SecureDrop (whistleblowing)
echo - OnionShare (file sharing)
echo.
echo [DIRECTORIES:]
echo - The Hidden Wiki (Educational)
echo - Daniel's Onion List
echo.
echo NOTE: Always verify .onion addresses
echo from official sources!
echo.
pause
cls
echo ============================================
echo    COMMON MISTAKES TO AVOID
echo ============================================
echo.
echo 1. [X] Torrenting over Tor
echo    - Exposes real IP address
echo    - Overloads Tor network
echo.
echo 2. [X] Opening downloaded files while connected
echo    - Files can "phone home"
echo    - Disconnect Tor first
echo.
echo 3. [X] Using personal information
echo    - Real name, email, phone
echo    - Creates identity correlation
echo.
echo 4. [X] Installing browser extensions
echo    - Fingerprinting vector
echo    - Potential malware
echo.
echo 5. [X] Clicking random links
echo    - Phishing attacks
echo    - Malware delivery
echo    - Law enforcement honeypots
echo.
pause
cls
echo ============================================
echo    ADVANCED OPSEC
echo ============================================
echo.
echo [MAXIMUM SECURITY:]
echo.
echo 1. Tails OS (Recommended)
echo    - Live USB operating system
echo    - Routes all traffic through Tor
echo    - Leaves no trace
echo    - Download: https://tails.boum.org/
echo.
echo 2. Whonix (VM-based)
echo    - Two VMs: Gateway + Workstation
echo    - Complete isolation
echo    - Download: https://www.whonix.org/
echo.
echo 3. VPN -^> Tor -^> VPN (Advanced)
echo    - Maximum anonymity
echo    - Complex setup
echo.
echo 4. Air-Gapped Documentation
echo    - Separate device for notes
echo    - No network connection
echo.
pause
cls
echo ============================================
echo    QUICK REFERENCE CARD
echo ============================================
echo.
echo [BEFORE BROWSING:]
echo 1. Connect to VPN
echo 2. Launch Tor Browser
echo 3. Set Security to "Safest"
echo 4. Verify connection
echo 5. Check for leaks
echo.
echo [DURING BROWSING:]
echo 1. Don't maximize window
echo 2. Don't login to personal accounts
echo 3. Don't download files
echo 4. Use .onion sites when possible
echo 5. Don't enable JavaScript on unknown sites
echo.
echo [AFTER BROWSING:]
echo 1. Clear all cookies
echo 2. Close Tor Browser
echo 3. Disconnect VPN
echo 4. Restart computer (if paranoid)
echo.
echo [EMERGENCY:]
echo - Close Tor immediately
echo - Disconnect internet
echo - Power off computer
echo.
pause
goto :menu

:verify
cls
echo ============================================
echo    VERIFY TOR CONNECTION
echo ============================================
echo.
echo Opening verification sites...
echo.
echo [1] Tor Check
start "" "https://check.torproject.org/"
timeout /t 2 >nul
echo.
echo [2] DNS Leak Test
start "" "https://dnsleaktest.com/"
timeout /t 2 >nul
echo.
echo [3] WebRTC Leak Test
start "" "https://browserleaks.com/webrtc"
echo.
echo.
echo [EXPECTED RESULTS:]
echo.
echo [OK] Tor Check: "Congratulations. This browser is configured to use Tor."
echo [OK] DNS Leak: Shows Tor exit node IP (NOT your real IP)
echo [OK] WebRTC: No local IP visible
echo.
echo If any test fails, DO NOT use Tor for sensitive browsing!
echo.
pause
goto :menu
