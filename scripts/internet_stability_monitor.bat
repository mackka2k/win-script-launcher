@echo off
setlocal EnableDelayedExpansion
title Internet Stability Monitor PRO 🌐📊

echo ============================================
echo    Internet Stability Monitor PRO
echo ============================================
echo.
echo Skenuojama jungtis su Cloudflare (1.1.1.1)...
echo Skaiciuojamas Ping, Jitter ir Packet Loss.
echo Sustabdyti galite paspaude CTRL+C.
echo.

powershell -NoProfile -Command "^
$target = '1.1.1.1'; ^
$history = @(); ^
$maxHistory = 20; ^
Write-Host 'Pradedamas monitoringas...' -ForegroundColor Gray; ^
while ($true) { ^
    $ping = Test-Connection -ComputerName $target -Count 1 -ErrorAction SilentlyContinue; ^
    if ($ping) { ^
        $ms = $ping.ResponseTime; ^
        $history += $ms; ^
        if ($history.Length -gt $maxHistory) { $history = $history[1..$maxHistory] }; ^
        ^
        # Skaiciuojame Jitter (vidutinis skirtumas tarp ping'u)
        $jitter = 0; ^
        if ($history.Length -gt 1) { ^
            $diffs = for ($i=1; $i -lt $history.Length; $i++) { [Math]::Abs($history[$i] - $history[$i-1]) }; ^
            $jitter = ($diffs | Measure-Object -Average).Average; ^
        }; ^
        ^
        $color = 'Green'; ^
        if ($ms -gt 100) { $color = 'Yellow' } elseif ($ms -gt 200) { $color = 'Red' }; ^
        ^
        $output = 'Ping: ' + $ms.ToString().PadRight(4) + ' ms | Jitter: ' + [Math]::Round($jitter, 2).ToString().PadRight(5) + ' ms | Status: STABLE'; ^
        Write-Host $output -ForegroundColor $color; ^
    } else { ^
        Write-Host 'Ping: TIMEOUT | Status: PACKET LOSS' -ForegroundColor Red; ^
    } ^
    Start-Sleep -Seconds 1; ^
}"

pause
exit /b
