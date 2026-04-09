@echo off
setlocal EnableDelayedExpansion
title WiFi Diagnostikos ir Taisymo Irankis

echo ============================================
echo    WiFi Diagnostika ir Taisymas
echo ============================================
echo.
echo Sis skriptas patikrins:
echo  - Ar PC turi WiFi adapteri (hardware)
echo  - Ar WiFi driveriai instaliuoti
echo  - Ar WLAN AutoConfig servisas veikia
echo  - Ar WiFi adapteris ijungtas
echo  - Ar galima prisijungti prie tinklu
echo.
echo Jei rasta problemu - bandys jas sutaisyti automatiskai.
echo.

:: Patikrinimas del administratoriaus teisiu
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] KLAIDA: Reikalingos Administratoriaus teises!
    echo     Paleiskite si skripta kaip Administratorius.
    pause
    exit /b 1
)

set "ISSUES_FOUND=0"
set "FIXES_APPLIED=0"
set "HAS_WIFI_HW=0"
set "HAS_WIFI_DRIVER=0"
set "WIRELESS_FEATURE_OFF=0"

echo ============================================
echo    [1/7] WiFi Hardware Tikrinimas
echo ============================================
echo.

:: Tikrinam ar yra wireless adapteris per PnP
echo Ieskoma WiFi hardware (PnP devices)...
set "PNP_FOUND=0"
for /f "tokens=*" %%a in ('powershell -NoProfile -Command "Get-PnpDevice -Class Net -ErrorAction SilentlyContinue | Where-Object { $_.FriendlyName -match 'Wi-Fi|WiFi|Wireless|WLAN|802\.11' } | Select-Object -ExpandProperty FriendlyName" 2^>nul') do (
    echo   [+] Rastas: %%a
    set "PNP_FOUND=1"
    set "HAS_WIFI_HW=1"
)

if "!PNP_FOUND!"=="0" (
    echo   [-] Wireless PnP irenginys NERASTAS.
    echo.
    echo   Tikrinam USB ir PCI busa del pasleptu WiFi adapteriu...
    for /f "tokens=*" %%a in ('powershell -NoProfile -Command "Get-PnpDevice -ErrorAction SilentlyContinue | Where-Object { $_.FriendlyName -match 'Wi-Fi|WiFi|Wireless|WLAN|802\.11' } | Select-Object Status,Class,FriendlyName | Format-Table -AutoSize | Out-String" 2^>nul') do (
        echo   %%a
    )
) else (
    echo   [OK] WiFi hardware rastas!
)
echo.

echo ============================================
echo    [2/7] WiFi Driveriu Tikrinimas
echo ============================================
echo.

:: Tikrinam ar yra wireless network adapter (driver zaizes)
set "DRIVER_FOUND=0"
netsh wlan show drivers >nul 2>&1
if %errorLevel% neq 0 (
    echo   [-] WiFi driveriai NEINSTALIUOTI arba WLAN servisas neveikia.
    echo       Tai dazna problema su custom Windows.
    set "ISSUES_FOUND=1"
    set "HAS_WIFI_DRIVER=0"
) else (
    echo   Driveriu informacija:
    echo   ---------------------
    netsh wlan show drivers 2>nul
    set "HAS_WIFI_DRIVER=1"
    echo.
    echo   [OK] WiFi driveriai rasti!
)
echo.

echo ============================================
echo    [3/7] WLAN AutoConfig Serviso Tikrinimas
echo ============================================
echo.

:: Tikrinam WLAN AutoConfig serviso busena
set "WLAN_STATE="
set "WLAN_MISSING=0"
for /f "tokens=3" %%a in ('sc query WlanSvc 2^>nul ^| findstr "STATE"') do set "WLAN_STATE=%%a"

if not defined WLAN_STATE (
    echo   [-] WLAN AutoConfig servisas NEEGZISTUOJA!
    echo       Tai reiskia kad wireless komponentai neinstaliuoti.
    set "ISSUES_FOUND=1"
    set "WLAN_MISSING=1"
) else if "!WLAN_STATE!"=="4" (
    echo   [OK] WLAN AutoConfig servisas VEIKIA (RUNNING^).
    set "WLAN_MISSING=0"
) else (
    echo   [-] WLAN AutoConfig servisas SUSTABDYTAS (state: !WLAN_STATE!^).
    set "ISSUES_FOUND=1"
    set "WLAN_MISSING=0"
)

:: Taip pat tikrinam WlanSvc startup type
set "WLAN_START="
for /f "tokens=3" %%a in ('sc qc WlanSvc 2^>nul ^| findstr "START_TYPE"') do set "WLAN_START=%%a"
if defined WLAN_START (
    if "!WLAN_START!"=="4" (
        echo   [!] WLAN servisas yra DISABLED!
        set "ISSUES_FOUND=1"
    ) else if "!WLAN_START!"=="3" (
        echo   [i] WLAN servisas nustatytas i MANUAL.
    ) else if "!WLAN_START!"=="2" (
        echo   [i] WLAN servisas nustatytas i AUTOMATIC.
    )
)
echo.

