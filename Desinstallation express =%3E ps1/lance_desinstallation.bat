@echo off
REM Se placer dans le dossier où se trouve ce BAT
cd /d "%~dp0"

REM Lancer le script PowerShell avec bypass
powershell -ExecutionPolicy Bypass -File "desinstallation_express.ps1"