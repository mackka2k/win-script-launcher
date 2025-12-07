@echo off
echo ============================================
echo    NumLock Auto-ON Enabler
echo ============================================
echo.
echo This script will force NumLock to be ON at Windows startup.
echo Administrator privileges are required.
echo.

:: Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: This script requires administrator privileges.
    echo Please run as administrator.
    pause
    exit /b 1
)

echo Applying registry tweaks...
echo.

:: Registry key for current user (startup)
reg add "HKCU\Control Panel\Keyboard" /v "InitialKeyboardIndicators" /t REG_SZ /d "2" /f
echo [OK] Current User config updated.

:: Registry key for boot/login screen (users profile)
reg add "HKU\.DEFAULT\Control Panel\Keyboard" /v "InitialKeyboardIndicators" /t REG_SZ /d "2147483650" /f
echo [OK] Login Screen config updated.

echo.
echo ============================================
echo    Success!
echo ============================================
echo.
echo NumLock will now automatically turn ON when:
echo 1. You boot up the computer (Login Screen)
echo 2. You log in to your user account
echo.
echo Note: You may need to restart for changes to take effect.
echo.
pause
