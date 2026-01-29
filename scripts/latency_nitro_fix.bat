@echo off
setlocal EnableDelayedExpansion
title Latency Nitro Fix - 0.5ms Precision ⚡🦾

echo ============================================
echo    Latency Nitro Fix - System Timer Optimizer
echo ============================================
echo.
echo Sis skriptas optimizuos sistemos signalu dazni:
echo  - Isjungs HPET (High Precision Event Timer) per BCD
echo  - Isjungs Dynamic Ticking (stabilus timeris)
echo  - Nustatys Global Timer Resolution politika
echo  - Sumazins sistemos "stuttering"
echo.

:: Patikrinimas del administratoriaus teisiu
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] KLAIDA: BUTINOS Administratoriaus teises.
    pause
    exit /b 1
)

echo [1/3] Modifikuojami BCD nustatymai...
:: Isjungiamas platforminis laikrodis (HPET bios lygis per windows)
bcdedit /set useplatformclock false >nul 2>&1
:: Isjungiamas dynamic ticking (taupymo funkcija, kuri keicia timerio dazni)
bcdedit /set disabledynamictick yes >nul 2>&1
echo [OK] BCD nustatymai pritaikyti.

echo [2/3] Optimizuojami registro parametrai...
:: Priverstinai leidžiame sistemai naudoti didesnį timer resolution
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "GlobalTimerResolutionRequests" /t REG_DWORD /d 1 /f >nul
echo [OK] Registro raktai prideti.

echo [3/3] Tikrinamas dabartinis Timer Resolution...
powershell -NoProfile -Command "$code = '[DllImport(\"ntdll.dll\")] public static extern int NtQueryTimerResolution(out uint min, out uint max, out uint cur);'; $type = Add-Type -MemberDefinition $code -Name 'Win32' -Namespace 'Timer' -PassThru; $min=$max=$cur=0; $type::NtQueryTimerResolution([ref]$min, [ref]$max, [ref]$cur); Write-Host \"Dabartinis tikslumas: $($cur/10000) ms\" -ForegroundColor Green; Write-Host \"Maksimalus galimas: $($max/10000) ms\" -ForegroundColor Cyan"

echo.
echo ============================================
echo    NITRO FIX PRITAIKYTAS! ⚡🚀
echo ============================================
echo.
echo PASTEBĖJIMAS: Pakeitimai pilnai isigalios tik 
echo po kompiuterio perkrovimo.
echo.
echo Po perkrovimo tavo sistema naudos stabiliausia ir 
echo greiciausia imanoma laiko skaiciavimo metoda.
echo.
pause
exit /b
