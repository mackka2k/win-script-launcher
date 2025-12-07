@echo off
echo ============================================
echo    Network Speed Test
echo ============================================
echo.
echo This script will test your internet connection speed.
echo.

echo Testing network connection...
echo.

:: Test basic connectivity
echo [1/3] Checking internet connectivity...
ping -n 1 8.8.8.8 >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: No internet connection detected.
    echo Please check your network connection and try again.
    pause
    exit /b 1
)
echo Connected to internet.
echo.

:: Test download speed using PowerShell
echo [2/3] Testing download speed...
echo This may take 10-30 seconds...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference = 'SilentlyContinue'; Write-Host 'Downloading test file...'; $url = 'http://speedtest.tele2.net/10MB.zip'; $start = Get-Date; try { $webClient = New-Object System.Net.WebClient; $data = $webClient.DownloadData($url); $end = Get-Date; $duration = ($end - $start).TotalSeconds; $sizeMB = $data.Length / 1MB; $speedMbps = ($sizeMB * 8) / $duration; Write-Host ''; Write-Host 'Download Speed: ' -NoNewline; Write-Host ([math]::Round($speedMbps, 2)) -ForegroundColor Green -NoNewline; Write-Host ' Mbps'; Write-Host 'File Size: ' -NoNewline; Write-Host ([math]::Round($sizeMB, 2)) -NoNewline; Write-Host ' MB'; Write-Host 'Time Taken: ' -NoNewline; Write-Host ([math]::Round($duration, 2)) -NoNewline; Write-Host ' seconds'; } catch { Write-Host 'ERROR: Speed test failed.' -ForegroundColor Red; Write-Host $_.Exception.Message; }"

echo.

:: Test latency
echo [3/3] Testing latency (ping)...
echo.
ping -n 10 8.8.8.8 | findstr "Average"

echo.
echo ============================================
echo    Speed Test Complete!
echo ============================================
echo.
pause
