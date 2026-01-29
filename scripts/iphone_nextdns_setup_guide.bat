@echo off
setlocal EnableDelayedExpansion
title iPhone NextDNS Setup ^& Fix Guide 📱🛡️

echo ============================================
echo    iPhone NextDNS Setup ^& Fix Guide
echo ============================================
echo.
echo Jei tavo iPhone 15 Pro vis dar leidžia pasiekti 
echo nepageidaujamą turinį, sek šias instrukcijas:
echo.

echo [1] IŠJUNK "iCloud Private Relay" (SVARBIAUSIA!)
echo --------------------------------------------
echo Apple Private Relay veikia kaip VPN ir apeina visus filtrus.
echo  1. Eik į: Settings
echo  2. Spausk ant savo vardo (Apple ID)
echo  3. Eik į: iCloud
echo  4. Rask: Private Relay
echo  5. Nustatyk į: OFF
echo.

echo [2] IŠJUNK "Limit IP Address Tracking"
echo --------------------------------------------
echo Šis nustatymas gali priverstinai naudoti Apple DNS serverius.
echo  - Wi-Fi: Settings ^> Wi-Fi ^> spausk (i) prie savo tinklo ^> Išjunk "Limit IP Address Tracking"
echo  - Mobilūs duomenys: Settings ^> Mobile Service ^> Mobile Data Options ^> Išjunk "Limit IP Address Tracking"
echo.

echo [3] ĮDIEK NextDNS PROFILĮ (jei dar neturi)
echo --------------------------------------------
echo Programėlę lengva išjungti, profilį - sunkiau.
echo  1. Atsidaryk Safari savo telefone.
echo  2. Eik į: apple.nextdns.io
echo  3. Configuration ID įvesk: d92cad
echo  4. Įjunk nustatymą "LOCKED" (kad būtų sunkiau ištrinti).
echo  5. Spausk "Download" ir tada iPhone Settings įdiek profilį.
echo.

echo [4] PATIKRINK STATUSĄ
echo --------------------------------------------
echo Atsidaryk Safari ir įvesk: test.nextdns.io
echo Ieškok šių eilučių:
echo  - "status": "ok"
echo  - "profile": "d92cad"
echo.

echo [5] DASHBOARD NUSTATYMAI
echo --------------------------------------------
echo Jei statusas yra "ok", bet vis tiek leidžia naršyti:
echo  1. Prisijunk prie my.nextdns.io/d92cad per PC.
echo  2. Skiltyje "Parental Control" įsitikink, kad jungi:
echo     - [x] Pornography
echo     - [x] Gambling
echo.

echo ============================================
echo PATARIMAS: Kad nepajustum pagundos išjungti, 
echo paprašyk ko nors uždėti Screen Time slaptažodį 
echo ir uždrausti "Account Changes".
echo ============================================
echo.
pause
exit /b
