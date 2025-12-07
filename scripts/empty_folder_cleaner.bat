@echo off
echo ============================================
echo    Empty Folder Cleaner
echo ============================================
echo.

echo Scanning User Profile for empty folders...
echo Path: %USERPROFILE%
echo.

:: Create temporary file for results
set "TEMP_FILE=%TEMP%\empty_folders.txt"
if exist "%TEMP_FILE%" del "%TEMP_FILE%"

:: Find empty folders using PowerShell
echo Finding empty folders...
powershell -Command "Get-ChildItem -Path '%USERPROFILE%' -Directory -Recurse -ErrorAction SilentlyContinue | Where-Object { (Get-ChildItem $_.FullName -Force -ErrorAction SilentlyContinue | Measure-Object).Count -eq 0 } | Select-Object -ExpandProperty FullName | Out-File -FilePath '%TEMP_FILE%' -Encoding UTF8"

:: Count empty folders
set COUNT=0
for /f %%i in ('type "%TEMP_FILE%" 2^>nul ^| find /c /v ""') do set COUNT=%%i

if %COUNT%==0 (
    echo No empty folders found!
    goto :end
)

echo.
echo Found %COUNT% empty folder(s)
echo.
echo Deleting empty folders...
echo.

set DELETED=0
for /f "usebackq delims=" %%f in ("%TEMP_FILE%") do (
    rd "%%f" 2>nul && (
        echo Deleted: %%f
        set /a DELETED+=1
    )
)

echo.
echo ============================================
echo    Cleanup Complete!
echo ============================================
echo.
echo Deleted %DELETED% empty folder(s).

:end
if exist "%TEMP_FILE%" del "%TEMP_FILE%"
pause

