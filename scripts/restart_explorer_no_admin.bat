@echo off
setlocal EnableExtensions
title Restart Explorer No Admin
taskkill /f /im explorer.exe >nul 2>&1
start explorer.exe
exit
