@echo off
setlocal EnableDelayedExpansion
title Internet Hog Finder

echo ============================================
echo      Internet Hog Finder (Real-time)
echo ============================================
echo.
echo Tikrinama, kokios programos naudoja tavo
echo interneto rysi siuo metu...
echo.

:: Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] WARNING: Kai kurios programos gali buti nematomos be Admin teisiu.
    echo.
)

echo [Skenuojama...]
echo ----------------------------------------------------------------------
echo Program Name              PID        Remote Address       Port
echo ----------------------------------------------------------------------

powershell -Command "Get-NetTCPConnection -State Established | ForEach-Object { $proc = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue; if ($proc) { $name = $proc.Name.PadRight(25).Substring(0,25); $idStr = $_.OwningProcess.ToString().PadRight(10); $remote = $_.RemoteAddress.ToString().PadRight(20); $port = $_.RemotePort.ToString(); Write-Host (\"$name $idStr $remote $port\") -ForegroundColor Cyan } }"

echo ----------------------------------------------------------------------
echo.
echo Isvada: Visos auksciau isvardintos programos dabar turi aktyvu rysi.
echo Jei matote kazka itartino, naudokite 'Port Killer' arba 'Task Manager'.
echo.
pause
exit /b
