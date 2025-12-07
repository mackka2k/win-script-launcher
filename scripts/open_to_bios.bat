@echo off
echo ================================================
echo Opening BIOS/UEFI Settings
echo ================================================
echo.
echo This will restart your computer and open BIOS/UEFI settings.
echo You have 5 seconds to cancel (press Ctrl+C)
echo.
timeout /t 5 /nobreak >nul 2>&1

echo Restarting to BIOS/UEFI...
shutdown /r /fw /t 0

