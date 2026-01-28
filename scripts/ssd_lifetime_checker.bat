@echo off
title SSD Health Checker

echo ============================================
echo    SSD Health Checker
echo ============================================
echo.

:: Patikrinimas del administratoriaus teisiu
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] ISPEJIMAS: Rekomenduojamos Administratoriaus teises.
    echo.
)

echo Tikrinama SSD/NVMe disku busena...
echo.

:: Supaprastinta versija - rodome tik tai, ka Windows tikrai gali pateikti
powershell -NoProfile -ExecutionPolicy Bypass -Command "$disks = Get-PhysicalDisk | Where-Object { $_.MediaType -match 'SSD|NVMe' }; if (-not $disks) { Write-Host 'Nerasta SSD/NVMe disku.' -ForegroundColor Yellow; exit }; foreach ($disk in $disks) { Write-Host '============================================' -ForegroundColor Cyan; Write-Host ('  ' + $disk.FriendlyName) -ForegroundColor Yellow; Write-Host ('  Modelis: ' + $disk.Model); Write-Host '============================================' -ForegroundColor Cyan; Write-Host ('Sveikatos busena:  ' + $disk.HealthStatus) -ForegroundColor Green; Write-Host ('Talpa:            ' + [math]::round($disk.Size / 1GB, 0) + ' GB'); if ($disk.Temperature -ne $null -and $disk.Temperature -gt 0) { Write-Host ('Temperatura:      ' + $disk.Temperature + ' C') } else { Write-Host 'Temperatura:      Nepasiekiama' }; Write-Host ''; Write-Host 'SMART Duomenys (TBW, Nusidevejimas):' -ForegroundColor Gray; $stats = Get-StorageReliabilityCounter -PhysicalDisk $disk -ErrorAction SilentlyContinue; if ($stats -and ($stats.Wear -ne $null -or $stats.TotalBytesWritten -ne $null)) { if ($stats.Wear -ne $null) { Write-Host ('  Nusidevejimas: ' + $stats.Wear + '%%') } else { Write-Host '  Nusidevejimas: N/A' }; if ($stats.TotalBytesWritten -ne $null -and $stats.TotalBytesWritten -gt 0) { $tbw = [math]::round($stats.TotalBytesWritten / 1TB, 2); Write-Host ('  Irasyta: ' + $tbw + ' TB') } else { Write-Host '  Irasyta: N/A' } } else { Write-Host '  [!] SMART duomenys nepasiekiami per Windows API' -ForegroundColor DarkYellow; Write-Host '  Rekomenduojama naudoti gamintojo irankius:' -ForegroundColor DarkYellow; if ($disk.Model -match 'KINGSTON') { Write-Host '    - Kingston SSD Manager' -ForegroundColor White } elseif ($disk.Model -match 'SAMSUNG') { Write-Host '    - Samsung Magician' -ForegroundColor White } elseif ($disk.Model -match 'CRUCIAL|MICRON') { Write-Host '    - Crucial Storage Executive' -ForegroundColor White } elseif ($disk.Model -match 'WD|WESTERN') { Write-Host '    - Western Digital Dashboard' -ForegroundColor White } else { Write-Host '    - CrystalDiskInfo (universalus)' -ForegroundColor White } }; Write-Host '' }"

echo.
echo ============================================
echo Jei matote "N/A" - tai normalu daugeliui NVMe disku.
echo Windows API neturi pilnos prieigos prie SMART duomenu.
echo.
echo Rekomenduojama: Atsisiuskite gamintojo programa detaliai statistikai.
echo ============================================
echo.
pause
exit /b
