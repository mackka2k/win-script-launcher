@echo off
setlocal EnableDelayedExpansion
title Explorer Restart PRO 🚀📂

echo ============================================
echo    Explorer Restart PRO 🚀📂
echo ============================================
echo.
echo Sis skriptas atliks pilna Windows UI perkrovima:
echo 1. Isjungs explorer.exe procesus
echo 2. Isvalys piktogramu talpykla (Icon Cache)
echo 3. Isvalys miniaturu talpykla (Thumb Cache)
echo 4. Paleis explorer.exe is naujo
echo.

:: Patikrinimas del administratoriaus teisiu (rekomenduojama cache valymui)
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] ISPEJIMAS: Paleidus be Administratoriaus teisiu,
    echo kai kurie Cache failai gali buti neistrinti.
    echo.
)

echo [1/4] Isjungiamas Windows Explorer...
taskkill /f /im explorer.exe >nul 2>&1
echo [OK] Explorer sustabdytas.

echo [2/4] Valoma piktogramu talpykla (Icon Cache)...
:: Istriname IconCache DB
del /f /s /q /a %LocalAppData%\IconCache.db >nul 2>&1
del /f /s /q /a %LocalAppData%\Microsoft\Windows\Explorer\iconcache_*.db >nul 2>&1
echo [OK] Piktogramu talpykla isvalyta.

echo [3/4] Valoma miniaturu talpykla (Thumbnail Cache)...
del /f /s /q /a %LocalAppData%\Microsoft\Windows\Explorer\thumbcache_*.db >nul 2>&1
echo [OK] Miniaturu talpykla isvalyta.

echo [4/4] Paleidziamas Windows Explorer is naujo...
start explorer.exe
echo [OK] Explorer paleistas.

echo.
echo ============================================
echo    UI PERKRAUTAS! ✨
echo ============================================
echo Jei turejote klaidų su piktogramomis ar uzduociu juosta, 
echo jos turetu buti dingusios.
echo.
pause
exit /b
