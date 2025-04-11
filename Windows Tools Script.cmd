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
    call :log error "<> Windows Tool Script must be run as administrator."
    echo.
    call :log error "<> Run the script as administrator to:" 
    call :log error "   - Access restricted parts of your system"
    call :log error "   - Modify system settings"
    call :log error "   - Access protected files"
    call :log error "   - Make changes that affect other users on the computer"
    echo.
    call :log error "<> To run a program as an administrator on Windows:"
    call :log error "   - Locate the program you want to run"
    call :log error "   - Right-click the program's shortcut or executable file"
    call :log error "   - Select Properties"
    call :log error "   - In the Compatibility tab, check the 'Run this program as an administrator' option"
    call :log error "   - Click Apply, then OK"
    call :log error "   - Depending on your Windows Account Settings, you may receive a warning message"
    call :log error "   - Click Continue to confirm the changes"
    echo.
    call :log warning "<> Warning: This program will close in after 30 seconds."
    timeout /t 30 >nul && exit /b
)

:: Clear screen and provide script explanation
:WindowsToolScriptMenu
cls
call :log success "=========================================================================================================="
call :log success "System Information:"
call :log info "Owner: %username%"
for /f "delims=" %%A in ('powershell -Command "(Get-CimInstance -ClassName Win32_ComputerSystem).Model"') do (
    call :log info "Device Model: %%A"
)
for /f "delims=" %%A in ('powershell -Command "(Get-CimInstance -ClassName Win32_OperatingSystem).Caption"') do (
    set "OSCaption=%%A"
)
for /f "delims=" %%A in ('powershell -Command "(Get-CimInstance -ClassName Win32_OperatingSystem).Version"') do (
    set "OSVersion=%%A"
)
call :log info "OS: %OSCaption% (%OSVersion%)"
call :log success "=========================================================================================================="
echo.
call :log success "                                           WINDOWS TOOLS SCRIPT PANEL                          "
echo.
echo.
call :log info "[1] Malicious Software Removal Tool (MRT)                              [11] Hyper-V Installer"
call :log info "[2] System Properties (Sysdm.cpl)                                      [12] Sandbox Installer"
call :log info "[3] System Information (MSINFO32)                                      [13] Internet Access Manager"
call :log info "[4] System Configuration (MSConfig)                                    [14] Disable Windows Bloat  (Experimental!)"
call :log info "[5] Disk Cleanup Utility (Cleanmgr)                                    [15] Microsoft Sign In Disable"
call :log info "[6] Disk Defragmenter (Dfrgui)"
call :log info "[7] Windows Package Manager (Winget)"
call :log info "[8] System File Checker (SFC)"
call :log info "[9] Add DNS Configuration (IPv4 & IPv6 DNS Integration)"
call :log info "[10] Windows Redistributable Package Installer (Experimental!)"
echo.
call :log warning "[0] Exit"
echo.
echo.

:: Get user input
set /p menuOptions=">> "

:: Handle options
if "%menuOptions%"=="0" exit
if "%menuOptions%"=="1" call :RunTool "Malicious Software Removal Tool" mrt.exe
if "%menuOptions%"=="2" call :RunTool "System Properties" sysdm.cpl
if "%menuOptions%"=="3" call :RunTool "System Information" msinfo32.exe
if "%menuOptions%"=="4" call :RunTool "System Configuration" msconfig.exe
if "%menuOptions%"=="5" call :RunTool "Disk Cleanup Utility" cleanmgr.exe
if "%menuOptions%"=="6" call :RunTool "Disk Defragmenter" dfrgui.exe & del /f /s /q "%temp%\*" 2>nul && del /f /s /q "C:\Windows\Prefetch\*" 2>nul && del /f /s /q "C:\Windows\Temp\*" 2>nul
if "%menuOptions%"=="7" call "%~dp0Panel Utilities\RunWinget.cmd"
if "%menuOptions%"=="8" call "%~dp0Panel Utilities\RunSFC.cmd"
if "%menuOptions%"=="9" call "%~dp0Panel Utilities\AddDNSConfiguration.cmd"
if "%menuOptions%"=="10" call "%~dp0Panel Utilities\WindowsRedistributableInstaller.cmd"
if "%menuOptions%"=="11" call "%~dp0Panel Utilities\HyperVInstaller.cmd"
if "%menuOptions%"=="12" call "%~dp0Panel Utilities\SandboxInstaller.cmd"
if "%menuOptions%"=="13" call "%~dp0Panel Utilities\InternetAccessManager.cmd"
if "%menuOptions%"=="14" call "%~dp0Panel Utilities\WindowsBloatRemover.cmd"
if "%menuOptions%"=="15" call "%~dp0Panel Utilities\MicrosoftSignInDisabler.cmd"
goto :WindowsToolScriptMenu

:: Run specified tool
:RunTool
cls
call :log progress "Running %1..."
%2
call :log info "Press any key to return to the menu..."
pause >nul
goto :WindowsToolScriptMenu

:: Updated logging subsystem (no prefixes)
:log
setlocal
set "type=%~1"
set "msg=%~2"
set "color="

:: Configure color only (no prefixes)
if "%type%"=="error" (
    set "color=Red"
) else if "%type%"=="warning" (
    set "color=Yellow"
) else if "%type%"=="info" (
    set "color=Cyan"
) else if "%type%"=="progress" (
    set "color=Gray"
) else if "%type%"=="critical" (
    set "color=White -b Red"
) else (
    set "color=Green"  :: Success messages
)

:: PowerShell color output
powershell -Command "[Console]::ForegroundColor='%color%'; Write-Host '%msg%'; [Console]::ResetColor()"
endlocal
exit /b 0