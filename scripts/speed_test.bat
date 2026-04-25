@echo off
setlocal EnableExtensions
title Speed Test
echo ============================================
echo    Network Speed Test
echo ============================================
echo.
echo This script will test your internet connection speed.
echo.

echo Testing network connection...
echo.

:: Test basic connectivity
echo [1/3] Checking internet connectivity...
ping -n 1 8.8.8.8 >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: No internet connection detected.
    echo Please check your network connection and try again.
    pause
    exit /b 1
)
echo Connected to internet.
echo.

:: Test download speed using PowerShell
echo [2/3] Testing download speed...
echo This may take 10-30 seconds...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0assets\speed_test_inline_1.ps1"

echo.

:: Test latency
echo [3/3] Testing latency (ping)...
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0assets\speed_test_inline_2.ps1"

echo.
echo ============================================
echo    Speed Test Complete!
echo ============================================
echo.
pause
