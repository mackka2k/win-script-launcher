@echo off
setlocal EnableDelayedExpansion
title Essential Apps Installer - Interactive

echo ============================================
echo    Essential Apps Installer (Interactive)
echo ============================================
echo.
echo This script will ask you which apps to install.
echo Press Y to install, N to skip each app.
echo.
pause

:: Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] WARNING: This script is not running as Administrator.
    echo Some installations might fail or require prompts.
    echo.
    pause
)

echo.
echo ============================================
echo    SELECT APPS TO INSTALL
echo ============================================
echo.

:: Counter for selected apps
set count=0

:: Apps list with descriptions
call :ask_install "7-Zip" "7zip.7zip" "File archiver"
call :ask_install "Brave Browser" "Brave.Brave" "Privacy-focused browser"
call :ask_install "Discord" "Discord.Discord" "Communication platform"
call :ask_install "Telegram" "Telegram.TelegramDesktop" "Messaging app"
call :ask_install "VLC Media Player" "VideoLAN.VLC" "Media player"
call :ask_install "qBittorrent" "qBittorrent.qBittorrent" "Torrent client"
call :ask_install "Steam" "Valve.Steam" "Gaming platform"
call :ask_install "WinDirStat" "WinDirStat.WinDirStat" "Disk space analyzer"
call :ask_install "Zed" "zed-industries.zed" "Modern code editor"
call :ask_install "Notepad++" "Notepad++.Notepad++" "Text editor"
call :ask_install "Git" "Git.Git" "Version control"
call :ask_install "Python 3.12" "Python.Python.3.12" "Programming language"
call :ask_install "Node.js LTS" "OpenJS.NodeJS.LTS" "JavaScript runtime"
call :ask_install "Windows Terminal" "Microsoft.WindowsTerminal" "Modern terminal"
call :ask_install "PowerShell 7" "Microsoft.PowerShell" "Advanced shell"
call :ask_install "DB Browser for SQLite" "DBBrowserForSQLite.DBBrowserForSQLite" "SQLite database tool"
call :ask_install "CrystalDiskInfo" "CrystalDewWorld.CrystalDiskInfo" "HDD/SSD health monitor"
call :ask_install "AnyDesk" "AnyDeskSoftwareGmbH.AnyDesk" "Remote desktop"
call :ask_install "Rufus" "Rufus.Rufus" "Bootable USB creator"

echo.
echo ============================================
echo    INSTALLATION SUMMARY
echo ============================================
echo.
echo Selected apps: %count%
echo.

if %count%==0 (
    echo No apps selected. Exiting...
    pause
    exit /b
)

choice /C YN /M "Start installation"
if errorlevel 2 (
    echo Installation cancelled.
    pause
    exit /b
)

echo.
echo ============================================
echo    INSTALLING SELECTED APPS
echo ============================================
echo.

:: Install selected apps
for /f "tokens=1,2 delims=|" %%a in ('set selected_ 2^>nul') do (
    for /f "tokens=2 delims==" %%c in ("%%a") do (
        echo --------------------------------------------
        echo [^>] Installing: %%c
        echo --------------------------------------------
        winget install --id %%c --silent --accept-package-agreements --accept-source-agreements
        if !errorlevel! equ 0 (
            echo.
            echo [OK] Success: %%c
        ) else (
            echo.
            echo [!] Failed or already installed: %%c
        )
        echo.
    )
)

echo.
echo ============================================
echo    Installation Process Complete!
echo ============================================
echo.
pause
exit /b

:: Function to ask if user wants to install an app
:ask_install
set "app_name=%~1"
set "app_id=%~2"
set "app_desc=%~3"

choice /C YN /M "Install %app_name% (%app_desc%)"
if errorlevel 2 (
    echo [SKIP] %app_name%
    echo.
    goto :eof
)

echo [SELECT] %app_name%
set /a count+=1
set "selected_%count%=%app_id%"
echo.
goto :eof
