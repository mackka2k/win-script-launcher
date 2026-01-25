@echo off
setlocal
title Dark Wallpaper Setter

echo ============================================
echo    Dark Wallpaper Setter
echo ============================================
echo.
echo This script will set a premium dark theme wallpaper.
echo.

set "WALLPAPER_PATH=%~dp0assets\6227297.jpg"

if not exist "%WALLPAPER_PATH%" (
    echo ERROR: Wallpaper file not found at %WALLPAPER_PATH%
    pause
    exit /b 1
)

echo Setting wallpaper...
echo.

:: Use PowerShell to set the wallpaper and refresh the system
powershell -Command "$code = 'using System; using System.Runtime.InteropServices; public class Wallpaper { [DllImport(\"user32.dll\", CharSet=CharSet.Auto)] public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni); }'; Add-Type -TypeDefinition $code; [Wallpaper]::SystemParametersInfo(20, 0, '%WALLPAPER_PATH%', 3) | Out-Null"

if %errorlevel% equ 0 (
    echo.
    echo ============================================
    echo    Wallpaper Updated!
    echo ============================================
    echo.
    echo Your desktop is now in Dark Mode.
) else (
    echo.
    echo ERROR: Failed to set wallpaper.
)

echo.
pause
endlocal
exit /b
