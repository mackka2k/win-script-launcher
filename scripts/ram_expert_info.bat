@echo off
setlocal EnableDelayedExpansion
title RAM Expert Info

echo ============================================
echo    RAM Expert Info
echo ============================================
echo.
echo Informacija apie idietus RAM modulius...
echo.

:: PowerShell naudojimas vienoje eiluteje, kad isvengtume CMD "line continuation" klaidu
powershell -NoProfile -File "%~dp0assets\ram_expert_info_inline_1.ps1"

echo.
echo Darbas baigtas.
pause
exit /b
