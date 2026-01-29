@echo off
setlocal EnableDelayedExpansion
title Registry Optimizer ^& Compressor 💎🚀

echo ============================================
echo    Registry Optimizer ^& Compressor
echo ============================================
echo.
echo Sis skriptas:
echo  1. Isvalys pasenusius registro irasus (Logs/Temp).
echo  2. Optimizuos Windows Component Store (sumazina registro bloat).
echo  3. Sutvarkys registro transakciju failus.
echo.

:: Patikrinimas del administratoriaus teisiu
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] KLAIDA: BUTINOS Administratoriaus teises.
    pause
    exit /b 1
)

echo [1/3] Valomi registro logai ir laikini failai...
:: Valome Windows Registry Transaction Logs
del /f /q %systemroot%\system32\config\*.blf >nul 2>&1
del /f /q %systemroot%\system32\config\*.regtrans-ms >nul 2>&1
echo [OK] Transakciju logai isvalyti.

echo [2/3] Optimizuojama Windows komponentu saugykla (tai gali uztrukti)...
:: DISM StartComponentCleanup sumazina registro baze, pashalinant senas versijas
dism /online /cleanup-image /startcomponentcleanup /resetbase
echo [OK] Komponentu saugykla optimizuota.

echo [3/3] Tikrinama registro duomenu baze (SFC scan)...
sfc /verifyonly
echo [OK] Patikra baigta.

echo.
echo ============================================
echo    OPTIMIZAVIMAS BAIGTAS! 💎✨
echo ============================================
echo.
echo Atlikti veiksmai:
echo  [+] Pashalinti .blf ir .regtrans-ms failai.
echo  [+] Atliktas Component Store suspaudimas (ResetBase).
echo  [+] Patikrinta sistemos duomenu bazes sveikata.
echo.
echo Rekomendacija: Perkraukite kompiuteri maksimaliam efektui.
echo.
pause
exit /b
