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

:: Registry Path Shortcuts
set "REG_ROOT=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies"
set "REG_UI=%REG_ROOT%\System"
set "REG_VIS=%REG_ROOT%\Explorer"


:menu
cls
call :log success " <> Microsoft Sign-In Access Manager"
echo.
call :log info " [1] Disable Microsoft Account Sign-In"
call :log info " [2] Enable Microsoft Account Sign-In (with Store Fix)"
echo.
call :log warning " [0] Exit"
echo.
set "user_choice="
set /p "user_choice=>> "

if "%user_choice%"=="1" goto disable
if "%user_choice%"=="2" goto enable
if "%user_choice%"=="0" exit /b
call :log error "Invalid option. Please enter 1, 2, or 0."
pause
goto menu



:: DISABLE MICROSOFT SIGN-IN
:disable
call :log action "Applying UI and account restrictions..."

:: Ensure registry keys exist before adding values
reg query "%REG_UI%" >nul 2>&1 || reg add "%REG_UI%" /f >nul
reg query "%REG_VIS%" >nul 2>&1 || reg add "%REG_VIS%" /f >nul

:: Disable connected account use
reg add "%REG_UI%" /v NoConnectedUser /t REG_DWORD /d 3 /f >nul || goto :reg_failure
reg add "%REG_UI%" /v BlockMicrosoftAccount /t REG_DWORD /d 1 /f >nul || goto :reg_failure

:: Hide Sign-in options from Settings UI
reg add "%REG_VIS%" /v SettingsPageVisibility /t REG_SZ /d "hide:signinoptions" /f >nul && (
    call :log success " - Settings menu item hidden"
) || (
    call :log warning " - Settings visibility not modified"
)

:: Prevent re-enabling through Settings App
reg add "HKLM\SOFTWARE\Microsoft\PolicyManager\default\Settings\AllowYourAccount" /v Value /t REG_DWORD /d 0 /f >nul

call :finalize_changes
call :log success "SIGN-IN UI DISABLED - Store/Outlook may have limited functionality"
pause
exit /b 0



:: ENABLE MICROSOFT SIGN-IN & FIX STORE
:enable
call :log action "Restoring sign-in access and fixing Microsoft Store..."

:: Re-enable account UI
reg add "%REG_UI%" /v NoConnectedUser /t REG_DWORD /d 0 /f >nul
reg add "%REG_UI%" /v BlockMicrosoftAccount /t REG_DWORD /d 0 /f >nul
reg delete "%REG_VIS%" /v SettingsPageVisibility /f >nul 2>&1

:: Remove policy restriction if present
reg delete "HKLM\SOFTWARE\Microsoft\PolicyManager\default\Settings\AllowYourAccount" /f >nul 2>&1

:: Restart related services safely
call :log action "Restarting related services..."
call :start_service "wlidsvc" "Microsoft Sign-in Assistant"
call :start_service "tokenbroker" "Token Broker"
call :start_service "wuauserv" "Windows Update"

:: Clear MS Store cache (safe even if in use)
call :log action "Resetting Microsoft Store cache..."
start /wait "" "wsreset.exe"
if errorlevel 1 (
    call :log warning " - wsreset failed or Store was busy"
    taskkill /f /im WinStore.App.exe >nul 2>&1
    timeout /t 2 /nobreak >nul
    start /wait "" "wsreset.exe"
)

:: Fix networking just in case Store had DNS or socket issues
ipconfig /flushdns >nul
netsh winsock reset >nul
netsh int ip reset >nul

call :finalize_changes
call :log success "SIGN-IN ENABLED - Store and services should now work properly"
pause
exit /b 0


:: Finalize Changes (gpupdate, refresh UI)
:finalize_changes
call :log progress "Finalizing system updates..."
gpupdate /target:computer /force >nul
timeout /t 1 /nobreak >nul

:: Restart Explorer to apply UI/reg changes
taskkill /f /im explorer.exe >nul 2>&1
timeout /t 1 /nobreak >nul
start explorer.exe && (
    call :log success " - User Interface refreshed"
) || (
    call :log warning " - Failed to restart explorer, please do it manually"
)
exit /b 0


:: Registry Write Error Catcher
:reg_failure
call :log error "CRITICAL: Registry modification failed!"
call :log info "Possible causes:"
call :log info " - Group Policy override active"
call :log info " - System file protection is blocking changes"
exit /b 1

:: Service Start With Fallback
:start_service
:: %1 = Service name, %2 = Display name
sc query "%~1" | findstr /i "RUNNING" >nul
if errorlevel 1 (
    net start "%~1" >nul 2>&1 && (
        call :log success " - %~2 started"
    ) || (
        call :log warning " - %~2 could not be started"
    )
) else (
    call :log info " - %~2 already running"
)
exit /b 0


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
