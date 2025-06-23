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

::-------------------- SYSTEM INFO AND OPTIONS --------------------
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

::-------------------- HANDLE USER INPUT --------------------
set /p menuOptions=">> "

::-------------------- EXECUTE SELECTED OPTION --------------------
if "%menuOptions%"=="0" exit

if "%menuOptions%"=="1"  call :RunTool "Malicious Software Removal Tool" "mrt.exe"
if "%menuOptions%"=="2"  call :RunTool "System Properties" "sysdm.cpl"
if "%menuOptions%"=="3"  call :RunTool "System Information" "msinfo32.exe"
if "%menuOptions%"=="4"  call :RunTool "System Configuration" "msconfig.exe"
if "%menuOptions%"=="5"  call :RunTool "Disk Cleanup Utility" "cleanmgr.exe"

if "%menuOptions%"=="6" (
    call :RunTool "Disk Defragmenter" "dfrgui.exe"
    echo Cleaning temporary files...
    del /f /s /q "%temp%\*" >nul 2>&1
    del /f /s /q "C:\Windows\Prefetch\*" >nul 2>&1
    del /f /s /q "C:\Windows\Temp\*" >nul 2>&1
)

if "%menuOptions%"=="7"  call "%~dp0Panel Utilities\RunWinget.cmd"
if "%menuOptions%"=="8"  call "%~dp0Panel Utilities\RunSFC.cmd"
if "%menuOptions%"=="9"  call "%~dp0Panel Utilities\AddDNSConfiguration.cmd"
if "%menuOptions%"=="10" call "%~dp0Panel Utilities\WindowsRedistributableInstaller.cmd"
if "%menuOptions%"=="11" call "%~dp0Panel Utilities\HyperVInstaller.cmd"
if "%menuOptions%"=="12" call "%~dp0Panel Utilities\SandboxInstaller.cmd"
if "%menuOptions%"=="13" call "%~dp0Panel Utilities\InternetAccessManager.cmd"
if "%menuOptions%"=="14" call "%~dp0Panel Utilities\WindowsBloatRemover.cmd"
if "%menuOptions%"=="15" call "%~dp0Panel Utilities\MicrosoftSignInDisabler.cmd"

goto :WindowsToolScriptMenu

::-------------------- TOOL RUNNER FUNCTION --------------------
:RunTool
setlocal enabledelayedexpansion
set "toolName=%~1"
set "toolCommand=%~2"
cls
call :log progress "Running !toolName!..."
start "" "!toolCommand!"
timeout /t 3 >nul
call :log info "."
goto :WindowsToolScriptMenu



::-------------------- LOG FUNCTION WITH ANSI COLOR OUTPUT --------------------
:log
setlocal enabledelayedexpansion
set "type=%~1"
set "msg=%~2"

set "ESC=["

set "color="
if /i "%type%"=="error" set "color=91"          :: Bright Red
if /i "%type%"=="warning" set "color=93"        :: Bright Yellow
if /i "%type%"=="info" set "color=96"           :: Bright Cyan
if /i "%type%"=="progress" set "color=92"       :: Bright Green
if /i "%type%"=="critical" set "color=91;107"   :: Red text on White background
if /i "%type%"=="" set "color=97"               :: Bright Green (Success default)

<nul set /p="!ESC!!color!m%msg%!ESC!0m"
echo.
endlocal
goto :eof

