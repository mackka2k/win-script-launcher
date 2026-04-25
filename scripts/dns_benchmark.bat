@echo off
setlocal EnableDelayedExpansion
title DNS Benchmark

echo ============================================
echo    DNS Benchmark
echo ============================================
echo.
echo Tikrinamas populiariausiu DNS serveriu greitis (Latency)...
echo Prasome palaukti, tai uztruks kelias sekundes.
echo.

:: Serveriu sarasas: Pavadinimas, IP
set "servers=Cloudflare:1.1.1.1 Google:8.8.8.8 Quad9:9.9.9.9 OpenDNS:208.67.222.222 Level3:4.2.2.1"

echo --------------------------------------------------
echo  DNS Tiekejas      IP Adresas       Atsakas (ms)
echo --------------------------------------------------

set "min_ms=9999"
set "best_dns="

for %%a in (%servers%) do (
    for /f "tokens=1,2 delims=:" %%b in ("%%a") do (
        set "name=%%b          "
        set "name=!name:~0,15!"
        set "ip=%%c             "
        set "ip=!ip:~0,15!"

        :: Matuojame 3 kartus per PowerShell, kad neveiktu nuo ping lokalizacijos.
        set "ms=N/A"
        for /f "tokens=*" %%d in ('powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0assets\dns_benchmark_probe.ps1" -ComputerName %%c 2^>nul') do (
            set "ms=%%d"

            if !ms! LSS !min_ms! (
                set "min_ms=!ms!"
                set "best_dns=%%b (%%c)"
            )
        )
        echo  !name! !ip! !ms! ms
    )
)

echo --------------------------------------------------
echo.
if defined best_dns (
    echo [PRO PATARIMAS]: Greiciausias DNS tavo tinkle yra:
    echo ^>^> !best_dns! su !min_ms! ms latency.
) else (
    echo [!] Nepavyko nustatyti greiciausio DNS. Patikrink interneto rysi.
)
echo.
pause
exit /b
