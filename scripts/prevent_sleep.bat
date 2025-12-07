@echo off
echo ============================================
echo    Prevent Sleep Mode
echo ============================================
echo.
echo This script will prevent your computer from sleeping.
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

:menu
echo.
echo ============================================
echo    Options:
echo ============================================
echo.
echo 1. Prevent sleep INDEFINITELY (until manually stopped)
echo 2. Prevent sleep for 1 hour
echo 3. Prevent sleep for 2 hours
echo 4. Prevent sleep for 4 hours
echo 5. Restore normal sleep settings
echo 6. Exit
echo.
set /p choice="Enter your choice (1-6): "

if "%choice%"=="1" goto indefinite
if "%choice%"=="2" goto onehour
if "%choice%"=="3" goto twohours
if "%choice%"=="4" goto fourhours
if "%choice%"=="5" goto restore
if "%choice%"=="6" goto end

echo Invalid choice. Please try again.
goto menu

:indefinite
echo.
echo Preventing sleep indefinitely...
powercfg -change -standby-timeout-ac 0
powercfg -change -standby-timeout-dc 0
powercfg -change -monitor-timeout-ac 0
powercfg -change -monitor-timeout-dc 0
powercfg -change -disk-timeout-ac 0
powercfg -change -disk-timeout-dc 0
echo.
echo Done! Your computer will not sleep until you restore settings.
echo.
echo IMPORTANT: Remember to restore normal settings when done!
goto menu

:onehour
echo.
echo Preventing sleep for 1 hour...
powercfg -change -standby-timeout-ac 60
powercfg -change -standby-timeout-dc 60
echo.
echo Done! Sleep disabled for 1 hour.
goto menu

:twohours
echo.
echo Preventing sleep for 2 hours...
powercfg -change -standby-timeout-ac 120
powercfg -change -standby-timeout-dc 120
echo.
echo Done! Sleep disabled for 2 hours.
goto menu

:fourhours
echo.
echo Preventing sleep for 4 hours...
powercfg -change -standby-timeout-ac 240
powercfg -change -standby-timeout-dc 240
echo.
echo Done! Sleep disabled for 4 hours.
goto menu

:restore
echo.
echo Restoring normal sleep settings...
powercfg -change -standby-timeout-ac 30
powercfg -change -standby-timeout-dc 15
powercfg -change -monitor-timeout-ac 15
powercfg -change -monitor-timeout-dc 10
powercfg -change -disk-timeout-ac 20
powercfg -change -disk-timeout-dc 10
echo.
echo Done! Normal sleep settings restored.
echo (Sleep after 30 min on AC, 15 min on battery)
goto menu

:end
echo.
echo Exiting...
pause
