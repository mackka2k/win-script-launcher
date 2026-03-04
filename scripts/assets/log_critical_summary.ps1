# Critical Events Summary
Write-Host '  Ieškoma kritiniu ivykiu (visu laiku)...' -ForegroundColor Cyan
Write-Host ''

$logs = @('System', 'Application')
$allCritical = @()

foreach ($logName in $logs) {
    # Critical (Level 1)
    $critical = Get-WinEvent -FilterHashtable @{
        LogName = $logName
        Level   = 1
    } -MaxEvents 100 -ErrorAction SilentlyContinue

    if ($critical) {
        foreach ($e in $critical) {
            $allCritical += [PSCustomObject]@{
                Time     = $e.TimeCreated
                Log      = $logName
                Source   = $e.ProviderName
                Id       = $e.Id
                Message  = if ($e.Message) { $e.Message.Replace("`r",'').Replace("`n",' ').Substring(0, [Math]::Min(80, $e.Message.Length)) } else { 'N/A' }
            }
        }
    }
}

if ($allCritical.Count -eq 0) {
    Write-Host '  [OK] Kritiniu ivykiu nerasta!' -ForegroundColor Green
    Write-Host '  Sistema neturi kritinin klaidu istorijoje.' -ForegroundColor Green
} else {
    $sorted = $allCritical | Sort-Object Time -Descending
    Write-Host ('  Rasta kritiniu ivykiu: ' + $sorted.Count) -ForegroundColor Red
    Write-Host ''
    Write-Host ('  {0,-20} {1,-12} {2,-8} {3,-25} {4}' -f 'Data', 'Log', 'ID', 'Saltinis', 'Zinute') -ForegroundColor Cyan
    Write-Host ('  ' + '-' * 95) -ForegroundColor DarkGray

    foreach ($e in ($sorted | Select-Object -First 30)) {
        $source = $e.Source
        if ($source.Length -gt 24) { $source = $source.Substring(0, 21) + '...' }
        $msg = $e.Message
        if ($msg.Length -gt 40) { $msg = $msg.Substring(0, 37) + '...' }
        Write-Host ('  {0,-20} {1,-12} {2,-8} {3,-25} {4}' -f $e.Time.ToString('yyyy-MM-dd HH:mm'), $e.Log, $e.Id, $source, $msg) -ForegroundColor Red
    }

    if ($sorted.Count -gt 30) {
        Write-Host ('  ... ir dar ' + ($sorted.Count - 30)) -ForegroundColor DarkGray
    }

    Write-Host ''

    # Group by source
    Write-Host '  --- Kritines klaidos pagal saltini ---' -ForegroundColor Cyan
    $bySource = $sorted | Group-Object Source | Sort-Object Count -Descending | Select-Object -First 10
    foreach ($g in $bySource) {
        $bar = '█' * [math]::Min($g.Count, 30)
        Write-Host ('  {0,-35} {1,4} {2}' -f $g.Name.Substring(0, [Math]::Min(34, $g.Name.Length)), $g.Count, $bar) -ForegroundColor Yellow
    }
}
