@echo off
setlocal enabledelayedexpansion
title Thermal Throttle Monitor
chcp 65001 >nul 2>&1

echo ============================================
echo    Thermal Throttle Monitor
echo ============================================
echo.
echo Sis skriptas stebi CPU/GPU temperatura ir
echo tikrina ar nevyksta thermal throttling.
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

echo Pasirinkite veiksma:
echo [1] Dabartine temperaturos busena
echo [2] CPU informacija ir throttle tikrinimas
echo [3] Realaus laiko temperaturos stebejimas
echo [4] Termalinio profilio ataskaita
echo [5] Atsaukti
echo.

set /p opt="Pasirinkimas (1-5): "

if "%opt%"=="5" exit /b 0
if "%opt%"=="1" goto :temp_status
if "%opt%"=="2" goto :cpu_throttle
if "%opt%"=="3" goto :realtime
if "%opt%"=="4" goto :thermal_report
goto :invalid

:temp_status
echo.
echo ============================================
echo    Dabartine temperaturos busena
echo ============================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "Write-Host '  --- CPU Temperatura ---' -ForegroundColor Cyan;" ^
    "$temps = Get-CimInstance -Namespace root\wmi -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction SilentlyContinue;" ^
    "if ($temps) {" ^
    "  foreach ($t in $temps) {" ^
    "    $celsius = [math]::Round(($t.CurrentTemperature / 10) - 273.15, 1);" ^
    "    $color = if ($celsius -ge 90) {'Red'} elseif ($celsius -ge 75) {'Yellow'} else {'Green'};" ^
    "    $bar = '█' * [math]::Min([math]::Round($celsius / 2), 50) + '░' * [math]::Max(50 - [math]::Round($celsius / 2), 0);" ^
    "    Write-Host ('  Zona: ' + $t.InstanceName.Split('_')[-1]) -ForegroundColor White;" ^
    "    Write-Host ('  Temperatura: ' + $celsius + ' °C') -ForegroundColor $color;" ^
    "    Write-Host ('  [' + $bar + ']') -ForegroundColor $color;" ^
    "    Write-Host '';" ^
    "    if ($celsius -ge 95) {" ^
    "      Write-Host '  [!!!] PAVOJUS: Temperatura kritiskai auksta!' -ForegroundColor Red;" ^
    "      Write-Host '        Galimas thermal throttling arba sistemos isjungimas!' -ForegroundColor Red" ^
    "    } elseif ($celsius -ge 85) {" ^
    "      Write-Host '  [!!] Auksta temperatura! Tikrinkit ausinima.' -ForegroundColor Red" ^
    "    } elseif ($celsius -ge 75) {" ^
    "      Write-Host '  [!] Vidutiniskai auksta. Stebeti situacija.' -ForegroundColor Yellow" ^
    "    } else {" ^
    "      Write-Host '  [OK] Temperatura normali.' -ForegroundColor Green" ^
    "    };" ^
    "    Write-Host ''" ^
    "  }" ^
    "} else {" ^
    "  Write-Host '  [!] Nepavyko nuskaityti ACPI temperaturos.' -ForegroundColor Yellow;" ^
    "  Write-Host '      Bandoma alternatyvus metodas...' -ForegroundColor Yellow;" ^
    "  Write-Host '';" ^
    "  $cpuInfo = Get-CimInstance -ClassName Win32_PerfFormattedData_Counters_ThermalZoneInformation -ErrorAction SilentlyContinue;" ^
    "  if ($cpuInfo) {" ^
    "    foreach ($c in $cpuInfo) {" ^
    "      $tempC = [math]::Round($c.Temperature - 273.15, 1);" ^
    "      $color = if ($tempC -ge 90) {'Red'} elseif ($tempC -ge 75) {'Yellow'} else {'Green'};" ^
    "      Write-Host ('  ' + $c.Name + ': ' + $tempC + ' °C') -ForegroundColor $color" ^
    "    }" ^
    "  } else {" ^
    "    Write-Host '  [!] Temperatura nepasiekiama per Windows API.' -ForegroundColor Red;" ^
    "    Write-Host '      Naudokite: HWiNFO64, Core Temp arba HWMonitor.' -ForegroundColor Yellow" ^
    "  }" ^
    "};" ^
    "Write-Host '';" ^
    "Write-Host '  --- GPU Temperatura ---' -ForegroundColor Cyan;" ^
    "$gpu = Get-CimInstance -ClassName Win32_VideoController | Select-Object -First 1;" ^
    "Write-Host ('  GPU: ' + $gpu.Name) -ForegroundColor White;" ^
    "if ($gpu.Name -match 'NVIDIA') {" ^
    "  $nvSmi = (Get-Command 'nvidia-smi' -ErrorAction SilentlyContinue) -or (Test-Path 'C:\\Program Files\\NVIDIA Corporation\\NVSMI\\nvidia-smi.exe');" ^
    "  if ($nvSmi) {" ^
    "    try {" ^
    "      $smiPath = if (Get-Command 'nvidia-smi' -ErrorAction SilentlyContinue) { 'nvidia-smi' } else { 'C:\\Program Files\\NVIDIA Corporation\\NVSMI\\nvidia-smi.exe' };" ^
    "      $gpuTemp = (& $smiPath --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>$null).Trim();" ^
    "      $gpuTempInt = [int]$gpuTemp;" ^
    "      $gColor = if ($gpuTempInt -ge 85) {'Red'} elseif ($gpuTempInt -ge 70) {'Yellow'} else {'Green'};" ^
    "      Write-Host ('  GPU Temperatura: ' + $gpuTempInt + ' °C') -ForegroundColor $gColor;" ^
    "      $gpuClock = (& $smiPath --query-gpu=clocks.current.graphics --format=csv,noheader,nounits 2>$null).Trim();" ^
    "      $gpuMaxClock = (& $smiPath --query-gpu=clocks.max.graphics --format=csv,noheader,nounits 2>$null).Trim();" ^
    "      $gpuUtil = (& $smiPath --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>$null).Trim();" ^
    "      $gpuPower = (& $smiPath --query-gpu=power.draw --format=csv,noheader,nounits 2>$null).Trim();" ^
    "      Write-Host ('  GPU Daznis:      ' + $gpuClock + ' / ' + $gpuMaxClock + ' MHz');" ^
    "      Write-Host ('  GPU Apkrova:     ' + $gpuUtil + '%%');" ^
    "      Write-Host ('  GPU Galia:       ' + $gpuPower + ' W');" ^
    "      if ($gpuTempInt -ge 85) {" ^
    "        Write-Host '';" ^
    "        Write-Host '  [!!] GPU temperatura auksta - galimas throttling!' -ForegroundColor Red" ^
    "      }" ^
    "    } catch {" ^
    "      Write-Host '  [!] nvidia-smi klaida.' -ForegroundColor Yellow" ^
    "    }" ^
    "  } else {" ^
    "    Write-Host '  [!] nvidia-smi nerastas. Idiekite NVIDIA drivers.' -ForegroundColor Yellow" ^
    "  }" ^
    "} else {" ^
    "  Write-Host '  [!] GPU temperaturos nuskaitymas per Windows API negalimas.' -ForegroundColor Yellow;" ^
    "  Write-Host '      Naudokite HWiNFO64 arba GPU gamintojo programine iranga.' -ForegroundColor Yellow" ^
    "}"
