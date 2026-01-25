@echo off
setlocal EnableDelayedExpansion
title essential Apps Installer

echo ============================================
echo    essential Apps Installer (via Winget)
echo ============================================
echo.
echo This script will download and install the following apps:
echo - Notepad++, Brave, Discord, Microsoft Teams,
echo   qBitTorrent, Steam, Telegram, VLC, WinRAR
echo.

:: Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] WARNING: This script is not running as Administrator.
    echo installers may prompt for permission or fail.
    echo.
)

echo [?] Preparing installation...
echo.

:: Define apps in an array-like list
set "apps=Notepad++.Notepad++ Brave.Brave Discord.Discord Microsoft.Teams qBittorrent.qBittorrent Valve.Steam Telegram.TelegramDesktop VideoLAN.VLC RARLab.WinRAR WinDirStat.WinDirStat"

for %%a in (%apps%) do (
    echo --------------------------------------------
    echo [^>] Installing: %%a
    echo --------------------------------------------
    winget install --id %%a --silent --accept-package-agreements --accept-source-agreements
    if !errorlevel! equ 0 (
        echo.
        echo [OK] Success: %%a
    ) else (
        echo.
        echo [!] Failed or already installed: %%a
    )
    echo.
)

echo [?] Organizing shortcuts...
echo [?] Organizing shortcuts...
echo [?] Organizing shortcuts...
powershell -Command "$shell = New-Object -ComObject WScript.Shell; $desktop = [Environment]::GetFolderPath('Desktop'); $sDir = Join-Path $desktop 'Shortcuts'; if (-not (Test-Path $sDir)) { mkdir $sDir }; $apps = @(@{n='Brave'; t='brave.exe'}, @{n='Discord'; t='Discord.exe'}, @{n='Teams'; t='ms-teams.exe'}, @{n='qBittorrent'; t='qbittorrent.exe'}, @{n='Steam'; t='steam.exe'}, @{n='Telegram'; t='Telegram.exe'}, @{n='VLC'; t='vlc.exe'}, @{n='WinRAR'; t='WinRAR.exe'}, @{n='Notepad++'; t='notepad++.exe'}, @{n='WinDirStat'; t='windirstat.exe'}); foreach ($a in $apps) { $p = Join-Path $sDir ($a.n + '.lnk'); $exe = Get-Command $a.t -ErrorAction SilentlyContinue; $path = ''; if ($exe) { $path = $exe.Source } else { if ($a.n -eq 'Telegram') { $tp = \"$env:APPDATA\Telegram Desktop\Telegram.exe\"; if (Test-Path $tp) { $path = $tp } } elseif ($a.n -eq 'Teams') { $tp = (Get-AppxPackage *Teams* | Select-Object -ExpandProperty InstallLocation); if ($tp) { $tf = Get-ChildItem -Path $tp -Filter 'ms-teams.exe' -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName; if ($tf) { $path = $tf } }; if (-not $path) { $oldp = \"$env:LOCALAPPDATA\Microsoft\Teams\current\Teams.exe\"; if (Test-Path $oldp) { $path = $oldp } } } elseif ($a.n -eq 'WinDirStat') { $wp = \"$env:ProgramFiles\WinDirStat\WinDirStat.exe\"; if (Test-Path $wp) { $path = $wp } else { $wp2 = \"${env:ProgramFiles(x86)}\WinDirStat\WinDirStat.exe\"; if (Test-Path $wp2) { $path = $wp2 } } } }; if ($path) { if (Test-Path $p) { Remove-Item $p -Force }; $lnk = $shell.CreateShortcut($p); $lnk.TargetPath = $path; $lnk.Save(); Write-Host ('[SHORTCUT] ' + $a.n + ' added to Shortcuts') -ForegroundColor Cyan } }"

echo.
echo ============================================
echo    Installation Process Complete!
echo ============================================
echo.
pause
exit /b
