@echo off
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
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$code = '[DllImport(\"user32.dll\")] public static extern void mouse_event(uint dwFlags, int dx, int dy, uint dwData, int dwExtraInfo);'; $mouse = Add-Type -MemberDefinition $code -Name 'MJ' -Namespace 'Win32' -PassThru; while ($true) { $mouse::mouse_event(0x0001, 50, 50, 0, 0); Start-Sleep -Milliseconds 100; $mouse::mouse_event(0x0001, -50, -50, 0, 0); Start-Sleep -Seconds 1; }"
