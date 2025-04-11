@echo off
setlocal enabledelayedexpansion

:: -------------------------------
:: Admin Check: Must run as Administrator
:: -------------------------------
net session >nul 2>&1
if %errorlevel% neq 0 (
    call :log error "This script must be run as Administrator."
    pause
    exit /b 1
)

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

:: -------------------------------
:: Disable Routine
:: -------------------------------
:disable
echo.
call :log progress "Disabling Microsoft Account Sign-In..."

:: Apply registry changes with error checking
call :apply_registry_changes 3 2 0 0 || exit /b 1

:: Hide Settings Page by adding a marker value
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v SettingsPageVisibility /t REG_SZ /d "hide:signinoptions" /f >nul || (
    call :log error "Failed to hide settings page."
    exit /b 1
)

:: Refresh system policies
call :refresh_policies

:: Modify hosts file: Add marker for Microsoft domains
call :manage_hosts disable || exit /b 1

echo.
call :log success "MICROSOFT ACCOUNT SIGN-IN IS NOW DISABLED"
pause
exit /b

:: -------------------------------
:: Enable Routine
:: -------------------------------
:enable
echo.
call :log progress "Enabling Microsoft Account Sign-In..."

:: Revert registry changes with error checking
call :apply_registry_changes 0 0 1 1 || exit /b 1

:: Remove the settings page hiding marker
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v SettingsPageVisibility /f >nul 2>&1

:: Refresh system policies
call :refresh_policies

:: Modify hosts file: Remove marker entries
call :manage_hosts enable || exit /b 1

echo.
call :log success "MICROSOFT ACCOUNT SIGN-IN IS NOW ENABLED"
pause
exit /b

:: -------------------------------
:: Subroutine: Apply Registry Changes
:: Parameters: %1 = NoConnectedUser, %2 = BlockMicrosoftAccount, %3 = AllowYourAccount, %4 = AllowMicrosoftAccountConnection
:: -------------------------------
:apply_registry_changes
rem Change System policies with error handling
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v NoConnectedUser /t REG_DWORD /d %1 /f >nul || goto :reg_error
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v BlockMicrosoftAccount /t REG_DWORD /d %2 /f >nul || goto :reg_error
reg add "HKLM\SOFTWARE\Microsoft\PolicyManager\default\Settings\AllowYourAccount" /v value /t REG_DWORD /d %3 /f >nul 2>&1 || goto :reg_error
reg add "HKLM\SOFTWARE\Microsoft\PolicyManager\default\Settings\AllowMicrosoftAccountConnection" /v value /t REG_DWORD /d %4 /f >nul 2>&1 || goto :reg_error
exit /b 0

:reg_error
call :log error "Failed to apply registry changes. This system may not support all policies."
exit /b 1

:: -------------------------------
:: Subroutine: Refresh Policies
:: -------------------------------
:refresh_policies
call :log info "Refreshing system policies..."
gpupdate /force >nul
taskkill /f /im explorer.exe >nul && start explorer.exe
exit /b %errorlevel%

:: -------------------------------
:: Subroutine: Manage Hosts File
:: Uses marker comments to reliably add or remove lines
:: -------------------------------
:manage_hosts
set "hosts=%SystemRoot%\System32\drivers\etc\hosts"
set "marker=##MICROSOFT_SIGNIN_BLOCK##"
set "domains=account.microsoft.com login.live.com signup.live.com"

if /I "%1"=="disable" (
    attrib -r "%hosts%" 2>nul
    for %%d in (%domains%) do (
        rem Check if the marker line for this domain exists; if not, add it
        findstr /i /c:"127.0.0.1 %%d %marker%" "%hosts%" >nul || (
            echo 127.0.0.1 %%d %marker% >> "%hosts%"
        )
    )
    attrib +r "%hosts%" 2>nul
) else (
    attrib -r "%hosts%" 2>nul
    rem Create a temporary file without the marker lines
    findstr /v /i /c:"%marker%" "%hosts%" > "%hosts%.tmp"
    move /y "%hosts%.tmp" "%hosts%" >nul
    attrib +r "%hosts%" 2>nul
)
exit /b 0

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
