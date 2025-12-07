@echo off
echo ============================================
echo    PATH Environment Variable Cleaner
echo ============================================
echo.
echo This script will clean duplicate and invalid entries from PATH.
echo Administrator privileges are required.
echo.

:: Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: This script requires administrator privileges.
    echo Please run as administrator.
    pause
    exit /b 1
)

echo Creating backup of current PATH...
echo.

:: Backup current PATH to a file
for /f "tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path') do set "CURRENT_PATH=%%b"
echo %CURRENT_PATH% > "%TEMP%\path_backup.txt"
echo Backup saved to: %TEMP%\path_backup.txt
echo.

echo Analyzing PATH variable...
echo.

:: Use PowerShell with a script block
powershell -NoProfile -ExecutionPolicy Bypass -Command "$path = [Environment]::GetEnvironmentVariable('Path', 'Machine'); $entries = $path -split ';' | Where-Object { $_.Trim() -ne '' }; Write-Host 'Total entries:' $entries.Count -ForegroundColor Cyan; Write-Host ''; $seen = @{}; $duplicates = 0; $invalid = 0; $valid = @(); foreach ($e in $entries) { $t = $e.Trim(); if ($seen.ContainsKey($t)) { Write-Host '[DUPLICATE]' $t -ForegroundColor Red; $duplicates++; } elseif (-not (Test-Path $t -ErrorAction SilentlyContinue)) { Write-Host '[INVALID]  ' $t -ForegroundColor Yellow; $invalid++; } else { $seen[$t] = $true; $valid += $t; } }; Write-Host ''; Write-Host 'Summary:' -ForegroundColor Yellow; Write-Host 'Duplicates:' $duplicates -ForegroundColor Red; Write-Host 'Invalid:' $invalid -ForegroundColor Yellow; Write-Host 'Valid:' $valid.Count -ForegroundColor Green; Write-Host ''; if ($duplicates -gt 0 -or $invalid -gt 0) { $ans = Read-Host 'Clean PATH? (Y/N)'; if ($ans -eq 'Y' -or $ans -eq 'y') { $newPath = $valid -join ';'; [Environment]::SetEnvironmentVariable('Path', $newPath, 'Machine'); Write-Host ''; Write-Host 'PATH cleaned! Removed' ($duplicates + $invalid) 'entries.' -ForegroundColor Green; } else { Write-Host 'Cancelled.' -ForegroundColor Yellow; } } else { Write-Host 'PATH is clean!' -ForegroundColor Green; }"

echo.
echo ============================================
echo    PATH Cleaner Complete!
echo ============================================
echo.
echo Note: You may need to restart applications for changes to take effect.
echo.
pause
