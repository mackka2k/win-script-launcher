# Export Log Report
$exportPath = "$env:USERPROFILE\Desktop\Windows_Log_Report.html"

Write-Host '  Generuojama HTML ataskaita...' -ForegroundColor Cyan
Write-Host ''

$logs = @('System', 'Application')
$since = (Get-Date).AddDays(-7)
$allEvents = @()

foreach ($logName in $logs) {
    $events = Get-WinEvent -FilterHashtable @{
        LogName   = $logName
        Level     = @(1, 2, 3)  # Critical, Error, Warning
        StartTime = $since
    } -MaxEvents 200 -ErrorAction SilentlyContinue

    if ($events) {
        foreach ($e in $events) {
            $levelName = switch ($e.Level) { 1 {'Critical'} 2 {'Error'} 3 {'Warning'} default {'Info'} }
            $allEvents += [PSCustomObject]@{
                Time    = $e.TimeCreated
                Log     = $logName
                Level   = $levelName
                Source  = $e.ProviderName
                Id      = $e.Id
                Message = if ($e.Message) { $e.Message.Replace("`r",'').Replace("`n",'<br>') } else { 'N/A' }
            }
        }
    }
}

$sorted = $allEvents | Sort-Object Time -Descending

# Generate HTML
$html = @"
<!DOCTYPE html>
<html lang="lt">
<head>
<meta charset="utf-8">
<title>Windows Log Report - $(Get-Date -Format 'yyyy-MM-dd')</title>
<style>
body { font-family: 'Segoe UI', sans-serif; background: #1a1a2e; color: #eee; padding: 20px; }
h1 { color: #00d4ff; border-bottom: 2px solid #00d4ff; padding-bottom: 10px; }
h2 { color: #ffd700; margin-top: 20px; }
.stats { display: flex; gap: 20px; margin: 20px 0; }
.stat-box { background: #16213e; padding: 15px 25px; border-radius: 10px; text-align: center; }
.stat-num { font-size: 2em; font-weight: bold; }
.critical { color: #ff4444; }
.error { color: #ff8800; }
.warning { color: #ffcc00; }
table { width: 100%; border-collapse: collapse; margin: 10px 0; }
th { background: #0f3460; padding: 10px; text-align: left; }
td { padding: 8px 10px; border-bottom: 1px solid #333; }
tr:hover { background: #16213e; }
.level-Critical { color: #ff4444; font-weight: bold; }
.level-Error { color: #ff8800; }
.level-Warning { color: #ffcc00; }
.footer { margin-top: 30px; color: #666; font-size: 0.9em; border-top: 1px solid #333; padding-top: 10px; }
</style>
</head>
<body>
<h1>Windows Event Log Ataskaita</h1>
<p>Sugeneruota: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | Laikotarpis: paskutines 7 dienos</p>

<div class="stats">
<div class="stat-box"><div class="stat-num critical">$(($sorted | Where-Object Level -eq 'Critical').Count)</div>Critical</div>
<div class="stat-box"><div class="stat-num error">$(($sorted | Where-Object Level -eq 'Error').Count)</div>Errors</div>
<div class="stat-box"><div class="stat-num warning">$(($sorted | Where-Object Level -eq 'Warning').Count)</div>Warnings</div>
<div class="stat-box"><div class="stat-num" style="color:#00d4ff">$($sorted.Count)</div>Viso</div>
</div>

<h2>Ivykiu sarasas</h2>
<table>
<tr><th>Laikas</th><th>Log</th><th>Lygis</th><th>Saltinis</th><th>ID</th><th>Zinute</th></tr>
"@

foreach ($e in $sorted) {
    $msgShort = $e.Message
    if ($msgShort.Length -gt 200) { $msgShort = $msgShort.Substring(0, 200) + '...' }
    $html += "<tr><td>$($e.Time.ToString('yyyy-MM-dd HH:mm'))</td><td>$($e.Log)</td><td class='level-$($e.Level)'>$($e.Level)</td><td>$($e.Source)</td><td>$($e.Id)</td><td>$msgShort</td></tr>`n"
}

$html += @"
</table>
<div class="footer">Sugeneruota su Script Launcher - Windows Log Analyzer</div>
</body>
</html>
"@

$html | Out-File -FilePath $exportPath -Encoding UTF8

Write-Host ('  [OK] Ataskaita issaugota: ' + $exportPath) -ForegroundColor Green
Write-Host ('  Ivykiu: ' + $sorted.Count) -ForegroundColor Cyan
Write-Host ''

$open = Read-Host '  Atidaryti narstykleje? (T/N)'
if ($open -eq 'T') {
    Start-Process $exportPath
}
