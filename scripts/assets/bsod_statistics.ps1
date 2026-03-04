# BSOD Crash Statistics
Write-Host '  Renkama crash statistika...' -ForegroundColor Cyan
Write-Host ''

# Get all BSOD events
$bugChecks = Get-WinEvent -FilterHashtable @{
    LogName = 'System'
    ProviderName = 'Microsoft-Windows-WER-SystemErrorReporting'
    Id = 1001
} -ErrorAction SilentlyContinue

$kernelPower = Get-WinEvent -FilterHashtable @{
    LogName = 'System'
    ProviderName = 'Microsoft-Windows-Kernel-Power'
    Id = 41
} -ErrorAction SilentlyContinue

$bsodCount = if ($bugChecks) { $bugChecks.Count } else { 0 }
$kpCount = if ($kernelPower) { $kernelPower.Count } else { 0 }
$totalCrashes = $bsodCount + $kpCount

if ($totalCrashes -eq 0) {
    Write-Host '  [OK] Jokiu crash irasu nerasta!' -ForegroundColor Green
    Write-Host '  Sistema veikia stabiliai.' -ForegroundColor Green
    exit
}

# Overall stats
Write-Host '  --- Bendra statistika ---' -ForegroundColor Cyan
$color = if ($totalCrashes -ge 10) { 'Red' } elseif ($totalCrashes -ge 3) { 'Yellow' } else { 'Green' }
Write-Host ('  Viso crash ivykiu:         ' + $totalCrashes) -ForegroundColor $color
Write-Host ('    BSOD (melynai ekranai):  ' + $bsodCount)
Write-Host ('    Kernel Power (Event 41): ' + $kpCount)
Write-Host ''

# Combine all events for timeline
$allEvents = @()
if ($bugChecks) {
    foreach ($e in $bugChecks) { $allEvents += [PSCustomObject]@{ Time = $e.TimeCreated; Type = 'BSOD' } }
}
if ($kernelPower) {
    foreach ($e in $kernelPower) { $allEvents += [PSCustomObject]@{ Time = $e.TimeCreated; Type = 'KernelPower' } }
}
$allEvents = $allEvents | Sort-Object Time

# Time range
$first = $allEvents[0].Time
$last = $allEvents[-1].Time
$daySpan = [math]::Max(($last - $first).TotalDays, 1)
$avgPerMonth = [math]::Round($totalCrashes / ($daySpan / 30), 1)

Write-Host ('  Laikotarpis:       ' + $first.ToString('yyyy-MM-dd') + ' iki ' + $last.ToString('yyyy-MM-dd'))
Write-Host ('  Dienu:             ' + [math]::Round($daySpan, 0))
Write-Host ('  Vidurkis/menesi:   ' + $avgPerMonth) -ForegroundColor $(if ($avgPerMonth -ge 5) {'Red'} elseif ($avgPerMonth -ge 2) {'Yellow'} else {'Green'})
Write-Host ''

# Crashes by month
Write-Host '  --- Crash pagal menesi ---' -ForegroundColor Cyan
$byMonth = $allEvents | Group-Object { $_.Time.ToString('yyyy-MM') } | Sort-Object Name -Descending | Select-Object -First 12
foreach ($m in $byMonth) {
    $bar = '█' * [math]::Min($m.Count, 40)
    $mColor = if ($m.Count -ge 5) { 'Red' } elseif ($m.Count -ge 2) { 'Yellow' } else { 'Green' }
    Write-Host ('  {0}  {1,3} {2}' -f $m.Name, $m.Count, $bar) -ForegroundColor $mColor
}
Write-Host ''

# Crashes by day of week
Write-Host '  --- Crash pagal savaites diena ---' -ForegroundColor Cyan
$dayNames = @('Pirmadienis','Antradienis','Treciadienis','Ketvirtadienis','Penktadienis','Sestadienis','Sekmadienis')
$byDay = $allEvents | Group-Object { [int]$_.Time.DayOfWeek }
$dayStats = @{}
foreach ($d in $byDay) { $dayStats[[int]$d.Name] = $d.Count }
for ($i = 1; $i -le 7; $i++) {
    $dayIdx = $i % 7  # Monday=1 -> DayOfWeek Monday=1, Sunday=0
    $count = if ($dayStats.ContainsKey($dayIdx)) { $dayStats[$dayIdx] } else { 0 }
    $bar = '█' * [math]::Min($count, 30)
    Write-Host ('  {0,-15} {1,3} {2}' -f $dayNames[$i-1], $count, $bar) -ForegroundColor Gray
}
Write-Host ''

# Crashes by hour
Write-Host '  --- Crash pagal valanda ---' -ForegroundColor Cyan
$byHour = $allEvents | Group-Object { $_.Time.Hour }
$hourStats = @{}
foreach ($h in $byHour) { $hourStats[[int]$h.Name] = $h.Count }
for ($i = 0; $i -lt 24; $i++) {
    $count = if ($hourStats.ContainsKey($i)) { $hourStats[$i] } else { 0 }
    if ($count -gt 0) {
        $bar = '█' * [math]::Min($count, 30)
        Write-Host ('  {0,2}:00  {1,3} {2}' -f $i, $count, $bar) -ForegroundColor Gray
    }
}
Write-Host ''

# Stability verdict
Write-Host '  --- Stabilumo ivertinimas ---' -ForegroundColor Cyan
if ($avgPerMonth -lt 1) {
    Write-Host '  [OK] Sistema STABILI. Retai pasitaikantys crash.' -ForegroundColor Green
} elseif ($avgPerMonth -lt 3) {
    Write-Host '  [!] Vidutinis stabilumas. Rekomenduojama tikrinti driverius.' -ForegroundColor Yellow
} elseif ($avgPerMonth -lt 5) {
    Write-Host '  [!!] Nestabili sistema! Tikrinkite:' -ForegroundColor Red
    Write-Host '       - Atnaujinkite driverius (ypac GPU)' -ForegroundColor Yellow
    Write-Host '       - Paleiskite sfc /scannow' -ForegroundColor Yellow
    Write-Host '       - Tikrinkite RAM su Windows Memory Diagnostic' -ForegroundColor Yellow
} else {
    Write-Host '  [!!!] KRITINIS nestabilumas!' -ForegroundColor Red
    Write-Host '        Galimos priezastys:' -ForegroundColor Red
    Write-Host '        - Sugedusi RAM (paleiskite memtest86)' -ForegroundColor Yellow
    Write-Host '        - Perkaitimas (tikrinkite temperaturą)' -ForegroundColor Yellow
    Write-Host '        - Sugadintas Windows (apsvarstykite reinstall)' -ForegroundColor Yellow
    Write-Host '        - Maitinimo problemos (PSU)' -ForegroundColor Yellow
}
