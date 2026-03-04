@ECHO OFF

del /s /f /q %temp%\*.*
del /s /f /q %WinDir%\temp\*.*
rmdir /s /q "C:\Windows\Prefetch"
del "%USERPROFILE%\AppData\Local\cache" /f /q /s
del %AppData%\Origin\Telemetry /F /Q
del %AppData%\Origin\Logs /F /Q
DEL /F /S /Q /A %LocalAppData%\Microsoft\Windows\Explorer\thumbcache_*.db
echo 19. Temp and Cache has been cleared
