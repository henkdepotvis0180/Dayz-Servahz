@echo off
cd /d "%~dp0"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\Install-Server.ps1" %*
if errorlevel 1 echo Instellen mislukt. Lees de foutmelding hierboven.
pause