echo ============================================
echo    [4/7] Tinklo Adapteriu Statuso Tikrinimas
echo ============================================
echo.

:: Tikrinam visus wireless adapterius ir ju statusus
set "ADAPTER_FOUND=0"
echo   Visi tinklo adapteriai:
echo   -----------------------
netsh interface show interface
echo.

for /f "tokens=*" %%a in ('powershell -NoProfile -Command "Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.InterfaceDescription -match 'Wi-Fi|WiFi|Wireless|WLAN|802\.11' -or $_.Name -match 'Wi-Fi|WiFi|Wireless|WLAN' } | Format-Table Name,Status,InterfaceDescription -AutoSize | Out-String" 2^>nul') do (
    set "ADAPTER_FOUND=1"
    echo   %%a
)

if "!ADAPTER_FOUND!"=="0" (
    echo   [-] Joks WiFi adapteris nerastas tinklo adapteriuose.
    set "ISSUES_FOUND=1"
)
echo.

echo ============================================
echo    [5/7] Windows Wireless Komponentu Tikrinimas
echo ============================================
echo.

:: Tikrinam ar irasyta Wireless LAN Service feature
echo   Tikrinam Windows features...
dism /online /get-featureinfo /featurename:WirelessNetworking 2>nul | findstr /i "state" >nul 2>&1
if %errorLevel% equ 0 (
    for /f "tokens=3" %%a in ('dism /online /get-featureinfo /featurename:WirelessNetworking 2^>nul ^| findstr /i "State"') do (
        echo   [i] WirelessNetworking feature: %%a
        if /i "%%a"=="Disabled" (
            echo   [-] Wireless Networking feature ISJUNGTA!
            set "ISSUES_FOUND=1"
            set "WIRELESS_FEATURE_OFF=1"
        )
    )
) else (
    echo   [i] WirelessNetworking feature negalima patikrinti (gali neegzistuoti sioje Windows versijoje^).
)

echo.
echo   Tikrinam reikalingus WiFi sistemos failus...
set "DLL_OK=1"
if not exist "%SystemRoot%\System32\wlanapi.dll" (
    echo   [-] TRUKSTA: wlanapi.dll
    set "DLL_OK=0"
    set "ISSUES_FOUND=1"
) else (
    echo   [OK] wlanapi.dll - yra
)
if not exist "%SystemRoot%\System32\wlansvc.dll" (
    echo   [-] TRUKSTA: wlansvc.dll
    set "DLL_OK=0"
    set "ISSUES_FOUND=1"
) else (
    echo   [OK] wlansvc.dll - yra
)
if not exist "%SystemRoot%\System32\WlanMM.dll" (
    echo   [-] TRUKSTA: WlanMM.dll (ne kritinis^)
) else (
    echo   [OK] WlanMM.dll - yra
)
echo.

echo ============================================
echo    [6/7] WiFi Tinklu Skenavimas
echo ============================================
echo.

netsh wlan show networks 2>nul
if %errorLevel% neq 0 (
    echo   [-] Negalima skenuoti WiFi tinklu. Wireless neveikia.
    set "ISSUES_FOUND=1"
) else (
    echo.
    echo   [OK] WiFi skenavimas veikia!
)
echo.

echo ============================================
echo    [7/7] Diagnostikos Rezultatai
echo ============================================
echo.

if "!ISSUES_FOUND!"=="0" (
    echo   =============================================
    echo   =  VISKAS GERAI! WiFi veikia normaliai.     =
    echo   =============================================
    echo.
    echo   Jusu PC turi WiFi ir jis veikia tinkamai.
    echo.
    pause
    exit /b 0
)

echo   RASTOS PROBLEMOS! Bandoma taisyti...
echo.

:: ===== TAISYMO DALIS =====

echo ============================================
echo    TAISYMAS: Pradedamas automatinis fix
echo ============================================
echo.

:: Fix 1: Ijungiam WLAN AutoConfig servisa
echo [FIX 1/5] Ijungiamas WLAN AutoConfig servisas...
sc config WlanSvc start= auto >nul 2>&1
if %errorLevel% equ 0 (
    echo   [OK] WLAN servisas nustatytas i Automatic.
    set /a FIXES_APPLIED+=1
) else (
    echo   [-] Nepavyko pakeisti WLAN serviso nustatymu.
)
net start WlanSvc >nul 2>&1
if %errorLevel% equ 0 (
    echo   [OK] WLAN servisas paleistas!
    set /a FIXES_APPLIED+=1
) else (
    echo   [-] WLAN servisas jau veikia arba nepavyko paleisti.
)
echo.

