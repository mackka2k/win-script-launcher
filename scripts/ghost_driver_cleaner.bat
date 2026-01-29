@echo off
setlocal EnableDelayedExpansion
title Ghost Driver Cleaner - System Hygiene 👻🧹

echo ============================================
echo    Ghost Driver Cleaner
echo ============================================
echo.
echo Sis skriptas suranda ir pashalina senus, nebenaudojamus
echo "vaiduokliskus" draiverius (irenginius, kurie nebeprijungti).
echo Tai gali padeti pagreitinti sistemos krovimasi ir istaisyti konfliktus.
echo.

:: Patikrinimas del administratoriaus teisiu
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] KLAIDA: BUTINOS Administratoriaus teises.
    pause
    exit /b 1
)

echo [1/2] Skenuojami atjungti irenginiai...
echo Tai gali uztrukti kelias sekundes...
echo.

:: Naudojame PowerShell, kad gautume sąrašą ir suskaičiuotume
powershell -NoProfile -Command "$devs = Get-PnpDevice | Where-Object {$_.Status -eq 'Unknown' -or $_.ConfigManagerErrorCode -eq 45}; if ($devs) { echo \"Rasta irenginiu: $($devs.Count)\"; $devs | Select-Object FriendlyName, InstanceId | Format-Table } else { echo 'Atjungtu irenginiu nerasta.' }"

echo.
echo Pasirinkite veiksma:
echo [1] PASALINTI visus atjungtus irenginius (Rekomenduojama)
echo [2] Tik skenuoti (nieko nedaryti)
echo [3] Iseiti
echo.
set /p opt="Pasirinkimas: "

if "%opt%"=="1" goto clean
exit /b

:clean
echo.
echo [!] Pradedamas valymas...
:: Naudojame pnputil, kad pašalintume atjungtus įrenginius
powershell -NoProfile -Command "Get-PnpDevice | Where-Object {$_.Status -eq 'Unknown' -or $_.ConfigManagerErrorCode -eq 45} | ForEach-Object { & pnputil /remove-device $_.InstanceId }"

echo.
echo ============================================
echo    VALYMAS BAIGTAS! ✨👻
echo ============================================
echo.
echo Visi nebenaudingi draiveriu irasai pashalinti.
echo.
pause
exit /b
