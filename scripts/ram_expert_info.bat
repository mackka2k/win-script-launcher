@echo off
setlocal EnableDelayedExpansion
title RAM Expert Info

echo ============================================
echo    RAM Expert Info
echo ============================================
echo.
echo Informacija apie idietus RAM modulius...
echo.

:: PowerShell naudojimas vienoje eiluteje, kad isvengtume CMD "line continuation" klaidu
powershell -NoProfile -Command "$totalMem = [math]::round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2); Write-Host '--------------------------------------------' -ForegroundColor Gray; Write-Host '   Sistemos RAM Suvestine:' -ForegroundColor Yellow; Write-Host '--------------------------------------------' -ForegroundColor Gray; Write-Host 'Bendra talpa: ' -NoNewline; Write-Host \"$totalMem GB\" -ForegroundColor Green; Write-Host ''; Write-Host '--------------------------------------------' -ForegroundColor Gray; Write-Host '   Detali informacija apie modulius:' -ForegroundColor Yellow; Write-Host '--------------------------------------------' -ForegroundColor Gray; $chips = Get-CimInstance Win32_PhysicalMemory; foreach ($chip in $chips) { $capGB = [math]::round($chip.Capacity / 1GB, 2); Write-Host \"Slot: $($chip.DeviceLocator)\" -ForegroundColor White; Write-Host \"  Talpa:       $capGB GB\"; Write-Host \"  Greitis:     $($chip.Speed) MHz\"; Write-Host \"  Gamintojas:  $($chip.Manufacturer)\"; Write-Host \"  Part Number: $($chip.PartNumber)\"; Write-Host '  ------------------------' -ForegroundColor Gray; }; Write-Host ''; Write-Host 'Patarimas: Patikrinkite XMP/DOCP profili BIOS, jei greitis mazesnis nei tiketa.' -ForegroundColor Cyan; Write-Host 'Norint papildyti RAM, naudokite identiska Part Number.' -ForegroundColor Cyan;"

echo.
echo Darbas baigtas.
pause
exit /b