:: Fix 2: Ijungiam susijusius servisus
echo [FIX 2/5] Ijungiami susije servisai...
sc config Dhcp start= auto >nul 2>&1
net start Dhcp >nul 2>&1
echo   [i] DHCP Client - paleistas.

sc config NlaSvc start= auto >nul 2>&1
net start NlaSvc >nul 2>&1
echo   [i] Network Location Awareness - paleistas.

sc config Wcmsvc start= auto >nul 2>&1
net start Wcmsvc >nul 2>&1
echo   [i] Windows Connection Manager - paleistas.

sc config WdiServiceHost start= demand >nul 2>&1
sc config WdiSystemHost start= demand >nul 2>&1
echo   [i] Diagnostic servisai - sukonfiguruoti.
set /a FIXES_APPLIED+=1
echo.

:: Fix 3: Ijungiam WiFi adapteri jei isjungtas
echo [FIX 3/5] Ijungiamas WiFi adapteris (jei isjungtas^)...
powershell -NoProfile -Command "Get-NetAdapter | Where-Object { ($_.InterfaceDescription -match 'Wi-Fi|WiFi|Wireless|WLAN|802\.11' -or $_.Name -match 'Wi-Fi|WiFi|Wireless') -and $_.Status -ne 'Up' } | Enable-NetAdapter -Confirm:$false" 2>nul
if %errorLevel% equ 0 (
    echo   [OK] WiFi adapteris(-iai^) ijungtas.
    set /a FIXES_APPLIED+=1
) else (
    echo   [i] Nera isjungtu WiFi adapteriu arba nepavyko ijungti.
)
echo.

:: Fix 4: Ijungiam Wireless feature per DISM jei isjungta
echo [FIX 4/5] Tikrinam ir ijungiam Wireless Network feature...
if "!WIRELESS_FEATURE_OFF!"=="1" (
    echo   Ijungiama WirelessNetworking feature per DISM...
    dism /online /enable-feature /featurename:WirelessNetworking /norestart 2>nul
    if %errorLevel% equ 0 (
        echo   [OK] WirelessNetworking feature ijungta!
        set /a FIXES_APPLIED+=1
    ) else (
        echo   [-] Nepavyko ijungti WirelessNetworking feature.
    )
) else (
    echo   [i] Wireless feature jau ijungta arba neegzistuoja.
)
echo.

:: Fix 5: Bandome surasti ir instaliuoti WiFi driverius
echo [FIX 5/5] Ieskoma trukstamu driveriu...
echo   Skenuojama sistema del trukstamu driveriu...
pnputil /scan-devices >nul 2>&1
echo   [i] Irenginiu skenavimas baigtas.

:: Bandome atnaujinti wireless device driverius
powershell -NoProfile -Command "$devices = Get-PnpDevice -Class Net -ErrorAction SilentlyContinue | Where-Object { $_.FriendlyName -match 'Wi-Fi|WiFi|Wireless|WLAN|802\.11' -and $_.Status -ne 'OK' }; if ($devices) { foreach($d in $devices) { Write-Host '  Bandoma atnaujinti:' $d.FriendlyName; pnputil /enable-device $d.InstanceId 2>$null }; Write-Host '  [OK] Irenginiai ijungti.' } else { Write-Host '  [i] Visi WiFi irenginiai jau OK arba nerasti.' }" 2>nul
echo.

echo ============================================
echo    TAISYMO REZULTATAI
echo ============================================
echo.
echo   Pritaikyti taisymai: !FIXES_APPLIED!
echo.
echo   Rekomenduojama:
echo   1. Perkraukite kompiuteri ir patikrinkite WiFi.
echo   2. Jei WiFi vis dar neveikia, gali buti kad:
echo      - Jusu PC neturi WiFi adapterio (pvz. stacionarus PC^)
echo      - Custom Windows nukirpo WiFi driverius/servisus
echo      - Reikia rankiniu budu instaliuoti WiFi driverius
echo.
echo   DRIVERIU PAIESKA:
echo   -----------------
echo   Jei WiFi hardware rastas bet driveriai ne - atsisiunkite:
echo.
echo   Intel WiFi: https://www.intel.com/content/www/us/en/download/18649/
echo   Realtek WiFi: https://www.realtek.com/en/downloads
echo   Broadcom/Qualcomm: ieskokite pagal jusu adapterio modeli
echo.
echo   Arba naudokite: devmgmt.msc (Device Manager^) - Network adapters
echo   - desiniu peliu ant WiFi adapterio - Update driver
echo.

set /p reboot="Ar norite perkrauti dabar? (T/N): "
if /i "%reboot%"=="T" (
    echo Kompiuteris bus perkrautas po 10 sekundziu...
    shutdown /r /t 10 /c "WiFi Fix baigtas - perkraunama sistema"
) else (
    echo Nepamirskite perkrauti kompiuterio!
)
echo.
pause
exit /b
