$suspicious = @()
$tasks = Get-ScheduledTask | Where-Object { $_.State -ne 'Disabled' }
foreach ($t in $tasks) {
    $actions = $t.Actions
    foreach ($a in $actions) {
        $exe = $a.Execute
        $taskArgs = $a.Arguments
        $reasons = @()
        if ($exe -match '(?i)(\\temp\\|\\tmp\\|appdata\\local\\temp)') { $reasons += 'Vykdoma is TEMP katalogo' }
        if ($exe -match '(?i)(\\AppData\\)' -and $exe -notmatch '(?i)(Microsoft|Google|Mozilla|Adobe)') { $reasons += 'Nestandartinis AppData kelias' }
        if ($exe -match '(?i)(\\Public\\|\\ProgramData\\)' -and $exe -notmatch '(?i)(Microsoft|HP|Dell|Lenovo|Intel)') { $reasons += 'Vykdoma is Public/ProgramData' }
        if ($taskArgs -match '(?i)(-enc|-encodedcommand|-e\s)') { $reasons += 'Uzkoduota PowerShell komanda' }
        if ($taskArgs -match '(?i)(downloadstring|downloadfile|invoke-webrequest|wget|curl)') { $reasons += 'Atsisiuntimo komanda' }
        if ($taskArgs -match '(?i)(-windowstyle\s+hidden|-w\s+h)') { $reasons += 'Paslepttas langas' }
        if (-not $t.Author -or $t.Author -eq '') { $reasons += 'Nera autoriaus' }
        if ($reasons.Count -gt 0) {
            $authorVal = 'N/A'
            if ($t.Author) { $authorVal = $t.Author }
            $suspicious += [PSCustomObject]@{
                Name    = $t.TaskPath + $t.TaskName
                Exe     = $exe
                Args    = $taskArgs
                Reasons = $reasons -join ', '
                Author  = $authorVal
            }
        }
    }
}
if ($suspicious.Count -eq 0) {
    Write-Host '  [OK] Itartimu uzduociu nerasta!' -ForegroundColor Green
    Write-Host '  Visos aktyvios uzduotys atrodo normaliai.' -ForegroundColor Green
} else {
    Write-Host ('  [!] Rasta itartimu uzduociu: ' + $suspicious.Count) -ForegroundColor Red
    Write-Host ''
    foreach ($s in $suspicious) {
        Write-Host ('  >> ' + $s.Name) -ForegroundColor Red
        Write-Host ('     Vykdo:    ' + $s.Exe) -ForegroundColor Yellow
        if ($s.Args) { Write-Host ('     Arg.:     ' + $s.Args) -ForegroundColor Yellow }
        Write-Host ('     Autorius: ' + $s.Author) -ForegroundColor Gray
        Write-Host ('     Priezastis: ' + $s.Reasons) -ForegroundColor Magenta
        Write-Host ''
    }
    Write-Host '  [!] Patikrinkite sias uzduotis rankiniu budu!' -ForegroundColor Yellow
    Write-Host '  Naudokite: taskschd.msc (Task Scheduler)' -ForegroundColor Gray
}
