@echo off
echo ============================================
echo    Prevent Sleep Mode
echo ============================================
echo.
echo 1. Prevent Sleep
echo 2. Restore Normal Settings
echo.
set /p choice="Enter choice (1 or 2): "

if "%choice%"=="1" (
    echo.
    echo Preventing sleep...
    powercfg -change -standby-timeout-ac 0
    powercfg -change -standby-timeout-dc 0
    echo Done! Computer will not sleep.
) else if "%choice%"=="2" (
    echo.
    echo Restoring normal settings...
    powercfg -change -standby-timeout-ac 30
    powercfg -change -standby-timeout-dc 15
    echo Done! Normal sleep settings restored.
) else (
    echo Invalid choice.
)

echo.
pause
