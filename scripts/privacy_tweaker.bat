@echo off
echo ============================================
echo    Windows Privacy Tweaker
echo ============================================
echo.

:: Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: This script requires administrator privileges!
    echo Please run as Administrator.
    echo.
    pause
    exit /b 1
)

echo This script will disable Windows telemetry and tracking.
echo.
echo Changes include:
echo - Disable telemetry and data collection
echo - Turn off advertising ID
echo - Disable activity history
echo - Stop location tracking
echo - Disable feedback requests
echo - Turn off app suggestions
echo - Disable Cortana (optional)
echo.
echo Press any key to continue or Ctrl+C to cancel...
pause >nul

echo.
echo Applying privacy tweaks...
echo.

:: Disable Telemetry
echo [1/15] Disabling telemetry...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f >nul 2>&1
sc config DiagTrack start=disabled >nul 2>&1
sc stop DiagTrack >nul 2>&1
echo Done.

:: Disable Advertising ID
echo [2/15] Disabling advertising ID...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v "Enabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" /v "DisabledByGroupPolicy" /t REG_DWORD /d 1 /f >nul 2>&1
echo Done.

:: Disable Activity History
echo [3/15] Disabling activity history...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "EnableActivityFeed" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "PublishUserActivities" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "UploadUserActivities" /t REG_DWORD /d 0 /f >nul 2>&1
echo Done.

:: Disable Location Tracking
echo [4/15] Disabling location tracking...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" /v "DisableLocation" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" /v "DisableWindowsLocationProvider" /t REG_DWORD /d 1 /f >nul 2>&1
echo Done.

:: Disable Feedback Requests
echo [5/15] Disabling feedback requests...
reg add "HKCU\Software\Microsoft\Siuf\Rules" /v "NumberOfSIUFInPeriod" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "DoNotShowFeedbackNotifications" /t REG_DWORD /d 1 /f >nul 2>&1
echo Done.

:: Disable App Suggestions
echo [6/15] Disabling app suggestions...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SystemPaneSuggestionsEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SilentInstalledAppsEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "PreInstalledAppsEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "OemPreInstalledAppsEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
echo Done.

:: Disable Tailored Experiences
echo [7/15] Disabling tailored experiences...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Privacy" /v "TailoredExperiencesWithDiagnosticDataEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
echo Done.

:: Disable Cortana
echo [8/15] Disabling Cortana...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortana" /t REG_DWORD /d 0 /f >nul 2>&1
echo Done.

:: Disable Web Search in Start Menu
echo [9/15] Disabling web search in Start Menu...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "DisableWebSearch" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "ConnectedSearchUseWeb" /t REG_DWORD /d 0 /f >nul 2>&1
echo Done.

:: Disable Cloud Clipboard
echo [10/15] Disabling cloud clipboard...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "AllowClipboardHistory" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "AllowCrossDeviceClipboard" /t REG_DWORD /d 0 /f >nul 2>&1
echo Done.

:: Disable Timeline
echo [11/15] Disabling timeline...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "EnableActivityFeed" /t REG_DWORD /d 0 /f >nul 2>&1
echo Done.

:: Disable Windows Tips
echo [12/15] Disabling Windows tips...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableSoftLanding" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsSpotlightFeatures" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsConsumerFeatures" /t REG_DWORD /d 1 /f >nul 2>&1
echo Done.

:: Disable App Diagnostics
echo [13/15] Disabling app diagnostics...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Privacy" /v "AppDiagnosticsEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
echo Done.

:: Disable Inking & Typing Personalization
echo [14/15] Disabling inking and typing personalization...
reg add "HKCU\Software\Microsoft\Personalization\Settings" /v "AcceptedPrivacyPolicy" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\InputPersonalization" /v "RestrictImplicitTextCollection" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\InputPersonalization" /v "RestrictImplicitInkCollection" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\InputPersonalization\TrainedDataStore" /v "HarvestContacts" /t REG_DWORD /d 0 /f >nul 2>&1
echo Done.

:: Disable Windows Error Reporting
echo [15/15] Disabling Windows Error Reporting...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" /v "Disabled" /t REG_DWORD /d 1 /f >nul 2>&1
sc config WerSvc start=disabled >nul 2>&1
sc stop WerSvc >nul 2>&1
echo Done.

echo.
echo ============================================
echo    Privacy Tweaks Applied!
echo ============================================
echo.
echo The following privacy settings have been disabled:
echo [✓] Telemetry and data collection
echo [✓] Advertising ID
echo [✓] Activity history and timeline
echo [✓] Location tracking
echo [✓] Feedback requests
echo [✓] App suggestions and tips
echo [✓] Tailored experiences
echo [✓] Cortana
echo [✓] Web search in Start Menu
echo [✓] Cloud clipboard sync
echo [✓] Windows tips and spotlight
echo [✓] App diagnostics
echo [✓] Inking and typing personalization
echo [✓] Windows Error Reporting
echo.
echo IMPORTANT:
echo - Restart your PC for all changes to take effect
echo - Some features (Cortana, Timeline) will be disabled
echo - You can re-enable features in Windows Settings if needed
echo - This does NOT remove apps (use Windows Debloater for that)
echo.
pause
