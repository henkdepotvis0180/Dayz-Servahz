@echo off
cd /d "%~dp0"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\Queue-CodeLock.ps1" %*
if errorlevel 1 echo Codeslot niet ingepland. Lees de melding hierboven.
pause
