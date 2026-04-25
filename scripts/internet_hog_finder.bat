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

powershell -File "%~dp0assets\internet_hog_finder_inline_1.ps1"

echo ----------------------------------------------------------------------
echo.
echo Isvada: Visos auksciau isvardintos programos dabar turi aktyvu rysi.
echo Jei matote kazka itartino, naudokite 'Port Killer' arba 'Task Manager'.
echo.
pause
exit /b
