# Top Repeating Errors
Write-Host '  Analizuojamos pasikartojancios klaidos...' -ForegroundColor Cyan
Write-Host ''

$logs = @('System', 'Application')
$allErrors = @()

foreach ($logName in $logs) {
    $errors = Get-WinEvent -FilterHashtable @{
        LogName = $logName
        Level   = @(1, 2)  # Critical + Error
    } -MaxEvents 500 -ErrorAction SilentlyContinue

    if ($errors) {
        foreach ($e in $errors) {
            $allErrors += [PSCustomObject]@{
                Log     = $logName
                Source  = $e.ProviderName
                Id      = $e.Id
                First   = $e.TimeCreated
                Message = if ($e.Message) { $e.Message.Replace("`r",'').Replace("`n",' ').Substring(0, [Math]::Min(70, $e.Message.Length)) } else { 'N/A' }
            }
        }
    }
}

if ($allErrors.Count -eq 0) {
    Write-Host '  [OK] Klaidu nerasta!' -ForegroundColor Green
    exit
}

# Group by Source + ID combination
$grouped = $allErrors | Group-Object { $_.Source + '|' + $_.Id } | Sort-Object Count -Descending | Select-Object -First 15

Write-Host ('  Analizuota ivykiu: ' + $allErrors.Count) -ForegroundColor Gray
Write-Host ''
Write-Host '  TOP 15 besikartojancio klaidos:' -ForegroundColor Yellow
Write-Host ''

$rank = 1
foreach ($g in $grouped) {
    $sample = $g.Group[0]
    $firstOccurrence = ($g.Group | Sort-Object First | Select-Object -First 1).First
    $lastOccurrence = ($g.Group | Sort-Object First -Descending | Select-Object -First 1).First

    $countColor = if ($g.Count -ge 50) { 'Red' } elseif ($g.Count -ge 10) { 'Yellow' } else { 'White' }
    $bar = '█' * [math]::Min([math]::Round($g.Count / 2), 30)

    Write-Host ('  #{0,-3} [{1}x] {2}' -f $rank, $g.Count, $bar) -ForegroundColor $countColor
    Write-Host ('       Saltinis:  ' + $sample.Source + ' (ID: ' + $sample.Id + ')') -ForegroundColor Cyan
    Write-Host ('       Log:       ' + $sample.Log) -ForegroundColor Gray
    Write-Host ('       Pirma:     ' + $firstOccurrence.ToString('yyyy-MM-dd HH:mm')) -ForegroundColor Gray
    Write-Host ('       Paskutine: ' + $lastOccurrence.ToString('yyyy-MM-dd HH:mm')) -ForegroundColor Gray
    Write-Host ('       Zinute:    ' + $sample.Message) -ForegroundColor DarkGray
    Write-Host ''
    $rank++
}

# Advice
Write-Host '  --- Rekomendacijos ---' -ForegroundColor Cyan
$topCount = $grouped[0].Count
if ($topCount -ge 100) {
    Write-Host '  [!!] Labai daug pasikartojanciu klaidu!' -ForegroundColor Red
    Write-Host '       Rekomenduojama nedelsiant istirti pagrindini saltini.' -ForegroundColor Yellow
} elseif ($topCount -ge 20) {
    Write-Host '  [!] Yra daznu klaidu. Verta patikrinti saltini.' -ForegroundColor Yellow
} else {
    Write-Host '  [OK] Klaidu kartojimasis normalus.' -ForegroundColor Green
}
