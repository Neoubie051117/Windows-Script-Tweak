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

:: Robust Initialization
set "ESC="
for /f %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"
title PC Remote Access Control
cls

:: ANSI Support with Fallback
reg add HKCU\Console /v VirtualTerminalLevel /t REG_DWORD /d 1 /f >nul 2>&1

:main
cls
call :log success "<> Remote Desktop Access Manager"
echo.
call :log info "[1] Disable Remote Services"
call :log info "[2] Enable Remote Services"
echo.
call :log warning "[0] Exit"
echo.
echo.
choice /c 120 /n /m ">>"
set "choice=%errorlevel%"
if "%choice%"=="1" goto disable
if "%choice%"=="2" goto enable
if "%choice%"=="3" exit /b
call :beep
call :log error "Invalid selection. Please try again."
goto main

:disable
call :log progress "Disabling Remote Services..."
call :manage_service TermService fDenyTSConnections 1 "Remote Desktop"
call :manage_service "Remote Assistance" fAllowToGetHelp 0 "Remote Assistance"
call :manage_firewall "Remote Desktop" disable
call :manage_firewall "Remote Assistance" disable
call :toggle_service TermService stop "Remote Desktop Services"
call :toggle_service RemoteRegistry stop "Remote Registry"
call :toggle_service RasMan stop "Remote Access Connection Manager"
call :log success "Remote services successfully disabled."
pause
exit /b

:enable
call :log progress "Enabling Remote Services..."
call :manage_service TermService fDenyTSConnections 0 "Remote Desktop"
call :manage_service "Remote Assistance" fAllowToGetHelp 1 "Remote Assistance"
call :manage_firewall "Remote Desktop" enable
call :manage_firewall "Remote Assistance" enable
call :toggle_service TermService start "Remote Desktop Services"
call :toggle_service RemoteRegistry demand "Remote Registry (Manual)"
call :toggle_service RasMan start "Remote Access Connection Manager"
call :log success "Remote services successfully enabled."
pause
exit /b

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

:toggle_service
setlocal
sc query "%~1" >nul 2>&1 || (
    call :log warning "Service '%~1' not found."
    exit /b 1
)
if /i "%~2"=="stop" (
    sc query "%~1" | find "RUNNING" >nul && (
        net stop "%~1" >nul && (
            sc config "%~1" start= disabled >nul
            call :log success "- %~3 disabled."
        ) || call :log error "- Failed to stop %~3."
    )
) else if /i "%~2"=="start" (
    sc config "%~1" start= auto >nul
    net start "%~1" >nul && (
        call :log success "- %~3 enabled."
    ) || call :log warning "- %~3 started with warnings."
) else if /i "%~2"=="demand" (
    sc config "%~1" start= demand >nul
    call :log success "- %~3 configured."
)
endlocal
exit /b

:manage_service
setlocal
reg add "HKLM\SYSTEM\CurrentControlSet\Control\%~1" /v %~2 /t REG_DWORD /d %~3 /f >nul && (
    call :log success "- %~4 configured."
) || (
    call :log error "- Failed to configure %~4."
)
endlocal
exit /b

:manage_firewall
setlocal
set "cmd=netsh advfirewall firewall set rule group=\"%~1\" new enable="
if /i "%~2"=="disable" set "cmd=!cmd!No"
if /i "%~2"=="enable" set "cmd=!cmd!Yes"
%cmd% >nul && call :log success "- %~1 firewall %~2d." || call :log warning "- Partial %~2 of %~1 firewall rules."
endlocal
exit /b

:beep
powershell -c "[console]::beep(800,200)"
exit /b