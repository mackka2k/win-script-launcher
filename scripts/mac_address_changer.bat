@echo off
setlocal
title Ultimate MAC Address Changer

echo ============================================
echo      Ultimate MAC Address Changer
echo ============================================
echo.

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] KLAIDA: Reikalingos Administratoriaus teises.
    pause
    exit /b 1
)

:: Enhanced version with Full Network Refresh on Reset
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$regPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002BE10318}'; " ^
    "$adapters = @(Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }); " ^
    "if ($adapters.Count -eq 0) { $adapters = @(Get-NetAdapter) }; " ^
    "if ($adapters.Count -eq 0) { Write-Host 'Tinklo adapteriu nerasta.' -ForegroundColor Red; return }; " ^
    "for ($i=0; $i -lt $adapters.Count; $i++) { $a = $adapters[$i]; Write-Host ('[' + ($i+1) + '] ' + $a.Name + ' (' + $a.MacAddress + ')') -ForegroundColor Cyan }; " ^
    "Write-Host ''; Write-Host '[R] ATSTATYTI originalu MAC'; Write-Host '[Q] Iseiti'; " ^
    "$choice = Read-Host 'Pasirinkimas'; if ($choice -eq 'Q') { return }; " ^
    "if ($choice -eq 'R') { " ^
    "  $idx = Read-Host 'Adapterio numeris'; $sel = $adapters[[int]$idx - 1]; " ^
    "  Write-Host 'Vykdomas pilnas tinklo atstatymas...' -ForegroundColor Yellow; " ^
    "  # 1. Release current IP ^
       ipconfig /release $sel.Name 2>$null | Out-Null; " ^
    "  # 2. Remove Registry Key ^
       foreach ($key in (Get-ChildItem $regPath -ErrorAction SilentlyContinue)) { " ^
    "    $v = Get-ItemProperty $key.PSPath -Name 'NetCfgInstanceId' -ErrorAction SilentlyContinue; " ^
    "    if ($v -and $v.NetCfgInstanceId -eq $sel.DeviceId) { " ^
    "      Remove-ItemProperty -Path $key.PSPath -Name 'NetworkAddress' -ErrorAction SilentlyContinue; " ^
    "      Write-Host 'Registras isvalytas.' -ForegroundColor Gray; break " ^
    "    } " ^
    "  }; " ^
    "  # 3. Restart Adapter ^
       Disable-NetAdapter -Name $sel.Name -Confirm:$false; Enable-NetAdapter -Name $sel.Name -Confirm:$false; " ^
    "  # 4. Renew IP ^
       Write-Host 'Ieskoma r輿io su routeriu (Renew)...' -ForegroundColor Cyan; " ^
       "Start-Sleep -s 3; " ^
       "ipconfig /renew $sel.Name | Out-Null; " ^
       "ipconfig /flushdns | Out-Null; " ^
    "  Write-Host 'ORIGINALUS MAC ATSTATYTAS IR INTERNETAS GAIVINAMAS!' -ForegroundColor Green; return " ^
    "}; " ^
    "if ($choice -match '^\d+$' -and [int]$choice -le $adapters.Count) { " ^
    "  $sel = $adapters[[int]$choice - 1]; $newMac = ''; for($j=0; $j -lt 6; $j++) { $newMac += '{0:X2}' -f (Get-Random -Min 0 -Max 255) }; " ^
    "  $chars = '26AE'; $randChar = $chars[(Get-Random -Max 4)]; " ^
    "  $newMac = $newMac.Substring(0,1) + $randChar + $newMac.Substring(2); " ^
    "  Write-Host ('Gaminamas naujas tapatybes kodas: ' + $newMac) -ForegroundColor Yellow; " ^
    "  $found = $false; foreach ($key in (Get-ChildItem $regPath -ErrorAction SilentlyContinue)) { " ^
    "    $v = Get-ItemProperty $key.PSPath -Name 'NetCfgInstanceId' -ErrorAction SilentlyContinue; " ^
    "    if ($v -and $v.NetCfgInstanceId -eq $sel.DeviceId) { " ^
    "      Set-ItemProperty -Path $key.PSPath -Name 'NetworkAddress' -Value $newMac -Force; " ^
    "      $found = $true; break " ^
    "    } " ^
    "  }; " ^
    "  if ($found) { " ^
    "    Write-Host 'Registras atnaujintas. Perkrauliamas adapteris...' -ForegroundColor Cyan; " ^
    "    Disable-NetAdapter -Name $sel.Name -Confirm:$false; Enable-NetAdapter -Name $sel.Name -Confirm:$false; " ^
    "    Write-Host 'SEKMINGAI PAKEISTA! Interneto rysys turetu gri恆i po 5-10 sek.' -ForegroundColor Green " ^
    "  } else { Write-Host 'Klaida: Adapteris nerastas.' -ForegroundColor Red } " ^
    "} else { Write-Host 'Atsaukta.' }"

echo.
echo ============================================
pause
exit /b
