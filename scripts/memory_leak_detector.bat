@echo off
setlocal enabledelayedexpansion
title Memory Leak Detector
chcp 65001 >nul 2>&1

echo ============================================
echo    Memory Leak Detector
echo ============================================
echo.
echo Sis skriptas stebi RAM naudojima ir padeda
echo aptikti procesus su galimais memory leak.
echo.

echo Pasirinkite veiksma:
echo [1] Dabartine RAM busena (momentine nuotrauka)
echo [2] TOP 20 daugiausiai RAM naudojanciu procesu
echo [3] Memory leak stebejimas (realiu laiku)
echo [4] Procesu atminties palyginimas (prieš/po)
echo [5] Atsaukti
echo.

set /p opt="Pasirinkimas (1-5): "

if "%opt%"=="5" exit /b 0
if "%opt%"=="1" goto :ram_status
if "%opt%"=="2" goto :top_processes
if "%opt%"=="3" goto :realtime_monitor
if "%opt%"=="4" goto :compare
goto :invalid

:ram_status
echo.
echo ============================================
echo    Dabartine RAM busena
echo ============================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$os = Get-CimInstance Win32_OperatingSystem;" ^
    "$totalGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2);" ^
    "$freeGB = [math]::Round($os.FreePhysicalMemory / 1MB, 2);" ^
    "$usedGB = [math]::Round($totalGB - $freeGB, 2);" ^
    "$usedPct = [math]::Round(($usedGB / $totalGB) * 100, 1);" ^
    "$freePct = [math]::Round(100 - $usedPct, 1);" ^
    "" ^
    "$color = if ($usedPct -ge 90) {'Red'} elseif ($usedPct -ge 70) {'Yellow'} else {'Green'};" ^
    "" ^
    "Write-Host ('  Viso RAM:          ' + $totalGB + ' GB');" ^
    "Write-Host ('  Naudojama:         ' + $usedGB + ' GB (' + $usedPct + '%%)')  -ForegroundColor $color;" ^
    "Write-Host ('  Laisva:            ' + $freeGB + ' GB (' + $freePct + '%%)');" ^
    "Write-Host '';" ^
    "" ^
    "$cs = Get-CimInstance Win32_ComputerSystem;" ^
    "$commitGB = [math]::Round(($os.TotalVirtualMemorySize - $os.FreeVirtualMemory) / 1MB, 2);" ^
    "$commitTotalGB = [math]::Round($os.TotalVirtualMemorySize / 1MB, 2);" ^
    "$commitPct = [math]::Round(($commitGB / $commitTotalGB) * 100, 1);" ^
    "Write-Host ('  Commit charge:     ' + $commitGB + ' / ' + $commitTotalGB + ' GB (' + $commitPct + '%%)');" ^
    "Write-Host '';" ^
    "" ^
    "$bar = '  [';" ^
    "$filled = [math]::Round($usedPct / 2);" ^
    "$bar += '█' * $filled + '░' * (50 - $filled) + ']';" ^
    "Write-Host $bar -ForegroundColor $color;" ^
    "Write-Host '';" ^
    "" ^
    "if ($usedPct -ge 90) {" ^
    "  Write-Host '  [!!] KRITINIS: Beveik visa RAM uzimta!' -ForegroundColor Red;" ^
    "  Write-Host '       Uzdarykit nereikalingus procesus arba pridekite RAM.' -ForegroundColor Red" ^
    "} elseif ($usedPct -ge 70) {" ^
    "  Write-Host '  [!] Aukštas RAM naudojimas. Stebeti situacija.' -ForegroundColor Yellow" ^
    "} else {" ^
    "  Write-Host '  [OK] RAM naudojimas normalus.' -ForegroundColor Green" ^
    "}"
goto :done

:top_processes
echo.
echo ============================================
echo    TOP 20 procesu pagal RAM
echo ============================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$procs = Get-Process | Where-Object { $_.WorkingSet64 -gt 0 } | Sort-Object WorkingSet64 -Descending | Select-Object -First 20;" ^
    "$i = 1;" ^
    "Write-Host ('  {0,-4} {1,-35} {2,10} {3,8}' -f '#', 'Procesas', 'RAM (MB)', 'PID') -ForegroundColor Cyan;" ^
    "Write-Host ('  ' + '-' * 60) -ForegroundColor DarkGray;" ^
    "foreach ($p in $procs) {" ^
    "  $mb = [math]::Round($p.WorkingSet64 / 1MB, 1);" ^
    "  $color = if ($mb -ge 1000) {'Red'} elseif ($mb -ge 500) {'Yellow'} else {'White'};" ^
    "  Write-Host ('  {0,-4} {1,-35} {2,10} {3,8}' -f $i, $p.ProcessName.Substring(0, [Math]::Min(34, $p.ProcessName.Length)), $mb, $p.Id) -ForegroundColor $color;" ^
    "  $i++" ^
    "};" ^
    "Write-Host '';" ^
    "$totalMB = [math]::Round(($procs | Measure-Object WorkingSet64 -Sum).Sum / 1MB, 0);" ^
    "Write-Host ('  TOP 20 viso: ' + $totalMB + ' MB') -ForegroundColor Cyan"
goto :done

