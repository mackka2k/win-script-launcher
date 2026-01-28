@echo off
setlocal EnableDelayedExpansion
title GPU Info Extra

echo ============================================
echo    GPU Info Extra
echo ============================================
echo.
echo Informacija apie tavo vaizdo plokste (GPU)...
echo.

:: PowerShell naudojimas vienoje eiluteje, kad isvengtume CMD "line continuation" klaidu
powershell -NoProfile -Command "$gpus = Get-CimInstance Win32_VideoController; foreach ($gpu in $gpus) { $vram = [math]::round($gpu.AdapterRAM / 1GB, 2); Write-Host '--------------------------------------------' -ForegroundColor Gray; Write-Host \" GPU: $($gpu.Name)\" -ForegroundColor Yellow; Write-Host '--------------------------------------------' -ForegroundColor Gray; Write-Host \" Atmiute (VRAM):  $vram GB\"; Write-Host \" Draiveriu versija: $($gpu.DriverVersion)\"; Write-Host \" Draiveriu data:    $($gpu.DriverDate)\"; Write-Host \" Esama raiska:     $($gpu.CurrentHorizontalResolution) x $($gpu.CurrentVerticalResolution) @ $($gpu.CurrentRefreshRate)Hz\"; Write-Host \" Busena:           $($gpu.Status)\"; Write-Host '--------------------------------------------' -ForegroundColor Gray; }"

echo.
echo Darbas baigtas.
pause
exit /b
