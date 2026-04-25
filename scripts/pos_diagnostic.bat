@echo off
setlocal enabledelayedexpansion
title Pos Diagnostic
chcp 65001 >nul 2>&1
cls

set "output_file=pos_info_%COMPUTERNAME%.txt"

echo =====================================================
echo  KASOS (POS) DIAGNOSTIKOS SKRIPTAS
echo =====================================================
echo.
echo Surenkama informacija... Prasome palaukti.
echo.

echo [POS DIAGNOSTIKA - %DATE% %TIME%] > "%output_file%"
echo Kompiuterio vardas: %COMPUTERNAME% >> "%output_file%"
echo Vartotojas: %USERNAME% >> "%output_file%"
echo. >> "%output_file%"

echo --- GESTAI (EDGE SWIPE) --- >> "%output_file%"
reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\EdgeUI" /v "AllowEdgeSwipe" 2>nul >> "%output_file%"
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{E5323777-F976-4f5b-9B55-B94699C46E44}" /v "Value" 2>nul >> "%output_file%"
echo. >> "%output_file%"

echo --- LIEČIAMA KLAVIATŪRA --- >> "%output_file%"
reg query "HKCU\SOFTWARE\Microsoft\TabletTip\1.7" /v "EnableDesktopModeAutoInvoke" 2>nul >> "%output_file%"
reg query "HKCU\SOFTWARE\Microsoft\TabletTip\1.7" /v "TipbandDesiredVisibility" 2>nul >> "%output_file%"
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI" /v "ShowTabletKeyboard" 2>nul >> "%output_file%"
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Scaling" /v "MonitorSize" 2>nul >> "%output_file%"
echo. >> "%output_file%"

echo --- NARŠYKLĖS (Pristabdymai) --- >> "%output_file%"
echo [Google Chrome] >> "%output_file%"
reg query "HKLM\SOFTWARE\Policies\Google\Chrome" /v "OverscrollHistoryNavigationAllowed" 2>nul >> "%output_file%"
echo [Microsoft Edge] >> "%output_file%"
reg query "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "OverscrollHistoryNavigationAllowed" 2>nul >> "%output_file%"
echo. >> "%output_file%"

echo --- TABLET MODE STATUS --- >> "%output_file%"
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\ImmersiveShell" /v "TabletMode" 2>nul >> "%output_file%"
echo. >> "%output_file%"

echo --- SERVISAS (TabletInputService) --- >> "%output_file%"
sc query "TabletInputService" >> "%output_file%"
echo. >> "%output_file%"

echo --- SISTEMOS INFO (Trumpa) --- >> "%output_file%"
systeminfo | findstr /C:"OS Name" /C:"OS Version" /C:"System Type" >> "%output_file%"

echo.
echo =====================================================
echo  DIAGNOSTIKA BAIGTA!
echo =====================================================
echo.
echo Informacija isisaugota faile:
echo  %output_file%
echo.
echo Prasome si faila atsiusti analizei arba palyginti su kitos kasos failu.
echo.
echo =====================================================
pause
endlocal
