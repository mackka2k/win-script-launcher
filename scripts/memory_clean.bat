@echo off
setlocal EnableExtensions
title Memory Clean


set "SCRIPT_BACKUP_TARGETS=files"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0assets\common_backup.ps1" -ScriptName "%~nx0" -Targets %SCRIPT_BACKUP_TARGETS%
if errorlevel 1 (
    echo [!] Backup guard failed.
    choice /C YN /N /M "Continue without backup? (Y/N): "
    if errorlevel 2 exit /b 1
)

del /s /f /q %temp%\*.*
del /s /f /q %WinDir%\temp\*.*
rmdir /s /q "C:\Windows\Prefetch"
del "%USERPROFILE%\AppData\Local\cache" /f /q /s
del %AppData%\Origin\Telemetry /F /Q
del %AppData%\Origin\Logs /F /Q
DEL /F /S /Q /A %LocalAppData%\Microsoft\Windows\Explorer\thumbcache_*.db
echo 19. Temp and Cache has been cleared
