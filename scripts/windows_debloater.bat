@echo off
echo ============================================
echo    Windows 11 Debloater
echo ============================================
echo.
echo This script will download and run Win11Debloat
echo from: https://github.com/Raphire/Win11Debloat
echo.
echo What it does:
echo - Removes Windows bloatware apps
echo - Disables telemetry and tracking
echo - Removes Edge, OneDrive, Cortana (optional)
echo - Disables ads and suggestions
echo - Improves privacy and performance
echo.

:: Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: This script requires administrator privileges!
    echo Please run as Administrator.
    echo.
    pause
    exit /b 1
)

echo Checking for Win11Debloat...
echo.

:: Set paths
set "TEMP_DIR=%TEMP%\Win11Debloat"
set "ZIP_FILE=%TEMP_DIR%\Win11Debloat.zip"
set "EXTRACT_DIR=%TEMP_DIR%\Win11Debloat-master"

:: Check if already extracted
if exist "%EXTRACT_DIR%\Win11Debloat.ps1" (
    echo Win11Debloat already installed, using cached version.
    echo.
) else (
    echo Downloading Win11Debloat repository...
    echo This may take a moment...
    echo.
    
    :: Create temp directory
    if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"
    
    :: Download the entire repository as ZIP
    powershell -Command "& {Invoke-WebRequest -Uri 'https://github.com/Raphire/Win11Debloat/archive/refs/heads/master.zip' -OutFile '%ZIP_FILE%'}"
    
    if %errorlevel% neq 0 (
        echo.
        echo ERROR: Failed to download Win11Debloat.
        echo Please check your internet connection.
        echo.
        pause
        exit /b 1
    )
    
    echo Download complete! Extracting files...
    echo.
    
    :: Extract the ZIP file
    powershell -Command "& {Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%TEMP_DIR%' -Force}"
    
    if %errorlevel% neq 0 (
        echo.
        echo ERROR: Failed to extract Win11Debloat.
        echo.
        pause
        exit /b 1
    )
    
    :: Clean up ZIP file
    del "%ZIP_FILE%" 2>nul
    
    echo Extraction complete!
    echo.
)

echo ============================================
echo    Running Win11Debloat...
echo ============================================
echo.
echo IMPORTANT:
echo - A new window will open for the debloater
echo - Choose what you want to remove/disable in that window
echo - Read each option carefully before proceeding
echo - Some changes require a restart
echo.
echo Launching Win11Debloat in new window...
echo.

:: Run the PowerShell script in a new window from the extracted directory
start "Win11Debloat" powershell -ExecutionPolicy Bypass -NoExit -Command "cd '%EXTRACT_DIR%'; .\Win11Debloat.ps1"

echo.
echo A new window has opened with Win11Debloat.
echo Use that window to select your options.
echo This window will close automatically.
echo.
