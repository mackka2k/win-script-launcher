@echo off
setlocal EnableDelayedExpansion
title Disk Speed Test (WinSAT)
chcp 65001 >nul 2>&1

echo ============================================
echo    Disk Speed Test (Benchmark)
echo ============================================
echo.
echo Sis skriptas naudoja Windows System Assessment Tool (WinSAT),
echo kad ismatuotu tavo disko greiti (MB/s).
echo.

:: Patikrinimas del administratoriaus teisiu
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] KLAIDA: Reikalingos Administratoriaus teises!
    echo Paleiskite si skripta per Script Launcher kaip Administratoriu.
    pause
    exit /b 1
)

echo Pasirinkite diska testavimui (pvz., C arba D):
set /p drive="Disko raide: "
set drive=!drive:~0,1!:

echo.
echo [!] Pradedamas testas diske !drive!...
echo (Tai gali uztrukti apie 15-30 sekundziu)
echo.

:: Vykdome WinSAT testa ir saugome i laikiną failą, kad nereikėtų vykdyti du kartus
winsat disk -drive !drive! > "%temp%\winsat_res.txt" 2>&1

echo.
echo ============================================
echo    TESTO REZULTATAI (Santrauka):
echo ============================================
echo.

:: Isgauname skaicius naudojant patobulinta PowerShell logika
powershell -NoProfile -File "%~dp0assets\disk_speed_test_inline_1.ps1"

del "%temp%\winsat_res.txt" >nul 2>&1

echo.
echo Patarimas: Jei skaiciai virsija 500 MB/s, tai yra SATA SSD.
echo Jei virsija 2000 MB/s, tai yra NVMe SSD.
echo Jei nesiekia 150 MB/s, tai yra mechaninis HDD arba USB.
echo.
pause
exit /b
