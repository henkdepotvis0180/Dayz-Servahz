@echo off
cd /d "%~dp0"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\Start-Server.ps1"
if errorlevel 1 echo Starten mislukt. Lees de foutmelding hierboven.
pause
