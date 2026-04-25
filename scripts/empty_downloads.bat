@echo off
setlocal EnableExtensions
title Empty Downloads
echo ============================================
echo    Downloads Folder Cleaner
echo ============================================
echo.
echo This script will clean your Downloads folder.
echo.

set "downloads=%USERPROFILE%\Downloads"

echo Analyzing Downloads folder...
echo.

:: Count files and calculate size
powershell -File "%~dp0assets\empty_downloads_inline_1.ps1"

echo.
echo ============================================
echo    Options:
echo ============================================
echo.
echo 1. Delete ALL files and folders
echo 2. Delete files older than 30 days
echo 3. Delete files older than 90 days
echo 4. Open Downloads folder (no deletion)
echo 5. Cancel
echo.
set /p choice="Enter your choice (1-5): "

if "%choice%"=="1" goto deleteall
if "%choice%"=="2" goto delete30
if "%choice%"=="3" goto delete90
if "%choice%"=="4" goto open
if "%choice%"=="5" goto end

echo Invalid choice.
goto end

:deleteall
echo.
echo WARNING: This will delete ALL files in your Downloads folder!
set /p confirm="Are you sure? (Y/N): "
if /i not "%confirm%"=="Y" goto end

echo.
echo Deleting all files...
del /q /f /s "%downloads%\*" 2>nul
for /d %%p in ("%downloads%\*") do rmdir "%%p" /s /q 2>nul
echo.
echo Done! Downloads folder is now empty.
goto end

:delete30
echo.
echo Deleting files older than 30 days...
powershell -File "%~dp0assets\empty_downloads_inline_2.ps1"
goto end

:delete90
echo.
echo Deleting files older than 90 days...
powershell -File "%~dp0assets\empty_downloads_inline_3.ps1"
goto end

:open
echo.
echo Opening Downloads folder...
explorer "%downloads%"
goto end

:end
echo.
pause
