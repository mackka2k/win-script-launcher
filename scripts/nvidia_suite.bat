@echo off
setlocal
title NVIDIA Tool ^& Performance Suite

echo ============================================
echo    NVIDIA Tool ^& Performance Suite
echo ============================================
echo.

:: Check for NVIDIA via Services
sc query NvContainerLocalSystem >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] KLAIDA: NVIDIA plokste arba servisai nerasti.
    echo Pasitinkinkite, ar turite idiegtus NVIDIA draiverius.
    pause
    exit /b 1
)

:menu
echo Pasirinkite veiksma:
echo [1] Atidaryti NVIDIA Control Panel
echo [2] RESTARTUOTI vaizdo draiverius (Fix glitches)
echo [3] Isjungti NVIDIA Telemetry (Privatumas)
echo [4] Isjungti MPO (Fix flickering)
echo [5] Atstatyti MPO
echo [6] Iseiti
echo.

choice /c 123456 /n /m "Pasirinkimas (1-6): "
set opt=%errorlevel%

if %opt% equ 1 goto open_cpl
if %opt% equ 2 goto restart_drv
if %opt% equ 3 goto kill_telemetry
if %opt% equ 4 goto disable_mpo
if %opt% equ 5 goto reset_mpo
if %opt% equ 6 exit /b

:open_cpl
echo.
echo Bandoma paleisti NVIDIA Control Panel...
:: Method 1: DCH AUMID
start explorer.exe shell:AppsFolder\NVIDIACorp.NVIDIAControlPanel_56jybvy8sckqj!NVIDIACorp.NVIDIAControlPanel
:: Method 2: URI
start nvcpl: >nul 2>&1
:: Method 3: Classic
if exist "%ProgramFiles%\NVIDIA Corporation\Control Panel Client\nvcplui.exe" start "" "%ProgramFiles%\NVIDIA Corporation\Control Panel Client\nvcplui.exe"
goto end

:restart_drv
echo.
echo Restartuojami NVIDIA servisai...
net stop "NvContainerLocalSystem" /y >nul 2>&1
net start "NvContainerLocalSystem" >nul 2>&1
echo [OK] Servisai perkrauti.
goto end

:kill_telemetry
echo.
echo Stabdoma NVIDIA Telemetrija...
sc stop NvTelemetryContainer >nul 2>&1
sc config NvTelemetryContainer start= disabled >nul 2>&1
echo [OK] Telemetrija isjungta.
goto end

:disable_mpo
echo.
echo Isjungiamas MPO (Multi-Plane Overlay)...
reg add "HKLM\SOFTWARE\Microsoft\Windows\Dwm" /v "OverlayTestMode" /t REG_DWORD /d 5 /f >nul
echo [OK] MPO isjungtas.
goto end

:reset_mpo
echo.
echo Atstatomas MPO...
reg delete "HKLM\SOFTWARE\Microsoft\Windows\Dwm" /v "OverlayTestMode" /f >nul 2>&1
echo [OK] MPO nustatymai atstatyti.
goto end

:end
echo.
echo ============================================
echo    Atlikta!
echo ============================================
echo.
pause
goto menu
