@echo off
setlocal enabledelayedexpansion
title Scheduled Task Auditor
chcp 65001 >nul 2>&1

echo ============================================
echo    Scheduled Task Auditor
echo ============================================
echo.
echo Sis skriptas peržiūri suplanuotas užduotis
echo ir padeda aptikti itartinas arba nereikalingas.
echo.

:: Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] ISPEJIMAS: Be Admin teisiu kai kurios uzduotys gali buti nematomos.
    echo.
)

echo Pasirinkite veiksma:
echo [1] Visos suplanuotos uzduotys (suvestine)
echo [2] Tik aktyvios / isjungtos uzduotys
echo [3] Itartiniu uzduociu skenavimas (saugumo patikra)
echo [4] Uzduotys pagal vykdymo laika (artimiausios)
echo [5] Eksportuoti pilna sarasa i faila
echo [6] Atsaukti
echo.

set /p opt="Pasirinkimas (1-6): "

if "%opt%"=="6" exit /b 0

if "%opt%"=="1" goto :all_tasks
if "%opt%"=="2" goto :active_disabled
if "%opt%"=="3" goto :suspicious
if "%opt%"=="4" goto :by_time
if "%opt%"=="5" goto :export
goto :invalid

:all_tasks
echo.
echo ============================================
echo    Visos suplanuotos uzduotys
echo ============================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$tasks = Get-ScheduledTask | Sort-Object TaskPath, TaskName;" ^
    "$enabled = ($tasks | Where-Object State -eq 'Ready').Count;" ^
    "$disabled = ($tasks | Where-Object State -eq 'Disabled').Count;" ^
    "$running = ($tasks | Where-Object State -eq 'Running').Count;" ^
    "Write-Host ('  Viso uzduociu:     ' + $tasks.Count) -ForegroundColor Cyan;" ^
    "Write-Host ('  Aktyvios (Ready):  ' + $enabled) -ForegroundColor Green;" ^
    "Write-Host ('  Isjungtos:         ' + $disabled) -ForegroundColor Yellow;" ^
    "Write-Host ('  Vykdomos dabar:    ' + $running) -ForegroundColor Magenta;" ^
    "Write-Host '';" ^
    "Write-Host '--------------------------------------------';" ^
    "Write-Host '';" ^
    "foreach ($t in $tasks) {" ^
    "  $stColor = switch ($t.State) { 'Ready' {'Green'} 'Disabled' {'DarkGray'} 'Running' {'Magenta'} default {'White'} };" ^
    "  $line = '[' + $t.State.ToString().PadRight(8) + '] ' + $t.TaskPath + $t.TaskName;" ^
    "  Write-Host $line -ForegroundColor $stColor" ^
    "}"
goto :done

:active_disabled
echo.
echo ============================================
echo    Aktyvios / Isjungtos uzduotys
echo ============================================
echo.
echo Pasirinkite filtra:
echo [A] Tik aktyvios (Ready)
echo [D] Tik isjungtos (Disabled)
echo.
set /p filter="Pasirinkimas (A/D): "
if /i "%filter%"=="A" (
    set "stateFilter=Ready"
    set "stateLabel=AKTYVIOS"
) else (
    set "stateFilter=Disabled"
    set "stateLabel=ISJUNGTOS"
)
echo.
echo Rodomos %stateLabel% uzduotys:
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$state = '%stateFilter%';" ^
    "$tasks = Get-ScheduledTask | Where-Object State -eq $state | Sort-Object TaskPath, TaskName;" ^
    "Write-Host ('  Rasta: ' + $tasks.Count + ' uzduociu') -ForegroundColor Cyan;" ^
    "Write-Host '';" ^
    "foreach ($t in $tasks) {" ^
    "  $info = Get-ScheduledTaskInfo -TaskName $t.TaskName -TaskPath $t.TaskPath -ErrorAction SilentlyContinue;" ^
    "  $lastRun = if ($info.LastRunTime -and $info.LastRunTime.Year -gt 1999) { $info.LastRunTime.ToString('yyyy-MM-dd HH:mm') } else { 'Niekada' };" ^
    "  Write-Host ('  ' + $t.TaskPath + $t.TaskName) -ForegroundColor Yellow;" ^
    "  Write-Host ('    Pask. vykdymas: ' + $lastRun) -ForegroundColor Gray;" ^
    "  Write-Host ''" ^
    "}"
goto :done

:suspicious
echo.
echo ============================================
echo    Itartiniu uzduociu skenavimas
echo ============================================
echo.
echo [!] Tikrinamos uzduotys del itartimu pozymiu...
echo     - Vykdo .exe is TEMP, AppData, Public katalogu
echo     - Pasleptus PowerShell skriptus
echo     - Nezinomus/nestandartinius vykdomuosius
echo     - Uzduotys be autoriaus
echo.

