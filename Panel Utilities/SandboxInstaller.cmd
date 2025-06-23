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
call :log info ">> Checking if Windows Sandbox is already enabled..."

:: Check if the Sandbox feature is already enabled
dism /online /get-featureinfo /featurename:Containers-DisposableClientVM | findstr /i "Enabled" >nul
if %errorlevel%==0 (
    call :log success "Windows Sandbox is already enabled on this system."
    timeout /t 5 >nul
    goto :eof
)

:: Attempt privilege escalation if not running as admin (fallback for manual call)
(net session >nul 2>&1) || (PowerShell start """%~0""" -verb RunAs & exit /b)

:: Step 1: Install required Container packages
set "sandboxList=%TEMP%\sandbox.txt"
dir /b %SystemRoot%\servicing\Packages\*Containers*.mum > "%sandboxList%" 2>nul

if not exist "%sandboxList%" (
    call :log error "!! No container packages found. Are you using Windows Pro or higher?"
    timeout /t 5 >nul
    goto :eof
)

call :log progress "Installing required container packages..."
set "installFail=false"
for /f %%i in ('findstr /i . "%sandboxList%" 2^>nul') do (
    dism /online /norestart /add-package:"%SystemRoot%\servicing\Packages\%%i" >nul
    if errorlevel 1 (
        call :log warning "  - Failed: %%i"
        set "installFail=true"
    ) else (
        call :log info "  - Installed: %%i"
    )
)

del /f /q "%sandboxList%" >nul 2>&1

:: Step 2: Enable Windows Sandbox feature
call :log progress "Enabling Windows Sandbox feature..."
dism /online /enable-feature /featurename:Containers-DisposableClientVM /LimitAccess /Quiet
if errorlevel 1 (
    call :log error "!! Failed to enable Windows Sandbox feature."
    timeout /t 5 >nul
    goto :eof
)

:: Step 3: Final result
if "%installFail%"=="true" (
    call :log warning "Some packages failed, but Sandbox feature was enabled. A reboot may still be required."
) else (
    call :log success "Windows Sandbox installed and enabled successfully."
)

timeout /t 5 >nul

echo.
call :log info "Do you want to restart your system now?"
echo.
echo [0] Cancel
echo [1] Proceed
echo.
set /p restartChoice=">> "

if "%restartChoice%"=="1" (
    call :log warning "Restarting your system..."
    shutdown /r /t 5
) else (
    call :log info "Restart cancelled."
)

goto :eof


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
