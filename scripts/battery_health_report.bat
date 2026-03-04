@echo off
setlocal
title Battery Health Report
chcp 65001 >nul 2>&1

echo ============================================
echo    Battery Health Report
echo ============================================
echo.

:: Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] KLAIDA: Reikalingos Administratoriaus teises!
    echo Paleiskite Script Launcher kaip Administratoriu.
    echo.
    pause
    exit /b 1
)

:: Pirma patikriname ar yra baterija
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$b = Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue; if (-not $b) { Write-Host '[!] Baterija nerasta. Tikriausiai naudojate stacionaru PC.' -ForegroundColor Red; exit 1 }"
if %errorlevel% neq 0 (
    echo.
    pause
    exit /b 1
)

echo [OK] Baterija aptikta. Renkama informacija...
echo.

:: === Greita baterijos suvestine ===
echo ============================================
echo    Greita suvestine
echo ============================================
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$bat = Get-CimInstance -ClassName Win32_Battery;" ^
    "$charge = $bat.EstimatedChargeRemaining;" ^
    "$status = switch ($bat.BatteryStatus) {" ^
    "  1 { 'Iskraunama' }" ^
    "  2 { 'Ikraunama (AC)' }" ^
    "  3 { 'Pilnai ikrauta' }" ^
    "  4 { 'Zema baterija' }" ^
    "  5 { 'Kritine baterija' }" ^
    "  6 { 'Ikraunama' }" ^
    "  7 { 'Ikraunama ir auksta' }" ^
    "  8 { 'Ikraunama ir zema' }" ^
    "  9 { 'Ikraunama ir kritine' }" ^
    "  default { 'Nezinoma' }" ^
    "};" ^
    "" ^
    "$color = if ($charge -ge 60) { 'Green' } elseif ($charge -ge 25) { 'Yellow' } else { 'Red' };" ^
    "Write-Host ('  Ikrovimo lygis:    ' + $charge + '%%') -ForegroundColor $color;" ^
    "Write-Host ('  Busena:            ' + $status);" ^
    "" ^
    "if ($bat.EstimatedRunTime -and $bat.EstimatedRunTime -lt 71582788) {" ^
    "  $hours = [math]::Floor($bat.EstimatedRunTime / 60);" ^
    "  $mins = $bat.EstimatedRunTime %% 60;" ^
    "  Write-Host ('  Liko laiko:        ' + $hours + ' val. ' + $mins + ' min.')" ^
    "} else {" ^
    "  Write-Host '  Liko laiko:        N/A (prijungtas prie maitinimo)'" ^
    "};" ^
    "" ^
    "Write-Host ('  Gamintojas:        ' + $bat.DeviceID);" ^
    "Write-Host ('  Chemija:           ' + $(if ($bat.Chemistry) { switch ($bat.Chemistry) { 1 {'Other'} 2 {'Unknown'} 3 {'Lead Acid'} 4 {'Nickel Cadmium'} 5 {'Nickel MH'} 6 {'Li-ion'} 7 {'Zinc air'} 8 {'Li-Polymer'} default {'N/A'} } } else { 'N/A' }))"

echo.

:: === Design vs Full Charge talpa ===
echo ============================================
echo    Baterijos nusidevejimas
echo ============================================
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$design = (Get-CimInstance -Namespace root\wmi -ClassName BatteryStaticData -ErrorAction SilentlyContinue).DesignedCapacity;" ^
    "$full = (Get-CimInstance -Namespace root\wmi -ClassName BatteryFullChargedCapacity -ErrorAction SilentlyContinue).FullChargedCapacity;" ^
    "if ($design -and $full -and $design -gt 0) {" ^
    "  $health = [math]::Round(($full / $design) * 100, 1);" ^
    "  $wear = [math]::Round(100 - $health, 1);" ^
    "  Write-Host ('  Projektuota talpa:     ' + $design + ' mWh');" ^
    "  Write-Host ('  Dabartine max talpa:   ' + $full + ' mWh');" ^
    "  Write-Host '';" ^
    "  $hColor = if ($health -ge 80) { 'Green' } elseif ($health -ge 50) { 'Yellow' } else { 'Red' };" ^
    "  Write-Host ('  Baterijos sveikata:    ' + $health + '%%') -ForegroundColor $hColor;" ^
    "  Write-Host ('  Nusidevejimas:         ' + $wear + '%%');" ^
    "  Write-Host '';" ^
    "  if ($health -ge 80) {" ^
    "    Write-Host '  [OK] Baterija geros bukles!' -ForegroundColor Green" ^
    "  } elseif ($health -ge 50) {" ^
    "    Write-Host '  [!] Baterija vidutiniskai nusidevejusi.' -ForegroundColor Yellow;" ^
    "    Write-Host '      Apsvarstykite baterijos keitima artimiausiu metu.' -ForegroundColor Yellow" ^
    "  } else {" ^
    "    Write-Host '  [!!] Baterija stipriai nusidevejusi!' -ForegroundColor Red;" ^
    "    Write-Host '       Rekomenduojama nedelsiant keisti baterija.' -ForegroundColor Red" ^
    "  }" ^
    "} else {" ^
    "  Write-Host '  [!] Nepavyko gauti talpos duomenu.' -ForegroundColor Yellow" ^
    "}"

echo.

:: === Isami ataskaita i HTML ===
echo ============================================
echo    Detali HTML ataskaita
echo ============================================
echo.

set /p genReport="Ar norite sugeneruoti detalia HTML ataskaita? (T/N): "
if /i "%genReport%"=="T" (
    echo.
    echo [!] Generuojama detali baterijos ataskaita...
    set "reportPath=%USERPROFILE%\Desktop\Battery_Health_Report.html"
    powercfg /batteryreport /output "%USERPROFILE%\Desktop\Battery_Health_Report.html" >nul 2>&1
    if %errorlevel% equ 0 (
        echo [OK] Ataskaita issaugota: Desktop\Battery_Health_Report.html
        echo.
        echo Ataskaitoje rasite:
        echo   - Baterijos ikrovimo/iskrovimo istorija
        echo   - Talpos pokyciai laikui begant
        echo   - Baterijos naudojimo statistika
        echo   - Energijos suvartojimo grafikus
        echo.
        set /p openReport="Atidaryti ataskaita narstykleje? (T/N): "
        if /i "!openReport!"=="T" (
            start "" "%USERPROFILE%\Desktop\Battery_Health_Report.html"
        )
    ) else (
        echo [!] KLAIDA: Nepavyko sugeneruoti ataskaitos.
    )
)

echo.
echo ============================================
echo    Procesas baigtas.
echo ============================================
echo.
pause
exit /b