:: Run external PS1 script to avoid batch escaping issues
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0assets\task_audit_scan.ps1"
goto :done

:by_time
echo.
echo ============================================
echo    Uzduotys pagal vykdymo laika
echo ============================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$tasks = Get-ScheduledTask | Where-Object State -eq 'Ready';" ^
    "$withInfo = @();" ^
    "foreach ($t in $tasks) {" ^
    "  $info = Get-ScheduledTaskInfo -TaskName $t.TaskName -TaskPath $t.TaskPath -ErrorAction SilentlyContinue;" ^
    "  if ($info.NextRunTime -and $info.NextRunTime.Year -gt 1999) {" ^
    "    $withInfo += [PSCustomObject]@{" ^
    "      Name = $t.TaskPath + $t.TaskName;" ^
    "      NextRun = $info.NextRunTime;" ^
    "      LastRun = if ($info.LastRunTime -and $info.LastRunTime.Year -gt 1999) { $info.LastRunTime.ToString('yyyy-MM-dd HH:mm') } else { 'Niekada' }" ^
    "    }" ^
    "  }" ^
    "};" ^
    "$sorted = $withInfo | Sort-Object NextRun | Select-Object -First 30;" ^
    "Write-Host ('  Artimiausios 30 uzduociu:') -ForegroundColor Cyan;" ^
    "Write-Host '';" ^
    "foreach ($s in $sorted) {" ^
    "  $timeLeft = $s.NextRun - (Get-Date);" ^
    "  $tlStr = if ($timeLeft.TotalMinutes -lt 60) { [math]::Round($timeLeft.TotalMinutes) .ToString() + ' min.' } elseif ($timeLeft.TotalHours -lt 24) { [math]::Round($timeLeft.TotalHours, 1).ToString() + ' val.' } else { [math]::Round($timeLeft.TotalDays, 1).ToString() + ' d.' };" ^
    "  Write-Host ('  [' + $s.NextRun.ToString('yyyy-MM-dd HH:mm') + '] (' + $tlStr + ')') -ForegroundColor Green -NoNewline;" ^
    "  Write-Host (' ' + $s.Name) -ForegroundColor White;" ^
    "  Write-Host ('    Pask. vykdymas: ' + $s.LastRun) -ForegroundColor DarkGray;" ^
    "  Write-Host ''" ^
    "}"
goto :done

:export
echo.
echo ============================================
echo    Eksportas i faila
echo ============================================
echo.
set "exportFile=%USERPROFILE%\Desktop\Scheduled_Tasks_Report.csv"
echo [!] Eksportuojama...

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$tasks = Get-ScheduledTask | Sort-Object TaskPath, TaskName;" ^
    "$results = @();" ^
    "foreach ($t in $tasks) {" ^
    "  $info = Get-ScheduledTaskInfo -TaskName $t.TaskName -TaskPath $t.TaskPath -ErrorAction SilentlyContinue;" ^
    "  $exe = if ($t.Actions.Count -gt 0) { $t.Actions[0].Execute } else { 'N/A' };" ^
    "  $results += [PSCustomObject]@{" ^
    "    Pavadinimas = $t.TaskName;" ^
    "    Kelias = $t.TaskPath;" ^
    "    Busena = $t.State;" ^
    "    Autorius = if ($t.Author) { $t.Author } else { 'N/A' };" ^
    "    Vykdomasis = $exe;" ^
    "    PaskVykdymas = if ($info.LastRunTime -and $info.LastRunTime.Year -gt 1999) { $info.LastRunTime.ToString('yyyy-MM-dd HH:mm') } else { 'Niekada' };" ^
    "    KitasVykdymas = if ($info.NextRunTime -and $info.NextRunTime.Year -gt 1999) { $info.NextRunTime.ToString('yyyy-MM-dd HH:mm') } else { 'N/A' }" ^
    "  }" ^
    "};" ^
    "$results | Export-Csv -Path '%exportFile%' -NoTypeInformation -Encoding UTF8;" ^
    "Write-Host ('[OK] Eksportuota ' + $results.Count + ' uzduociu.') -ForegroundColor Green"

echo.
echo [OK] Failas issaugotas: Desktop\Scheduled_Tasks_Report.csv
echo.
set /p openExport="Atidaryti faila? (T/N): "
if /i "%openExport%"=="T" (
    start "" "%exportFile%"
)
goto :done

:invalid
echo [!] Neteisingas pasirinkimas.
goto :done

:done
echo.
echo ============================================
echo    Procesas baigtas.
echo ============================================
echo.
pause
exit /b
