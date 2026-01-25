@echo off
title Ultimate Performance Plan Activator

echo ============================================
echo   Ultimate Performance Plan Activator
echo ============================================
echo.

:: Simple execution using PowerShell for better stability
powershell -Command "$res = powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61; if ($?) { $guid = ($res -split ' ')[3]; powercfg -setactive $guid; Write-Host 'Sėkmingai atrakinta ir aktyvuota!' -ForegroundColor Green } else { powercfg -setactive e9a42b02-d5df-448d-aa00-03f14749eb61; if ($?) { Write-Host 'Aktyvuotas esamas planas.' -ForegroundColor Green } else { Write-Host 'Klaida: Planas nepalaikomas.' -ForegroundColor Red } }"

echo.
echo ============================================
echo   Process Finished.
echo ============================================
echo.
pause
exit /b
