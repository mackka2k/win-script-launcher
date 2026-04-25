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
powershell -NoProfile -File "%~dp0assets\gpu_info_extra_inline_1.ps1"

echo.
echo Darbas baigtas.
pause
exit /b
