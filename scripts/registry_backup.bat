@echo off
echo ============================================
echo    Windows Registry Backup
echo ============================================
echo.

:: Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: This script requires administrator privileges!
    echo Please run as Administrator.
    echo.
    goto :end
)

:: Create backup directory
set "BACKUP_DIR=%USERPROFILE%\Desktop\Registry_Backups"
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

:: Generate timestamp for filename
for /f %%a in ('powershell -Command "Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'"') do set TIMESTAMP=%%a

echo Creating registry backup...
echo Backup location: %BACKUP_DIR%
echo Timestamp: %TIMESTAMP%
echo.

:: Backup critical registry hives
echo [1/5] Backing up HKEY_LOCAL_MACHINE\SOFTWARE...
reg export "HKLM\SOFTWARE" "%BACKUP_DIR%\HKLM_SOFTWARE_%TIMESTAMP%.reg" /y >nul 2>&1
if %errorlevel% equ 0 (
    echo Done.
) else (
    echo Failed!
)

echo [2/5] Backing up HKEY_LOCAL_MACHINE\SYSTEM...
reg export "HKLM\SYSTEM" "%BACKUP_DIR%\HKLM_SYSTEM_%TIMESTAMP%.reg" /y >nul 2>&1
if %errorlevel% equ 0 (
    echo Done.
) else (
    echo Failed!
)

echo [3/5] Backing up HKEY_CURRENT_USER...
reg export "HKCU" "%BACKUP_DIR%\HKCU_%TIMESTAMP%.reg" /y >nul 2>&1
if %errorlevel% equ 0 (
    echo Done.
) else (
    echo Failed!
)

echo [4/5] Backing up HKEY_USERS...
reg export "HKU" "%BACKUP_DIR%\HKU_%TIMESTAMP%.reg" /y >nul 2>&1
if %errorlevel% equ 0 (
    echo Done.
) else (
    echo Failed!
)

echo [5/5] Creating system restore point...
powershell -Command "Checkpoint-Computer -Description 'Registry Backup %TIMESTAMP%' -RestorePointType 'MODIFY_SETTINGS'" >nul 2>&1
if %errorlevel% equ 0 (
    echo Done.
) else (
    echo Failed! (System restore may be disabled)
)

echo.
echo ============================================
echo    Backup Complete!
echo ============================================
echo.

:: Calculate total backup size
set TOTAL_SIZE=0
for %%F in ("%BACKUP_DIR%\*_%TIMESTAMP%.reg") do (
    set /a TOTAL_SIZE+=%%~zF
)
set /a TOTAL_SIZE_MB=TOTAL_SIZE/1024/1024

echo Backup files created:
dir /b "%BACKUP_DIR%\*_%TIMESTAMP%.reg"
echo.
echo Total backup size: %TOTAL_SIZE_MB% MB
echo Location: %BACKUP_DIR%
echo.
echo IMPORTANT:
echo - Keep these backups safe
echo - To restore, double-click a .reg file
echo - System restore point created (if enabled)
echo - Old backups can be deleted to save space
echo.

:: Ask to open backup folder
echo Opening backup folder...
explorer "%BACKUP_DIR%"

:end
pause
