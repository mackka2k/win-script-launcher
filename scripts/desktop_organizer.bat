@echo off
setlocal EnableDelayedExpansion
title Desktop Organizer

echo ============================================
echo    Desktop Environment Organizer
echo ============================================
echo.
echo This script will organize your desktop files into categorized folders:
echo [Images, Documents, Media, Archives, Code, Installers]
echo.

set "DESKTOP=%USERPROFILE%\Desktop"

echo Target: %DESKTOP%
echo.
set /p proceed="Are you sure you want to organize your desktop? (Y/N): "
if /i not "%proceed%"=="Y" goto end

echo.
echo Organizing...
echo.

powershell -File "%~dp0assets\desktop_organizer_inline_1.ps1"

echo.
echo ============================================
echo    Organization Complete!
echo ============================================
echo.
pause

:end
exit /b
