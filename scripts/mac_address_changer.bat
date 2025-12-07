@echo off
echo ============================================
echo    MAC Address Changer
echo ============================================
echo.
echo This script allows you to change or reset your MAC address.
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
echo Available Network Adapters:
echo.
powershell -Command "Get-NetAdapter | Where-Object {$_.Status -eq 'Up'} | Format-Table -Property Name, InterfaceDescription, MacAddress"
echo.
echo ============================================
echo    Options:
echo ============================================
echo.
echo 1. Change MAC Address (Random)
echo 2. Change MAC Address (Custom)
echo 3. Reset to Original MAC Address
echo 4. Exit
echo.
set /p choice="Enter your choice (1-4): "

if "%choice%"=="1" goto random
if "%choice%"=="2" goto custom
if "%choice%"=="3" goto reset
if "%choice%"=="4" goto end
echo Invalid choice. Please try again.
goto menu

:random
echo.
set /p adapter="Enter adapter name (e.g., Ethernet, Wi-Fi): "

:: Generate random MAC address
powershell -Command "& { ^
    $mac = '02' + ((1..5 | ForEach-Object { '{0:X2}' -f (Get-Random -Maximum 256) }) -join ''); ^
    Write-Host 'Generated MAC Address: ' -NoNewline; ^
    Write-Host $mac -ForegroundColor Green; ^
    $mac = $mac -replace '..(?!$)', '$0-'; ^
    try { ^
        Set-NetAdapter -Name '%adapter%' -MacAddress $mac -Confirm:$false; ^
        Write-Host 'MAC address changed successfully!' -ForegroundColor Green; ^
        Write-Host 'Restarting adapter...'; ^
        Restart-NetAdapter -Name '%adapter%' -Confirm:$false; ^
        Write-Host 'Done!' -ForegroundColor Green; ^
    } catch { ^
        Write-Host 'ERROR: Failed to change MAC address.' -ForegroundColor Red; ^
        Write-Host $_.Exception.Message; ^
    } ^
}"
goto menu

:custom
echo.
set /p adapter="Enter adapter name (e.g., Ethernet, Wi-Fi): "
echo.
echo Enter new MAC address (format: 02-XX-XX-XX-XX-XX)
echo Note: First byte should be 02 for locally administered address
set /p newmac="MAC Address: "

powershell -Command "& { ^
    try { ^
        Set-NetAdapter -Name '%adapter%' -MacAddress '%newmac%' -Confirm:$false; ^
        Write-Host 'MAC address changed successfully!' -ForegroundColor Green; ^
        Write-Host 'Restarting adapter...'; ^
        Restart-NetAdapter -Name '%adapter%' -Confirm:$false; ^
        Write-Host 'Done!' -ForegroundColor Green; ^
    } catch { ^
        Write-Host 'ERROR: Failed to change MAC address.' -ForegroundColor Red; ^
        Write-Host $_.Exception.Message; ^
    } ^
}"
goto menu

:reset
echo.
set /p adapter="Enter adapter name (e.g., Ethernet, Wi-Fi): "

powershell -Command "& { ^
    try { ^
        $regPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002BE10318}'; ^
        Get-ChildItem $regPath | ForEach-Object { ^
            $props = Get-ItemProperty $_.PSPath; ^
            if ($props.DriverDesc -like '*%adapter%*') { ^
                Remove-ItemProperty -Path $_.PSPath -Name 'NetworkAddress' -ErrorAction SilentlyContinue; ^
            } ^
        }; ^
        Write-Host 'MAC address reset to original!' -ForegroundColor Green; ^
        Write-Host 'Restarting adapter...'; ^
        Restart-NetAdapter -Name '%adapter%' -Confirm:$false; ^
        Write-Host 'Done!' -ForegroundColor Green; ^
    } catch { ^
        Write-Host 'ERROR: Failed to reset MAC address.' -ForegroundColor Red; ^
        Write-Host $_.Exception.Message; ^
    } ^
}"
goto menu

:end
echo.
echo Exiting...
pause
