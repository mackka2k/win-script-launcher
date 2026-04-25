@echo off
setlocal EnableExtensions
title HYPER Teams Status Jiggler - ACTIVE (1s)
color 0A

echo ===================================================
echo             HYPER JIGGLER IS ACTIVE
echo ===================================================
echo.
echo Jiggling mouse 50 pixels EVERY SECOND.
echo.
echo Press Ctrl+C or close this window to stop.
echo ===================================================
echo.

:: Launch powershell loop that moves mouse every 1 second
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0assets\mouse_jiggler_inline_1.ps1"
