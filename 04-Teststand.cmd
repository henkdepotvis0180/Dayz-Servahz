@echo off
cd /d "%~dp0"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\Install-Server.ps1" -TestMode
if errorlevel 1 echo Teststand instellen mislukt. Lees de foutmelding hierboven.
pause
