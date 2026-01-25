@echo off
setlocal EnableDelayedExpansion
title Ultimate Startup Manager

echo ============================================
echo    Ultimate Startup Manager
echo ============================================
echo.
echo [1/2] Vykdomas pilnas auditas...
echo.

:: Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] WARNING: Not running as Administrator.
    echo Some system-wide entries may be hidden.
    echo.
)

:: PowerShell logic to perform audit AND provide cleaning interface
powershell -Command "$regPaths = @('HKCU:\Software\Microsoft\Windows\CurrentVersion\Run', 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'); $items = @(); Write-Host '--- Aktyvios Registry Programos ---' -ForegroundColor Cyan; foreach ($path in $regPaths) { $p = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue; if ($p) { $names = $p | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name; foreach ($name in $names) { if ($name -notmatch 'PSParentPath|PSChildName|PSDrive|PSPath|PSProvider') { $val = (Get-ItemProperty -Path $path).$name; $items += [PSCustomObject]@{ Path = $path; Name = $name; Command = $val }; Write-Host ('[' + $items.Count + '] ' + $name) -ForegroundColor White; Write-Host ('    Path: ' + $val) -ForegroundColor Gray } } } }; Write-Host ''; Write-Host '--- Startup Aplankai ---' -ForegroundColor Cyan; $sUser = [Environment]::GetFolderPath('Startup'); $sSys = 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup'; Get-ChildItem $sUser, $sSys -ErrorAction SilentlyContinue | Select-Object Name, @{n='Folder'; e={$_.DirectoryName}} | Format-Table; Write-Host ''; if ($items.Count -eq 0) { Write-Host 'Valdomu Registry programu nerasta.' -ForegroundColor Yellow; pause; return }; $choice = Read-Host 'Iveskite programos numeri, kuria norite PASALINTI is Startup (arba Q iseiti)'; if ($choice -match '^\d+$') { $idx = [int]$choice; if ($idx -gt 0 -and $idx -le $items.Count) { $target = $items[$idx-1]; Remove-ItemProperty -Path $target.Path -Name $target.Name -Force; Write-Host ('Sekmingai pasalinote: ' + $target.Name) -ForegroundColor Green } else { Write-Host 'Neteisingas numeris.' -ForegroundColor Red } } elseif ($choice -ne 'Q') { Write-Host 'Atsaukta.' }"

echo.
echo ============================================
echo    Procesas baigtas.
echo ============================================
echo Atnaujinkite sarasa, jei norite matyti pokycius.
echo.
pause
exit /b
