# BSOD Event Log Analysis
Write-Host '  Ieškoma BSOD įrašų Event Log...' -ForegroundColor Cyan
Write-Host ''

# BugCheck events (Event ID 1001 from BugCheck)
$bugChecks = Get-WinEvent -FilterHashtable @{
    LogName = 'System'
    ProviderName = 'Microsoft-Windows-WER-SystemErrorReporting'
    Id = 1001
} -MaxEvents 20 -ErrorAction SilentlyContinue

# Unexpected shutdown events
$unexpectedShutdowns = Get-WinEvent -FilterHashtable @{
    LogName = 'System'
    ProviderName = 'Microsoft-Windows-Kernel-Power'
    Id = 41
} -MaxEvents 20 -ErrorAction SilentlyContinue

# Combine and sort
$allEvents = @()

if ($bugChecks) {
    foreach ($e in $bugChecks) {
        $msg = $e.Message
        $bugCode = ''
        if ($msg -match '0x[0-9a-fA-F]+') { $bugCode = $matches[0] }
        $allEvents += [PSCustomObject]@{
            Time    = $e.TimeCreated
            Type    = 'BSOD'
            Code    = $bugCode
            Message = $msg.Substring(0, [Math]::Min(120, $msg.Length)).Replace("`r",'').Replace("`n",' ')
        }
    }
}

if ($unexpectedShutdowns) {
    foreach ($e in $unexpectedShutdowns) {
        $allEvents += [PSCustomObject]@{
            Time    = $e.TimeCreated
            Type    = 'Kernel Power'
            Code    = 'Event 41'
            Message = 'Netiketas sistemos isjungimas / perkrovimas'
        }
    }
}

if ($allEvents.Count -eq 0) {
    Write-Host '  [OK] BSOD irasu nerasta! Sistema stabili.' -ForegroundColor Green
    Write-Host '  Jokiu melynu ekranu Event Log nera.' -ForegroundColor Green
} else {
    $sorted = $allEvents | Sort-Object Time -Descending
    Write-Host ('  Rasta ivykiu: ' + $sorted.Count) -ForegroundColor Yellow
    Write-Host ''
    Write-Host ('  {0,-20} {1,-14} {2,-14} {3}' -f 'Data/Laikas', 'Tipas', 'Kodas', 'Aprasymas') -ForegroundColor Cyan
    Write-Host ('  ' + '-' * 80) -ForegroundColor DarkGray
    foreach ($ev in $sorted) {
        $color = if ($ev.Type -eq 'BSOD') { 'Red' } else { 'Yellow' }
        Write-Host ('  {0,-20} {1,-14} {2,-14} {3}' -f $ev.Time.ToString('yyyy-MM-dd HH:mm'), $ev.Type, $ev.Code, $ev.Message) -ForegroundColor $color
    }
    Write-Host ''

    # Common BSOD codes reference
    Write-Host '  --- Dazni BSOD kodai ---' -ForegroundColor Cyan
    Write-Host '  0x0000000A  IRQL_NOT_LESS_OR_EQUAL    - Driverio problema' -ForegroundColor Gray
    Write-Host '  0x0000001E  KMODE_EXCEPTION            - Branduolio klaida' -ForegroundColor Gray
    Write-Host '  0x00000050  PAGE_FAULT_IN_NONPAGED     - RAM arba driverio problema' -ForegroundColor Gray
    Write-Host '  0x0000007E  SYSTEM_THREAD_EXCEPTION    - Driverio arba aparaturos klaida' -ForegroundColor Gray
    Write-Host '  0x000000D1  DRIVER_IRQL_NOT_LESS       - Tinklo/disko driverio klaida' -ForegroundColor Gray
    Write-Host '  0x00000124  WHEA_UNCORRECTABLE_ERROR   - Aparaturos gedimas (CPU/RAM)' -ForegroundColor Gray
    Write-Host '  0x0000003B  SYSTEM_SERVICE_EXCEPTION   - Sistemos paslaugos klaida' -ForegroundColor Gray
}