goto :done

:cpu_throttle
echo.
echo ============================================
echo    CPU Throttle tikrinimas
echo ============================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$cpu = Get-CimInstance Win32_Processor;" ^
    "Write-Host '  --- CPU informacija ---' -ForegroundColor Cyan;" ^
    "Write-Host ('  Modelis:           ' + $cpu.Name);" ^
    "Write-Host ('  Branduoliai:       ' + $cpu.NumberOfCores + ' fiziniai, ' + $cpu.NumberOfLogicalProcessors + ' loginiai');" ^
    "Write-Host ('  Max daznis:        ' + $cpu.MaxClockSpeed + ' MHz');" ^
    "Write-Host ('  Dabartinis daznis: ' + $cpu.CurrentClockSpeed + ' MHz');" ^
    "Write-Host '';" ^
    "" ^
    "$speedPct = [math]::Round(($cpu.CurrentClockSpeed / $cpu.MaxClockSpeed) * 100, 1);" ^
    "$sColor = if ($speedPct -ge 90) {'Green'} elseif ($speedPct -ge 70) {'Yellow'} else {'Red'};" ^
    "Write-Host ('  Daznis:            ' + $speedPct + '%% nuo max') -ForegroundColor $sColor;" ^
    "" ^
    "Write-Host ('  CPU apkrova:       ' + $cpu.LoadPercentage + '%%');" ^
    "Write-Host '';" ^
    "" ^
    "if ($speedPct -lt 70) {" ^
    "  Write-Host '  [!!] GALIMAS THROTTLING!' -ForegroundColor Red;" ^
    "  Write-Host '       CPU daznis zymiai mazesnis nei maksimalus.' -ForegroundColor Red;" ^
    "  Write-Host '       Priezastys: per auksta temperatura, energijos taupymas,' -ForegroundColor Yellow;" ^
    "  Write-Host '       arba blogas ausinimas.' -ForegroundColor Yellow" ^
    "} elseif ($speedPct -lt 90) {" ^
    "  Write-Host '  [!] CPU daznis sumažejęs. Gali buti susije su energijos planu.' -ForegroundColor Yellow" ^
    "} else {" ^
    "  Write-Host '  [OK] CPU veikia normaliu dazniu.' -ForegroundColor Green" ^
    "};" ^
    "Write-Host '';" ^
    "" ^
    "Write-Host '  --- Energijos planas ---' -ForegroundColor Cyan;" ^
    "$plan = powercfg /getactivescheme;" ^
    "Write-Host ('  ' + $plan);" ^
    "Write-Host '';" ^
    "" ^
    "Write-Host '  --- Procesoriu busenos ---' -ForegroundColor Cyan;" ^
    "$minState = (powercfg /query SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 2>$null) -match 'Current.*: 0x';" ^
    "$maxState = (powercfg /query SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 2>$null) -match 'Current.*: 0x';" ^
    "foreach ($line in $minState) {" ^
    "  if ($line -match '0x([0-9a-fA-F]+)') { $minPct = [convert]::ToInt32($matches[1], 16); Write-Host ('  Min CPU busena: ' + $minPct + '%%') }" ^
    "};" ^
    "foreach ($line in $maxState) {" ^
    "  if ($line -match '0x([0-9a-fA-F]+)') { $maxPct = [convert]::ToInt32($matches[1], 16); Write-Host ('  Max CPU busena: ' + $maxPct + '%%') }" ^
    "}"
