# BSOD Minidump Analysis
$dumpPath = "$env:SystemRoot\Minidump"
$fullDump = "$env:SystemRoot\MEMORY.DMP"

Write-Host '  Ieškoma minidump failų...' -ForegroundColor Cyan
Write-Host ''

$dumps = @()

# Check minidump folder
if (Test-Path $dumpPath) {
    $miniDumps = Get-ChildItem -Path $dumpPath -Filter '*.dmp' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    if ($miniDumps) {
        foreach ($d in $miniDumps) {
            $dumps += [PSCustomObject]@{
                Name     = $d.Name
                Path     = $d.FullName
                Date     = $d.LastWriteTime
                SizeKB   = [math]::Round($d.Length / 1KB, 0)
                Type     = 'Minidump'
            }
        }
    }
}

# Check full memory dump
if (Test-Path $fullDump) {
    $f = Get-Item $fullDump
    $dumps += [PSCustomObject]@{
        Name     = $f.Name
        Path     = $f.FullName
        Date     = $f.LastWriteTime
        SizeKB   = [math]::Round($f.Length / 1KB, 0)
        Type     = 'Full Dump'
    }
}

if ($dumps.Count -eq 0) {
    Write-Host '  [OK] Minidump failu nerasta!' -ForegroundColor Green
    Write-Host ''
    Write-Host '  Tai reiskia:' -ForegroundColor Gray
    Write-Host '  - Sistema nebuvo crashinusi, arba' -ForegroundColor Gray
    Write-Host '  - Minidump generavimas isjungtas' -ForegroundColor Gray
    Write-Host ''
    Write-Host '  Tikrinamas nustatymas...' -ForegroundColor Cyan
    $crashControl = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl' -ErrorAction SilentlyContinue
    if ($crashControl) {
        $dumpType = switch ($crashControl.CrashDumpEnabled) {
            0 { 'Isjungtas (None)' }
            1 { 'Pilnas atminties dump (Complete)' }
            2 { 'Branduolio dump (Kernel)' }
            3 { 'Mazas dump / Minidump' }
            7 { 'Automatinis dump' }
            default { 'Nezinomas' }
        }
        Write-Host ('  Crash dump tipas: ' + $dumpType) -ForegroundColor Yellow
        Write-Host ('  Dump vieta:       ' + $crashControl.DumpFile) -ForegroundColor Gray
        Write-Host ('  Minidump vieta:   ' + $crashControl.MinidumpDir) -ForegroundColor Gray
        if ($crashControl.CrashDumpEnabled -eq 0) {
            Write-Host ''
            Write-Host '  [!] Crash dump ISJUNGTAS! Rekomenduojama ijungti:' -ForegroundColor Red
            Write-Host '      System Properties > Advanced > Startup and Recovery' -ForegroundColor Yellow
        }
    }
} else {
    $sorted = $dumps | Sort-Object Date -Descending
    Write-Host ('  Rasta dump failu: ' + $sorted.Count) -ForegroundColor Yellow
    Write-Host ''
    Write-Host ('  {0,-25} {1,-12} {2,10} {3}' -f 'Failas', 'Tipas', 'Dydis', 'Data') -ForegroundColor Cyan
    Write-Host ('  ' + '-' * 70) -ForegroundColor DarkGray
    foreach ($d in $sorted) {
        $sizeStr = if ($d.SizeKB -ge 1024) { ([math]::Round($d.SizeKB / 1024, 1)).ToString() + ' MB' } else { $d.SizeKB.ToString() + ' KB' }
        Write-Host ('  {0,-25} {1,-12} {2,10} {3}' -f $d.Name, $d.Type, $sizeStr, $d.Date.ToString('yyyy-MM-dd HH:mm')) -ForegroundColor White
    }
    Write-Host ''

    # Total size
    $totalMB = [math]::Round(($sorted | Measure-Object SizeKB -Sum).Sum / 1024, 1)
    Write-Host ('  Bendras dydis: ' + $totalMB + ' MB') -ForegroundColor Cyan
    Write-Host ''

    # Show most recent dump details
    $latest = $sorted[0]
    Write-Host '  --- Naujausio dump informacija ---' -ForegroundColor Cyan
    Write-Host ('  Failas:  ' + $latest.Path) -ForegroundColor White
    Write-Host ('  Data:    ' + $latest.Date.ToString('yyyy-MM-dd HH:mm:ss')) -ForegroundColor White
    Write-Host ''

    # Try to read minidump header for BugCheck code
    if ($latest.Type -eq 'Minidump') {
        try {
            $bytes = [System.IO.File]::ReadAllBytes($latest.Path)
            if ($bytes.Length -ge 64) {
                $bugCheckCode = [BitConverter]::ToUInt32($bytes, 32)
                $bugCheckHex = '0x' + $bugCheckCode.ToString('X8')
                Write-Host ('  BugCheck kodas: ' + $bugCheckHex) -ForegroundColor Red

                $knownCodes = @{
                    '0x0000000A' = 'IRQL_NOT_LESS_OR_EQUAL - Driverio problema'
                    '0x0000001E' = 'KMODE_EXCEPTION_NOT_HANDLED - Branduolio isimtis'
                    '0x00000050' = 'PAGE_FAULT_IN_NONPAGED_AREA - RAM/driverio klaida'
                    '0x0000007E' = 'SYSTEM_THREAD_EXCEPTION - Driverio/aparaturos klaida'
                    '0x0000009F' = 'DRIVER_POWER_STATE_FAILURE - Maitinimo driverio klaida'
                    '0x000000D1' = 'DRIVER_IRQL_NOT_LESS_OR_EQUAL - Driverio IRQL klaida'
                    '0x00000124' = 'WHEA_UNCORRECTABLE_ERROR - Aparaturos gedimas'
                    '0x0000003B' = 'SYSTEM_SERVICE_EXCEPTION - Sistemos klaida'
                    '0x000000EF' = 'CRITICAL_PROCESS_DIED - Kritinis procesas sustojo'
                    '0x00000133' = 'DPC_WATCHDOG_VIOLATION - DPC timeout'
                    '0x000001CA' = 'SYNTHETIC_WATCHDOG_TIMEOUT - Sistemos timeout'
                }
                $codeKey = '0x' + $bugCheckCode.ToString('X8')
                if ($knownCodes.ContainsKey($codeKey)) {
                    Write-Host ('  Reiksme:        ' + $knownCodes[$codeKey]) -ForegroundColor Yellow
                }
            }
        } catch {
            Write-Host '  [!] Nepavyko nuskaityti dump failo.' -ForegroundColor Yellow
        }
    }

    Write-Host ''
    Write-Host '  Detaliai isanalizuoti dump galite su:' -ForegroundColor Gray
    Write-Host '    - WinDbg (Microsoft Store)' -ForegroundColor White
    Write-Host '    - BlueScreenView (NirSoft)' -ForegroundColor White
    Write-Host '    - WhoCrashed (Resplendence)' -ForegroundColor White
}
