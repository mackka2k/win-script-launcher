@echo off
echo ============================================
echo    Windows Defender Toggle
echo ============================================
echo.
echo This script allows you to enable or disable Windows Defender.
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
echo Checking current status...
echo.

:: Check current status
powershell -NoProfile -Command "$status = Get-MpPreference -ErrorAction SilentlyContinue; if ($status) { if ($status.DisableRealtimeMonitoring) { Write-Host 'Current Status: ' -NoNewline; Write-Host 'DISABLED' -ForegroundColor Red } else { Write-Host 'Current Status: ' -NoNewline; Write-Host 'ENABLED' -ForegroundColor Green } } else { Write-Host 'Unable to determine status.' -ForegroundColor Yellow }"

echo.
echo ============================================
echo    Options:
echo ============================================
echo.
echo 1. Disable Windows Defender (Real-time Protection)
echo 2. Enable Windows Defender (Real-time Protection)
echo 3. Disable All Protection (Real-time, Cloud, Samples)
echo 4. Enable All Protection (Full protection)
echo 5. Check Defender Status
echo 6. Exit
echo.
set /p choice="Enter your choice (1-6): "

if "%choice%"=="1" goto disable
if "%choice%"=="2" goto enable
if "%choice%"=="3" goto disableall
if "%choice%"=="4" goto enableall
if "%choice%"=="5" goto status
if "%choice%"=="6" goto end

echo Invalid choice. Please try again.
goto menu

:disable
echo.
echo Disabling Real-time Protection...
powershell -Command "Set-MpPreference -DisableRealtimeMonitoring $true" 2>nul
if %errorLevel% equ 0 (
    echo.
    echo Real-time Protection DISABLED successfully!
    echo.
    echo WARNING: Your computer is now less protected.
) else (
    echo.
    echo ERROR: Failed to disable. You may need to disable Tamper Protection first.
    echo Go to: Windows Security ^> Virus ^& threat protection ^> Manage settings
)
goto menu

:enable
echo.
echo Enabling Real-time Protection...
powershell -Command "Set-MpPreference -DisableRealtimeMonitoring $false" 2>nul
echo.
echo Real-time Protection ENABLED successfully!
goto menu

:disableall
echo.
echo Disabling ALL Windows Defender protection...
echo.
echo WARNING: This will disable all protection features!
set /p confirm="Are you sure? (Y/N): "
if /i not "%confirm%"=="Y" goto menu

powershell -NoProfile -Command "Set-MpPreference -DisableRealtimeMonitoring $true; Set-MpPreference -DisableBehaviorMonitoring $true; Set-MpPreference -DisableBlockAtFirstSeen $true; Set-MpPreference -DisableIOAVProtection $true; Set-MpPreference -DisableScriptScanning $true; Set-MpPreference -SubmitSamplesConsent 2; Set-MpPreference -MAPSReporting 0" 2>nul

if %errorLevel% equ 0 (
    echo.
    echo All protection features DISABLED!
) else (
    echo.
    echo ERROR: Some features could not be disabled.
    echo You may need to disable Tamper Protection first.
)
goto menu

:enableall
echo.
echo Enabling ALL Windows Defender protection...
powershell -NoProfile -Command "Set-MpPreference -DisableRealtimeMonitoring $false; Set-MpPreference -DisableBehaviorMonitoring $false; Set-MpPreference -DisableBlockAtFirstSeen $false; Set-MpPreference -DisableIOAVProtection $false; Set-MpPreference -DisableScriptScanning $false; Set-MpPreference -SubmitSamplesConsent 1; Set-MpPreference -MAPSReporting 2" 2>nul
echo.
echo All protection features ENABLED!
goto menu

:status
echo.
echo Detailed Status:
echo.
powershell -NoProfile -Command "$pref = Get-MpPreference; Write-Host 'Real-time Protection: ' -NoNewline; if ($pref.DisableRealtimeMonitoring) { Write-Host 'DISABLED' -ForegroundColor Red } else { Write-Host 'ENABLED' -ForegroundColor Green }; Write-Host 'Behavior Monitoring: ' -NoNewline; if ($pref.DisableBehaviorMonitoring) { Write-Host 'DISABLED' -ForegroundColor Red } else { Write-Host 'ENABLED' -ForegroundColor Green }; Write-Host 'Cloud Protection: ' -NoNewline; if ($pref.MAPSReporting -eq 0) { Write-Host 'DISABLED' -ForegroundColor Red } else { Write-Host 'ENABLED' -ForegroundColor Green }; Write-Host 'Sample Submission: ' -NoNewline; if ($pref.SubmitSamplesConsent -eq 2) { Write-Host 'DISABLED' -ForegroundColor Red } else { Write-Host 'ENABLED' -ForegroundColor Green }"
goto menu

:end
echo.
echo Exiting...
pause
