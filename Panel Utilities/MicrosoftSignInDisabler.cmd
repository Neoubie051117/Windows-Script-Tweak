@echo off
setlocal enabledelayedexpansion

:: -------------------------------
:: Admin Check: Must run as Administrator
:: -------------------------------
NET FILE 1>NUL 2>&1 || (
    call :log error "ADMINISTRATOR PRIVILEGES REQUIRED"
    timeout /t 3 /nobreak >nul
    exit /b 1
)

set "REG_ROOT=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies"
set "REG_UI=%REG_ROOT%\System"
set "REG_VIS=%REG_ROOT%\Explorer"

:: -------------------------------
:: Main Menu
:: -------------------------------
:menu
cls
call :log info " <> Microsoft Sign-In Access Manager"
echo.
call :log progress " [1] Disable Microsoft Account Sign-In"
call :log progress " [2] Enable Microsoft Account Sign-In"
echo.
call :log progress " [0] Exit"
echo.
set "user_choice="
set /p "user_choice=>> "

if "%user_choice%"=="1" goto disable
if "%user_choice%"=="2" goto enable
if "%user_choice%"=="0" exit /b
call :log error "Invalid option. Please enter 1, 2, or 0."
pause
goto menu

::# -------------------------------
::# Disable Module (UI Restrictions Only)
::# -------------------------------
:disable
call :log action "Applying UI restrictions..."

:: Core security policy update
reg add "%REG_UI%" /v NoConnectedUser /t REG_DWORD /d 3 /f >nul || goto :reg_failure
reg add "%REG_UI%" /v BlockMicrosoftAccount /t REG_DWORD /d 1 /f >nul || goto :reg_failure

:: Settings page customization
reg add "%REG_VIS%" /v SettingsPageVisibility /t REG_SZ /d "hide:signinoptions" /f >nul && (
    call :log success " - Settings menu item hidden"
) || (
    call :log warning " - Existing settings restriction not modified"
)

call :finalize_changes
call :log success "SIGN-IN UI DISABLED - Store/Outlook services remain active"
pause
exit /b 0

::# -------------------------------
::# Enable Module
::# -------------------------------
:enable
call :log action "Restoring default access..."

:: Policy reversion with legacy value cleanup
reg add "%REG_UI%" /v NoConnectedUser /t REG_DWORD /d 0 /f >nul
reg add "%REG_UI%" /v BlockMicrosoftAccount /t REG_DWORD /d 0 /f >nul
reg delete "%REG_VIS%" /v SettingsPageVisibility /f >nul 2>&1 && (
    call :log success " - Settings visibility restored"
)

call :finalize_changes
call :log success "SIGN-IN OPTIONS ENABLED SYSTEM WIDE"
pause
exit /b 0

::# -------------------------------
::# System Finalization Sequence
::# -------------------------------
:finalize_changes
call :log info "Finalizing system changes..."
gpupdate /target:computer /force >nul
timeout /t 1 /nobreak >nul

taskkill /f /im explorer.exe >nul && (
    start explorer.exe
    call :log success " - Shell refreshed successfully"
)
exit /b 0

::# -------------------------------
::# Registry Failure Handler
::# -------------------------------
:reg_failure
call :log error "CRITICAL: Registry modification failed"
call :log info "Possible causes:"
call :log info " - Group Policy override active"
call :log info " - System file protection interference"
exit /b 1

:: -------------------------------
:: Subroutine: Log Messages with Colors
:: Parameters: %1 = message type, %2 = message text
:: -------------------------------
:log
setlocal
set "type=%~1"
set "msg=%~2"
set "color="

if /I "%type%"=="error" (
    set "color=4"
) else if /I "%type%"=="warning" (
    set "color=6"
) else if /I "%type%"=="info" (
    set "color=3"
) else if /I "%type%"=="progress" (
    set "color=7"
) else if /I "%type%"=="critical" (
    set "color=4F"
) else (
    set "color=2"
)

powershell -Command "[Console]::ForegroundColor='%color%'; Write-Host '%msg%'; [Console]::ResetColor()"
endlocal
exit /b 0