:realtime_monitor
echo.
echo ============================================
echo    Memory Leak Stebejimas (realiu laiku)
echo ============================================
echo.
echo [!] Stebimi procesai, kuriu RAM naudojimas nuolat auga.
echo     Matuojama kas 10 sek. Spauskite Ctrl+C sustabdyti.
echo.
echo     Procesai, kuriu RAM padidejo ^>20 MB per stebejimo
echo     laikotarpi, bus pazymeti kaip ITARTINI.
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$baseline = @{};" ^
    "Get-Process | ForEach-Object { $baseline[$_.Id] = $_.WorkingSet64 };" ^
    "$iteration = 0;" ^
    "while ($true) {" ^
    "  Start-Sleep -Seconds 10;" ^
    "  $iteration++;" ^
    "  $now = Get-Date -Format 'HH:mm:ss';" ^
    "  $leaks = @();" ^
    "  $current = Get-Process;" ^
    "  foreach ($p in $current) {" ^
    "    if ($baseline.ContainsKey($p.Id)) {" ^
    "      $diff = $p.WorkingSet64 - $baseline[$p.Id];" ^
    "      $diffMB = [math]::Round($diff / 1MB, 1);" ^
    "      if ($diffMB -ge 20) {" ^
    "        $leaks += [PSCustomObject]@{" ^
    "          Name = $p.ProcessName;" ^
    "          PID = $p.Id;" ^
    "          CurrentMB = [math]::Round($p.WorkingSet64 / 1MB, 1);" ^
    "          GrowthMB = $diffMB" ^
    "        }" ^
    "      }" ^
    "    } else {" ^
    "      $baseline[$p.Id] = $p.WorkingSet64" ^
    "    }" ^
    "  };" ^
    "  $os = Get-CimInstance Win32_OperatingSystem;" ^
    "  $usedPct = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 1);" ^
    "  $ramColor = if ($usedPct -ge 90) {'Red'} elseif ($usedPct -ge 70) {'Yellow'} else {'Green'};" ^
    "  Write-Host ('  [' + $now + '] Ciklas #' + $iteration + ' | RAM: ' + $usedPct + '%%') -ForegroundColor $ramColor;" ^
    "  if ($leaks.Count -gt 0) {" ^
    "    foreach ($l in ($leaks | Sort-Object GrowthMB -Descending)) {" ^
    "      Write-Host ('    [!] ITARTINAS: ' + $l.Name + ' (PID:' + $l.PID + ') +' + $l.GrowthMB + ' MB (dabar: ' + $l.CurrentMB + ' MB)') -ForegroundColor Red" ^
    "    }" ^
    "  } else {" ^
    "    Write-Host '    Nauju memory leak neaptikta.' -ForegroundColor DarkGray" ^
    "  }" ^
    "}"
goto :done

:compare
echo.
echo ============================================
echo    Procesu atminties palyginimas
echo ============================================
echo.
echo [1/2] Fiksuojama pradine busena...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$snap1 = Get-Process | Where-Object { $_.WorkingSet64 -gt 10MB } | Select-Object Id, ProcessName, @{N='MB';E={[math]::Round($_.WorkingSet64/1MB,1)}};" ^
    "Write-Host ('  Uzfiksuota ' + $snap1.Count + ' procesu.') -ForegroundColor Cyan;" ^
    "Write-Host '';" ^
    "Write-Host '  Dabar atlikite veiksmus, kuriuos norite patikrinti.' -ForegroundColor Yellow;" ^
    "Write-Host '  (pvz., atidarykite programa, paleiskite zaidima ir pan.)' -ForegroundColor Yellow;" ^
    "Write-Host '';" ^
    "Read-Host '  Spauskite ENTER kai buste pasiruose palyginti';" ^
    "Write-Host '';" ^
    "Write-Host '[2/2] Fiksuojama dabartine busena ir lyginima...' -ForegroundColor Cyan;" ^
    "Write-Host '';" ^
    "$snap2 = Get-Process | Where-Object { $_.WorkingSet64 -gt 10MB } | Select-Object Id, ProcessName, @{N='MB';E={[math]::Round($_.WorkingSet64/1MB,1)}};" ^
    "$changes = @();" ^
    "foreach ($p2 in $snap2) {" ^
    "  $p1 = $snap1 | Where-Object { $_.Id -eq $p2.Id } | Select-Object -First 1;" ^
    "  if ($p1) {" ^
    "    $diff = $p2.MB - $p1.MB;" ^
    "    if ([math]::Abs($diff) -ge 5) {" ^
    "      $changes += [PSCustomObject]@{ Name=$p2.ProcessName; PID=$p2.Id; Before=$p1.MB; After=$p2.MB; Diff=$diff }" ^
    "    }" ^
    "  } else {" ^
    "    $changes += [PSCustomObject]@{ Name=$p2.ProcessName; PID=$p2.Id; Before=0; After=$p2.MB; Diff=$p2.MB }" ^
    "  }" ^
    "};" ^
    "$sorted = $changes | Sort-Object Diff -Descending;" ^
    "if ($sorted.Count -eq 0) {" ^
    "  Write-Host '  [OK] Jokiu reiksmingu pokyciu nerasta.' -ForegroundColor Green" ^
    "} else {" ^
    "  Write-Host ('  {0,-30} {1,10} {2,10} {3,10}' -f 'Procesas', 'Prieš MB', 'Po MB', 'Pokytis') -ForegroundColor Cyan;" ^
    "  Write-Host ('  ' + '-' * 62) -ForegroundColor DarkGray;" ^
    "  foreach ($c in $sorted) {" ^
    "    $dColor = if ($c.Diff -gt 50) {'Red'} elseif ($c.Diff -gt 0) {'Yellow'} else {'Green'};" ^
    "    $sign = if ($c.Diff -gt 0) {'+'} else {''};" ^
    "    Write-Host ('  {0,-30} {1,10} {2,10} {3,10}' -f $c.Name, $c.Before, $c.After, ($sign + $c.Diff)) -ForegroundColor $dColor" ^
    "  }" ^
    "}"
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
