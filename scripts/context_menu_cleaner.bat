@echo off
echo ============================================
echo    Context Menu Cleaner
echo ============================================
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

echo This script will clean up your right-click context menu.
echo.
echo It will remove common clutter entries from:
echo - Old uninstalled programs
echo - Outdated shell extensions
echo - Unnecessary menu items
echo.
echo Press any key to continue or Ctrl+C to cancel...
pause >nul

echo.
echo Cleaning context menu...
echo.

:: Remove "Edit with Paint 3D"
echo [1/10] Removing Paint 3D entries...
reg delete "HKLM\SOFTWARE\Classes\SystemFileAssociations\.bmp\Shell\3D Edit" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Classes\SystemFileAssociations\.jpg\Shell\3D Edit" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Classes\SystemFileAssociations\.png\Shell\3D Edit" /f >nul 2>&1
echo Done.

:: Remove "Share" from context menu
echo [2/10] Removing Share entries...
reg delete "HKLM\SOFTWARE\Classes\*\shellex\ContextMenuHandlers\ModernSharing" /f >nul 2>&1
echo Done.

:: Remove "Give access to" / "Share with"
echo [3/10] Removing 'Give access to' entries...
reg delete "HKLM\SOFTWARE\Classes\*\shellex\ContextMenuHandlers\Sharing" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Classes\Directory\Background\shellex\ContextMenuHandlers\Sharing" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Classes\Directory\shellex\ContextMenuHandlers\Sharing" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Classes\Drive\shellex\ContextMenuHandlers\Sharing" /f >nul 2>&1
echo Done.

:: Remove "Include in library"
echo [4/10] Removing 'Include in library' entries...
reg delete "HKLM\SOFTWARE\Classes\Folder\ShellEx\ContextMenuHandlers\Library Location" /f >nul 2>&1
echo Done.

:: Remove "Cast to Device"
echo [5/10] Removing 'Cast to Device' entries...
reg delete "HKLM\SOFTWARE\Classes\AllFilesystemObjects\shellex\ContextMenuHandlers\PlayTo" /f >nul 2>&1
echo Done.

:: Remove "Restore previous versions"
echo [6/10] Removing 'Restore previous versions' entries...
reg delete "HKLM\SOFTWARE\Classes\AllFilesystemObjects\shellex\ContextMenuHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Classes\CLSID\{450D8FBA-AD25-11D0-98A8-0800361B1103}\shellex\ContextMenuHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Classes\Directory\shellex\ContextMenuHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Classes\Drive\shellex\ContextMenuHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}" /f >nul 2>&1
echo Done.

:: Remove "Send to" OneNote
echo [7/10] Removing 'Send to OneNote' entries...
reg delete "HKLM\SOFTWARE\Classes\*\shellex\ContextMenuHandlers\OneNote.SendToOneNote" /f >nul 2>&1
echo Done.

:: Remove Windows Defender scan
echo [8/10] Removing Windows Defender scan entries...
reg delete "HKLM\SOFTWARE\Classes\*\shellex\ContextMenuHandlers\EPP" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Classes\Directory\shellex\ContextMenuHandlers\EPP" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Classes\Drive\shellex\ContextMenuHandlers\EPP" /f >nul 2>&1
echo Done.

:: Remove "Edit with Photos"
echo [9/10] Removing 'Edit with Photos' entries...
reg delete "HKLM\SOFTWARE\Classes\AppX43hnxtbyyps62jhe9sqpdzxn1790zetc\Shell\ShellEdit" /f >nul 2>&1
echo Done.

:: Remove "Set as desktop background"
echo [10/10] Removing 'Set as desktop background' entries...
reg delete "HKLM\SOFTWARE\Classes\SystemFileAssociations\image\shell\setdesktopwallpaper" /f >nul 2>&1
echo Done.

echo.
echo ============================================
echo    Context Menu Cleaned!
echo ============================================
echo.
echo Removed entries:
echo [✓] Paint 3D
echo [✓] Share / Modern Sharing
echo [✓] Give access to
echo [✓] Include in library
echo [✓] Cast to Device
echo [✓] Restore previous versions
echo [✓] Send to OneNote
echo [✓] Windows Defender scan
echo [✓] Edit with Photos
echo [✓] Set as desktop background
echo.
echo Your right-click menu is now cleaner and faster!
echo.
echo NOTE: Some entries may reappear after Windows updates.
echo You can run this script again to clean them.
echo.
pause
