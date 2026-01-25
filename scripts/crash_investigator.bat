@echo off
setlocal
title System Crash Reporter

echo ============================================
echo      System Crash Reporter 🕵️‍♂️📄
echo ============================================
echo.
echo Generuojama pilna sistemos klaidu ataskaita...
echo [Prasome palaukti, tai gali uztrukti]
echo.

set "REPORT_FILE=%USERPROFILE%\Desktop\CRASH_REPORT.txt"

:: Start building the report file
echo ============================================ > "%REPORT_FILE%"
echo      SYSTEM CRASH REPORT - %DATE% %TIME% >> "%REPORT_FILE%"
echo ============================================ >> "%REPORT_FILE%"
echo. >> "%REPORT_FILE%"

:: 1. Critical Power Errors
echo [1] KRITINIAI ISSIJUNGIMAI (Kernel-Power): >> "%REPORT_FILE%"
powershell -Command "Get-WinEvent -FilterHashtable @{LogName='System'; Id=41} -MaxEvents 10 -ErrorAction SilentlyContinue | Select-Object TimeCreated, Message | Format-List" >> "%REPORT_FILE%"
echo. >> "%REPORT_FILE%"

:: 2. Application Crashing
echo [2] PROGRAMU KLAIDOS (Application Crashes): >> "%REPORT_FILE%"
powershell -Command "Get-WinEvent -FilterHashtable @{LogName='Application'; Level=2} -MaxEvents 10 -ErrorAction SilentlyContinue | Select-Object TimeCreated, Message | Format-List" >> "%REPORT_FILE%"
echo. >> "%REPORT_FILE%"

:: 3. Blue Screen (BSOD) Info
echo [3] MELYNOJO EKRANO (BSOD) DUOMENYS: >> "%REPORT_FILE%"
powershell -Command "Get-WinEvent -FilterHashtable @{LogName='System'; Id=1001; ProviderName='Microsoft-Windows-WER-SystemErrorReporting'} -MaxEvents 5 -ErrorAction SilentlyContinue | Select-Object TimeCreated, Message | Format-List" >> "%REPORT_FILE%"
echo. >> "%REPORT_FILE%"

:: 4. Dump files list
echo [4] RASTI DUMP FAILAI (C:\Windows\Minidump): >> "%REPORT_FILE%"
dir C:\Windows\Minidump\*.dmp /O-D /B >> "%REPORT_FILE%" 2>&1
echo. >> "%REPORT_FILE%"

echo ============================================ >> "%REPORT_FILE%"
echo      ATASKAITOS PABAIGA >> "%REPORT_FILE%"

echo [OK] Ataskaita sugeneruota sekmingai!
echo Vietove: %REPORT_FILE%
echo.

:: Open the report automatically
start "" "%REPORT_FILE%"

echo.
pause
exit /b
