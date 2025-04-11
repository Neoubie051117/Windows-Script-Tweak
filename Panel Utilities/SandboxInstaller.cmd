@echo off
setlocal enabledelayedexpansion
:: Set text colors for better aesthetics
:: Colors: 
:: A - GREEN (Text UI Messages / Success)
:: C - RED (Errors / Warnings)
:: E - YELLOW (Message Updates)

:: Check if the script is run as Administrator

net session >nul 2>&1
if %errorlevel% neq 0 (
    color C
    echo.
    echo ^<^> Windows Tool Script must be run as administrator.
    echo.
    echo ^<^> Run the script as administrator to: 
    echo. 
    echo            - Access restricted parts of your system
    echo            - Modify system settings
    echo            - Access protected files
    echo            - Make changes that affect other users on the computer
    echo.
    echo ^<^> To run a program as an administrator on Windows:
    echo. 
    echo            - Locate the program you want to run
    echo            - Right-click the program's shortcut or executable file
    echo            - Select Properties
    echo            - In the Compatibility tab, check the "Run this program as an administrator" option
    echo            - Click Apply, then OK
    echo            - Depending on your Windows Account Settings, you may receive a warning message
    echo            - Click Continue to confirm the changes
    echo.
    echo ^<^> Warning: This program will close in after 30 seconds.
    timeout /t 30 >nul && exit /b
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