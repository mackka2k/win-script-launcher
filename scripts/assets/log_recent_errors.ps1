# Recent Errors - parameter: hours
param([int]$Hours = 24)

$since = (Get-Date).AddHours(-$Hours)
$logs = @('System', 'Application')

Write-Host ('  Laikotarpis: paskutines ' + $Hours + ' val. (nuo ' + $since.ToString('yyyy-MM-dd HH:mm') + ')') -ForegroundColor Cyan
Write-Host ''

$totalErrors = 0
$totalWarnings = 0

foreach ($logName in $logs) {
    Write-Host ('  === ' + $logName + ' Log ===') -ForegroundColor Yellow
    Write-Host ''

    # Errors
    $errors = Get-WinEvent -FilterHashtable @{
        LogName   = $logName
        Level     = 2  # Error
        StartTime = $since
    } -MaxEvents 50 -ErrorAction SilentlyContinue

    # Warnings
    $warnings = Get-WinEvent -FilterHashtable @{
        LogName   = $logName
        Level     = 3  # Warning
        StartTime = $since
    } -MaxEvents 30 -ErrorAction SilentlyContinue

    $errCount = if ($errors) { $errors.Count } else { 0 }
    $warnCount = if ($warnings) { $warnings.Count } else { 0 }
    $totalErrors += $errCount
    $totalWarnings += $warnCount

    $errColor = if ($errCount -ge 10) { 'Red' } elseif ($errCount -ge 1) { 'Yellow' } else { 'Green' }
    Write-Host ('  Klaidu (Error):      ' + $errCount) -ForegroundColor $errColor
    Write-Host ('  Ispejmu (Warning):   ' + $warnCount) -ForegroundColor $(if ($warnCount -ge 20) {'Yellow'} else {'Gray'})
    Write-Host ''

    if ($errors) {
        Write-Host ('  {0,-20} {1,-8} {2,-28} {3}' -f 'Laikas', 'ID', 'Saltinis', 'Zinute') -ForegroundColor Cyan
        Write-Host ('  ' + '-' * 90) -ForegroundColor DarkGray
        foreach ($e in ($errors | Select-Object -First 20)) {
            $msg = $e.Message
            if ($msg) {
                $msg = $msg.Replace("`r", '').Replace("`n", ' ')
                $msg = $msg.Substring(0, [Math]::Min(45, $msg.Length))
            } else {
                $msg = '(zinute nera)'
            }
            $source = $e.ProviderName
            if ($source.Length -gt 27) { $source = $source.Substring(0, 24) + '...' }
            Write-Host ('  {0,-20} {1,-8} {2,-28} {3}' -f $e.TimeCreated.ToString('yyyy-MM-dd HH:mm'), $e.Id, $source, $msg) -ForegroundColor Red
        }
        if ($errCount -gt 20) {
            Write-Host ('  ... ir dar ' + ($errCount - 20) + ' klaidu') -ForegroundColor DarkGray
        }
        Write-Host ''
    }
}

# Summary
Write-Host '  --- Suvestine ---' -ForegroundColor Cyan
$overallColor = if ($totalErrors -ge 20) { 'Red' } elseif ($totalErrors -ge 5) { 'Yellow' } else { 'Green' }
Write-Host ('  Viso klaidu:      ' + $totalErrors) -ForegroundColor $overallColor
Write-Host ('  Viso ispejmu:     ' + $totalWarnings) -ForegroundColor Gray

if ($totalErrors -eq 0) {
    Write-Host ''
    Write-Host '  [OK] Jokiu klaidu nerasta! Sistema veikia gerai.' -ForegroundColor Green
} elseif ($totalErrors -ge 20) {
    Write-Host ''
    Write-Host '  [!!] Daug klaidu! Rekomenduojama istirti priezastis.' -ForegroundColor Red
}
