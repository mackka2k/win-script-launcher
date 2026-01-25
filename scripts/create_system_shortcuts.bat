@echo off
setlocal
title System Shortcuts Creator

echo ============================================
echo    System Shortcuts Creator
echo ============================================
echo.
echo This script will add essential Windows tools to your
echo "Shortcuts" folder on the Desktop for quick access.
echo.

set "SYSTEM_DIR=%USERPROFILE%\Desktop\System"

if not exist "%SYSTEM_DIR%" (
    echo Creating System folder...
    mkdir "%SYSTEM_DIR%"
)

echo Adding shortcuts...
echo.

:: Use PowerShell to create the shortcuts with absolute paths and high-res icon resolution
powershell -Command "$s32 = [Environment]::GetFolderPath('System'); $win = [Environment]::GetFolderPath('Windows'); $shell = New-Object -ComObject WScript.Shell; $shortcuts = @( @{ Name = 'Control Panel'; Target = \"$s32\control.exe\"; Icon = \"$s32\shell32.dll,21\" }, @{ Name = 'Task Manager'; Target = \"$s32\taskmgr.exe\"; Icon = \"$s32\taskmgr.exe,0\" }, @{ Name = 'Device Manager'; Target = \"$s32\mmc.exe\"; Args = \"$s32\devmgmt.msc\"; Icon = \"$s32\devmgr.dll,0\" }, @{ Name = 'Disk Management'; Target = \"$s32\mmc.exe\"; Args = \"$s32\diskmgmt.msc\"; Icon = \"$s32\dmdskres.dll,0\" }, @{ Name = 'Registry Editor'; Target = \"$win\regedit.exe\"; Icon = \"$win\regedit.exe,0\" }, @{ Name = 'Services'; Target = \"$s32\mmc.exe\"; Args = \"$s32\services.msc\"; Icon = \"$s32\filemgmt.dll,0\" }, @{ Name = 'System Settings'; Target = 'ms-settings:'; Icon = \"$s32\imageres.dll,-150\" }, @{ Name = 'Command Prompt (Admin)'; Target = \"$s32\cmd.exe\"; Icon = \"$s32\cmd.exe,0\" }, @{ Name = 'Network Center'; Target = \"$s32\control.exe\"; Args = '/name Microsoft.NetworkAndSharingCenter'; Icon = \"$s32\netshell.dll,1\" }, @{ Name = 'Sound'; Target = \"$s32\control.exe\"; Args = 'mmsys.cpl'; Icon = \"$s32\mmsys.cpl,0\" }, @{ Name = 'Firewall'; Target = \"$s32\control.exe\"; Args = 'firewall.cpl'; Icon = \"$s32\FirewallControlPanel.dll,0\" }, @{ Name = 'Region'; Target = \"$s32\control.exe\"; Args = 'intl.cpl'; Icon = \"$s32\intl.cpl,0\" } ); foreach ($s in $shortcuts) { $p = Join-Path '%SYSTEM_DIR%' ($s.Name + '.lnk'); if (Test-Path $p) { Remove-Item $p -Force }; $lnk = $shell.CreateShortcut($p); $lnk.TargetPath = $s.Target; if ($s.Args) { $lnk.Arguments = $s.Args }; if ($s.Icon) { $lnk.IconLocation = $s.Icon }; $lnk.Save(); Write-Host ('[PRECISION FIX] ' + $s.Name) -ForegroundColor Green }"

echo.
echo ============================================
echo    Shortcuts Created!
echo ============================================
echo.
echo Check your Desktop\Shortcuts folder.
echo.
pause
exit /b
