@echo off
setlocal enabledelayedexpansion

::-------------------- CHECK FOR ADMIN PRIVILEGES --------------------
net session >nul 2>&1
if errorlevel 1 (
    call :log warning "<> Windows Tool Script must be run as administrator."
    echo.
    call :log warning "<> Run the script as administrator to:"
    call :log error "   - Access restricted parts of your system"
    call :log error "   - Modify system settings"
    call :log error "   - Access protected files"
    call :log error "   - Make changes that affect other users on the computer"
    echo.
    call :log warning "<> To run as admin:"
    call :log error "   - Right-click > Properties > Compatibility > 'Run as administrator'"
    echo.
    call :log warning "<> This program will close in 30 seconds."
    timeout /t 30 >nul
    exit /b
)

::Sandbox Installer function
:SandboxInstaller
cls
color 0A

@Echo off & Cls

(Net session >nul 2>&1)||(PowerShell start """%~0""" -verb RunAs & Exit /B)

pushd "%~dp0"

dir /b %SystemRoot%\servicing\Packages\*Containers*.mum >sandbox.txt

for /f %%i in ('findstr /i . sandbox.txt 2^>nul') do dism /online /norestart /add-package:"%SystemRoot%\servicing\Packages\%%i"

del sandbox.txt

Dism /online /enable-feature /featurename:Containers-DisposableClientVM /LimitAccess /ALL

ping -n 10 localhost