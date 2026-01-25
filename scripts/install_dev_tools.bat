@echo off
setlocal EnableDelayedExpansion
title Developer Tools Installer

echo ============================================
echo    Developer Tools Installer (via Winget)
echo ============================================
echo.
echo This script will install the essential dev environment:
echo - VS Code, Git, Python 3, Node.js (LTS),
echo   Windows Terminal, PowerShell 7, PowerToys
echo.

:: Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] WARNING: This script is not running as Administrator.
    echo some installations might fail or require prompts.
    echo.
)

echo [?] Preparing developer environment...
echo.

:: Define dev apps IDs
:: VS Code, Git, Python, Node, Terminal, PowerShell, PowerToys
set "dev_apps=Microsoft.VisualStudioCode Git.Git Python.Python.3.12 OpenJS.NodeJS.LTS Microsoft.WindowsTerminal Microsoft.PowerShell Microsoft.PowerToys"

for %%a in (%dev_apps%) do (
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
powershell -Command "$shell = New-Object -ComObject WScript.Shell; $desktop = [Environment]::GetFolderPath('Desktop'); $dDir = Join-Path $desktop 'Dev'; if (-not (Test-Path $dDir)) { mkdir $dDir }; $shortcuts = @(@{n='Windows Terminal'; t='wt.exe'; i='imageres.dll,-101'}, @{n='PowerShell 7'; t='pwsh.exe'; i='C:\Program Files\PowerShell\7\pwsh.exe,0'}, @{n='VS Code'; t='code.exe'}, @{n='Git Bash'; t='git-bash.exe'}, @{n='PowerToys'; t='PowerToys.exe'}); foreach ($s in $shortcuts) { $p = Join-Path $dDir ($s.n + '.lnk'); $exe = Get-Command $s.t -ErrorAction SilentlyContinue; $path = ''; if ($exe) { $path = $exe.Source } else { if ($s.n -eq 'VS Code') { $vsp = \"$env:ProgramFiles\Microsoft VS Code\Code.exe\"; if (Test-Path $vsp) { $path = $vsp } } elseif ($s.n -eq 'PowerShell 7') { $pp = 'C:\Program Files\PowerShell\7\pwsh.exe'; if (Test-Path $pp) { $path = $pp } } elseif ($s.n -eq 'PowerToys') { $ptp = \"$env:LOCALAPPDATA\PowerToys\PowerToys.exe\"; if (Test-Path $ptp) { $path = $ptp } else { $ptp2 = \"$env:ProgramFiles\PowerToys\PowerToys.exe\"; if (Test-Path $ptp2) { $path = $ptp2 } } } }; if ($path) { if (Test-Path $p) { Remove-Item $p -Force }; $lnk = $shell.CreateShortcut($p); $lnk.TargetPath = $path; if ($s.i) { $lnk.IconLocation = $s.i } elseif ($path -match 'pwsh\.exe') { $lnk.IconLocation = \"$path,0\" }; $lnk.Save(); Write-Host ('[SHORTCUT] ' + $s.n + ' added to Dev folder') -ForegroundColor Cyan } }"

echo.
echo ============================================
echo    Developer Environment Setup Complete!
echo ============================================
echo.
echo Note: You may need to restart your terminal or PC 
echo to see updated PATH variables (like python/git).
echo.
pause
exit /b
