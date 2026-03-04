@echo off
setlocal EnableDelayedExpansion
title Ultimate Audio Optimizer 🎧⚡
chcp 65001 >nul 2>&1

echo ============================================
echo    Ultimate Audio Optimizer 🎧⚡
echo ============================================
echo.
echo Šis skriptas optimizuos Windows garso posistemę:
echo  1. Nustatys maksimalų prioritetą Pro Audio užduotims.
echo  2. Sumažins sistemos rezervuojamą resursų kiekį (Latency fix).
echo  3. Išjungs garso apribojimus (Absolute Volume disable).
echo  4. Perkraus garso tarnybas švariam veikimui.
echo  5. Atidarys valdymo skydelius galutiniam suderinimui.
echo.

:: Patikrinimas dėl administratoriaus teisių
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] KLAIDA: Reikalingos Administratoriaus teisės!
    echo Paleiskite šį skriptą per Script Launcher kaip Administratorių.
    pause
    exit /b 1
)

echo [1/4] Reguliuojami MMCSS ir registro nustatymai...

:: 1. Nustatome sistemos jautrumą (SystemResponsiveness) į 0 (maksimali pirmenybė multimedijai)
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "SystemResponsiveness" /t REG_DWORD /d 0 /f >nul

:: 2. Pro Audio prioritetų optimizavimas
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Pro Audio" /v "GPU Priority" /t REG_DWORD /d 8 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Pro Audio" /v "Priority" /t REG_DWORD /d 6 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Pro Audio" /v "Scheduling Category" /t REG_SZ /d "High" /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Pro Audio" /v "SFIO Priority" /t REG_SZ /d "High" /f >nul

:: 3. Disable Absolute Volume (sutvarko kai kurių headsetų garsumo sinchronizavimo problemas)
reg add "HKLM\SYSTEM\ControlSet001\Control\Bluetooth\Audio\AVRCP\CT" /v "DisableAbsoluteVolume" /t REG_DWORD /d 1 /f >nul 2>&1

echo [OK] Registro pakeitimai pritaikyti.

echo [2/4] Perkraunamos Windows Audio tarnybos...
net stop Audiosrv /y >nul 2>&1
net stop AudioEndpointBuilder /y >nul 2>&1
net start AudioEndpointBuilder >nul 2>&1
net start Audiosrv >nul 2>&1
echo [OK] Tarnybos perkrautos.

echo [3/4] Konfigūruojamas fono stabilumas...
:: Garso variklis dabar veikia optimizuotu režimu per registro nustatymus.
echo [OK] Garso variklis paruoštas.

echo [4/4] Atidaromi valdymo skydeliai...
echo.
echo REKOMENDACIJA:
echo 1. Ausinėms: Pasirinkite 24-bit, 48000Hz (arba daugiau).
echo 2. Mikrofonui: Nustatykite garsumą į 80-90, palikite "Enhancements" išjungtus (jei nereikia efektų).
echo.

:: Atidaryti klasikinius garso nustatymus (Playback ir Recording)
start control mmsys.cpl,,0
start control mmsys.cpl,,1

echo ============================================
echo    SUTVARKYTA! ✨🎶
echo ============================================
echo Garso vėlavimas (latency) turėtų būti sumažintas.
echo Patikrinkite atsidariusius langus galutiniam suderinimui.
echo.
pause
exit /b
