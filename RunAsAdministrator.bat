@echo off
@setlocal enableextensions
@cd /d "%~dp0"
echo @echo off > WSUS.bat
echo powershell -file "%~dp0WSUS.ps1" >> WSUS.bat
powershell -command "& {Set-ExecutionPolicy Unrestricted }"
powershell -file install.ps1
powershell -file WSUS.ps1