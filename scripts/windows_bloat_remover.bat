@echo off
setlocal
title Windows Bloatware Remover

echo ============================================
echo    Windows Bloatware Remover
echo ============================================
echo.
echo Sis skriptas istrins nereikalingas Windows programas:
echo [Solitaire, News, Weather, Feedback Hub, Tips, Maps, etc.]
echo.

:: Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] KLAIDA: Reikalingos Administratoriaus teises!
    echo Paleiskite Script Launcher kaip Administratoriu.
    echo.
    pause
    exit /b 1
)

echo [!] ISPEJIMAS: Programos bus istrintos visam laikui.
set /p proceed="Ar tikrai norite testi? (Y/N): "
if /i not "%proceed%"=="Y" (
    echo Atsaukta.
    pause
    exit /b 0
)

echo.
echo 🚀 Isinstaliuojamos siuksles...
echo.

:: List of common Windows bloatware IDs
powershell -Command "$apps = @('Microsoft.MicrosoftSolitaireCollection', 'Microsoft.BingNews', 'Microsoft.BingWeather', 'Microsoft.BingSports', 'Microsoft.BingFinance', 'Microsoft.WindowsFeedbackHub', 'Microsoft.GetHelp', 'Microsoft.Getstarted', 'Microsoft.MicrosoftOfficeHub', 'Microsoft.People', 'Microsoft.SkypeApp', 'Microsoft.WindowsMaps', 'Microsoft.3DViewer', 'Microsoft.MixedReality.Portal', 'Microsoft.OneConnect', 'Microsoft.Office.OneNote'); foreach ($app in $apps) { Write-Host \"Salinama: $app...\" -NoNewline; $p = Get-AppxPackage $app; if ($p) { try { $p | Remove-AppxPackage -ErrorAction Stop; Write-Host ' [OK]' -ForegroundColor Green } catch { Write-Host ' [KLAIDA]' -ForegroundColor Red } } else { Write-Host ' [NERASTA]' -ForegroundColor Gray } }"

echo.
echo ============================================
echo    Valymas baigtas!
echo ============================================
echo.
pause
exit /b
