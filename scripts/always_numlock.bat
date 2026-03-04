@echo off
echo Enabling NumLock at Windows logon...

:: Set registry value
reg add "HKEY_USERS\.DEFAULT\Control Panel\Keyboard" /v InitialKeyboardIndicators /t REG_SZ /d 2 /f >nul 2>&1

:: Verify change
for /f "tokens=3" %%a in ('reg query "HKEY_USERS\.DEFAULT\Control Panel\Keyboard" /v InitialKeyboardIndicators 2^>nul') do set VAL=%%a

if "%VAL%"=="2" (
    echo NumLock has been successfully set to ON at logon.
) else (
    echo Failed to set NumLock registry value.
)

echo Closing in 2 seconds...
timeout /t 2 >nul
exit
