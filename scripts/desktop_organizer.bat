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

powershell -Command "$paths = @([Environment]::GetFolderPath('Desktop'), 'C:\Users\Public\Desktop'); $categories = @{ 'Shortcuts' = @('.lnk', '.url'); 'Images' = @('.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.svg', '.psd', '.ai'); 'Documents' = @('.pdf', '.doc', '.docx', '.txt', '.rtf', '.ods', '.odt', '.xlsx', '.pptx', '.csv'); 'Media' = @('.mp3', '.wav', '.mp4', '.mkv', '.mov', '.avi', '.flac'); 'Archives' = @('.zip', '.rar', '.7z', '.tar', '.gz'); 'Code' = @('.py', '.js', '.html', '.css', '.bat', '.ps1', '.sh', '.cpp', '.c', '.h', '.json', '.xml'); 'Installers'= @('.exe', '.msi') }; $userDesktop = [Environment]::GetFolderPath('Desktop'); $moveCount = 0; foreach ($path in $paths) { if (Test-Path $path) { $files = Get-ChildItem -Path $path -File | Where-Object { $_.Name -notmatch 'desktop.ini' }; foreach ($file in $files) { $ext = $file.Extension.ToLower(); $found = $false; foreach ($cat in @('Shortcuts', 'Images', 'Documents', 'Media', 'Archives', 'Code', 'Installers')) { if ($categories[$cat] -contains $ext) { $targetDir = Join-Path $userDesktop $cat; if (-not (Test-Path $targetDir)) { $null = New-Item -Path $targetDir -ItemType Directory }; try { Move-Item -Path $file.FullName -Destination $targetDir -Force -ErrorAction Stop; Write-Host ('[MOVED] ' + $file.Name + ' to ' + $cat) -ForegroundColor Cyan; $moveCount++ } catch { Write-Host ('[FAILED] ' + $file.Name + ' (Requires Admin?)') -ForegroundColor Red }; $found = $true; break } } if (-not $found) { $miscDir = Join-Path $userDesktop 'Misc'; if (-not (Test-Path $miscDir)) { $null = New-Item -Path $miscDir -ItemType Directory }; try { Move-Item -Path $file.FullName -Destination $miscDir -Force -ErrorAction Stop; Write-Host ('[MOVED] ' + $file.Name + ' to Misc') -ForegroundColor Gray; $moveCount++ } catch { } } } } } Write-Host \"`nTotal files organized: $moveCount\" -ForegroundColor Green"

echo.
echo ============================================
echo    Organization Complete!
echo ============================================
echo.
pause

:end
exit /b
