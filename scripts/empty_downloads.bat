@echo off
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
powershell -Command "& { $path = '%downloads%'; $files = Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue; $folders = Get-ChildItem -Path $path -Recurse -Directory -ErrorAction SilentlyContinue; $totalSize = ($files | Measure-Object -Property Length -Sum).Sum; $sizeMB = [math]::Round($totalSize / 1MB, 2); $sizeGB = [math]::Round($totalSize / 1GB, 2); Write-Host 'Location: ' -NoNewline; Write-Host $path -ForegroundColor Cyan; Write-Host 'Files: ' -NoNewline; Write-Host ($files.Count) -ForegroundColor Yellow; Write-Host 'Folders: ' -NoNewline; Write-Host ($folders.Count) -ForegroundColor Yellow; if ($sizeGB -gt 1) { Write-Host 'Total Size: ' -NoNewline; Write-Host $sizeGB -ForegroundColor Red -NoNewline; Write-Host ' GB' } else { Write-Host 'Total Size: ' -NoNewline; Write-Host $sizeMB -ForegroundColor Yellow -NoNewline; Write-Host ' MB' } }"

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
powershell -Command "& { $path = '%downloads%'; $days = 30; $cutoff = (Get-Date).AddDays(-$days); $files = Get-ChildItem -Path $path -Recurse -File | Where-Object { $_.LastWriteTime -lt $cutoff }; $count = if ($files) { $files.Count } else { 0 }; $files | Remove-Item -Force -ErrorAction SilentlyContinue; Write-Host ''; Write-Host 'Deleted ' -NoNewline; Write-Host $count -ForegroundColor Green -NoNewline; Write-Host ' files older than ' -NoNewline; Write-Host $days -NoNewline; Write-Host ' days.' }"
goto end

:delete90
echo.
echo Deleting files older than 90 days...
powershell -Command "& { $path = '%downloads%'; $days = 90; $cutoff = (Get-Date).AddDays(-$days); $files = Get-ChildItem -Path $path -Recurse -File | Where-Object { $_.LastWriteTime -lt $cutoff }; $count = if ($files) { $files.Count } else { 0 }; $files | Remove-Item -Force -ErrorAction SilentlyContinue; Write-Host ''; Write-Host 'Deleted ' -NoNewline; Write-Host $count -ForegroundColor Green -NoNewline; Write-Host ' files older than ' -NoNewline; Write-Host $days -NoNewline; Write-Host ' days.' }"
goto end

:open
echo.
echo Opening Downloads folder...
explorer "%downloads%"
goto end

:end
echo.
pause
