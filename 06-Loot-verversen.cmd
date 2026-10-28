@echo off
cd /d "%~dp0"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\Queue-LootRefresh.ps1" -Apply %*
if errorlevel 1 echo Lootverversing niet ingepland. Lees de melding hierboven.
pause