goto :done

:realtime
echo.
echo ============================================
echo    Realaus laiko temperaturos stebejimas
echo ============================================
echo.
echo [!] Stebima kas 5 sekundes. Spauskite Ctrl+C sustabdyti.
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$hasNvSmi = $false;" ^
    "$nvSmiPath = '';" ^
    "if (Get-Command 'nvidia-smi' -ErrorAction SilentlyContinue) { $hasNvSmi = $true; $nvSmiPath = 'nvidia-smi' }" ^
    "elseif (Test-Path 'C:\\Program Files\\NVIDIA Corporation\\NVSMI\\nvidia-smi.exe') { $hasNvSmi = $true; $nvSmiPath = 'C:\\Program Files\\NVIDIA Corporation\\NVSMI\\nvidia-smi.exe' };" ^
    "" ^
    "Write-Host ('  {0,-10} {1,10} {2,10} {3,10} {4,10}' -f 'Laikas', 'CPU °C', 'CPU %%', 'GPU °C', 'GPU %%') -ForegroundColor Cyan;" ^
    "Write-Host ('  ' + '-' * 55) -ForegroundColor DarkGray;" ^
    "" ^
    "while ($true) {" ^
    "  $time = Get-Date -Format 'HH:mm:ss';" ^
    "  $cpuTemp = '--';" ^
    "  $cpuColor = 'White';" ^
    "  $t = Get-CimInstance -Namespace root\\wmi -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction SilentlyContinue | Select-Object -First 1;" ^
    "  if ($t) {" ^
    "    $ct = [math]::Round(($t.CurrentTemperature / 10) - 273.15, 0);" ^
    "    $cpuTemp = $ct.ToString();" ^
    "    $cpuColor = if ($ct -ge 90) {'Red'} elseif ($ct -ge 75) {'Yellow'} else {'Green'}" ^
    "  };" ^
    "" ^
    "  $cpuLoad = (Get-CimInstance Win32_Processor).LoadPercentage;" ^
    "  if (-not $cpuLoad) { $cpuLoad = '--' };" ^
    "" ^
    "  $gpuTemp = '--';" ^
    "  $gpuLoad = '--';" ^
    "  $gpuColor = 'White';" ^
    "  if ($hasNvSmi) {" ^
    "    try {" ^
    "      $gt = [int](& $nvSmiPath --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>$null).Trim();" ^
    "      $gpuTemp = $gt.ToString();" ^
    "      $gpuColor = if ($gt -ge 85) {'Red'} elseif ($gt -ge 70) {'Yellow'} else {'Green'};" ^
    "      $gpuLoad = (& $nvSmiPath --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>$null).Trim()" ^
    "    } catch {}" ^
    "  };" ^
    "" ^
    "  $line = '  {0,-10} ' -f $time;" ^
    "  Write-Host $line -NoNewline;" ^
    "  Write-Host ('{0,10} ' -f $cpuTemp) -NoNewline -ForegroundColor $cpuColor;" ^
    "  Write-Host ('{0,10} ' -f $cpuLoad) -NoNewline;" ^
    "  Write-Host ('{0,10} ' -f $gpuTemp) -NoNewline -ForegroundColor $gpuColor;" ^
    "  Write-Host ('{0,10}' -f $gpuLoad);" ^
    "" ^
    "  if ($cpuTemp -ne '--' -and [int]$cpuTemp -ge 95) {" ^
    "    Write-Host '  >>> [!!!] CPU THERMAL THROTTLING TIKĖTINAS! <<<' -ForegroundColor Red" ^
    "  };" ^
    "  if ($gpuTemp -ne '--' -and [int]$gpuTemp -ge 90) {" ^
    "    Write-Host '  >>> [!!!] GPU THERMAL THROTTLING TIKĖTINAS! <<<' -ForegroundColor Red" ^
    "  };" ^
    "" ^
    "  Start-Sleep -Seconds 5" ^
    "}"
