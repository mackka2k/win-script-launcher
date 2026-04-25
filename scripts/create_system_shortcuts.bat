@echo off
setlocal
title System Shortcuts Creator

echo ============================================
echo    System Shortcuts Creator
echo ============================================
echo.
echo This script will add essential Windows tools to your
echo "Shortcuts" folder on the Desktop for quick access.
echo.

set "SYSTEM_DIR=%USERPROFILE%\Desktop\System"

if not exist "%SYSTEM_DIR%" (
    echo Creating System folder...
    mkdir "%SYSTEM_DIR%"
)

echo Adding shortcuts...
echo.

:: Use PowerShell to create the shortcuts with absolute paths and high-res icon resolution
powershell -File "%~dp0assets\create_system_shortcuts_inline_1.ps1"

echo.
echo ============================================
echo    Shortcuts Created!
echo ============================================
echo.
echo Check your Desktop\Shortcuts folder.
echo.
pause
exit /b