goto :done

:thermal_report
echo.
echo ============================================
echo    Termalinio profilio ataskaita
echo ============================================
echo.
echo [!] Generuojama isami termalinio profilio ataskaita...
echo     Tai uzims apie 60 sekundziu.
echo.
set "reportPath=%USERPROFILE%\Desktop\Thermal_Report.html"

powercfg /energy /output "%reportPath%" >nul 2>&1
if %errorlevel% leq 1 (
    echo [OK] Energijos efektyvumo ataskaita sugeneruota!
    echo     Failas: Desktop\Thermal_Report.html
    echo.
    echo     Ataskaitoje rasite:
    echo     - Energijos vartojimo problemas
    echo     - CPU P-state informacija
    echo     - Procesoriaus ausinimo politika
    echo     - Irenginio maitinimo valdymo klaidas
    echo.
    set /p openReport="Atidaryti ataskaita? (T/N): "
    if /i "!openReport!"=="T" (
        start "" "%reportPath%"
    )
) else (
    echo [!] KLAIDA: Nepavyko sugeneruoti ataskaitos.
    echo     Isitikinkite kad turite Admin teises.
)
goto :done

:invalid
echo [!] Neteisingas pasirinkimas.

:done
echo.
echo ============================================
echo    Procesas baigtas.
echo ============================================
echo.
pause
exit /b
