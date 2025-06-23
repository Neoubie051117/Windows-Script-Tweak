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

::Hyper V Installer function
:HyperVInstaller
cls
color 0A
call :log info ">> Checking if Hyper-V is already enabled..."

:: Check if Hyper-V is already enabled
dism /online /get-featureinfo /featurename:Microsoft-Hyper-V | findstr /i "Enabled" >nul
if %errorlevel%==0 (
    call :log success "Hyper-V is already enabled on this system."
    timeout /t 5 >nul
    goto :eof
)


:: Step 1: Check if Packages exist
set "hyperVList=%TEMP%\hyper-v.txt"
dir /b %SystemRoot%\servicing\Packages\*Hyper-V*.mum > "%hyperVList%" 2>nul

if not exist "%hyperVList%" (
    call :log error "!! No Hyper-V packages found. This system may not support Hyper-V."
    goto :eof
)

:: Step 2: Install all Hyper-V packages
call :log progress "Installing Hyper-V required packages..."
set "installFail=false"
for /f %%i in ('findstr /i . "%hyperVList%" 2^>nul') do (
    dism /online /norestart /add-package:"%SystemRoot%\servicing\Packages\%%i" >nul
    if errorlevel 1 (
        call :log warning "  - Failed: %%i"
        set "installFail=true"
    ) else (
        call :log info "  - Installed: %%i"
    )
)

del /f /q "%hyperVList%" >nul 2>&1

:: Step 3: Enable Feature
call :log progress "Enabling Hyper-V feature..."
Dism /online /enable-feature /featurename:Microsoft-Hyper-V -All /LimitAccess /Quiet
if errorlevel 1 (
    call :log error "!! Hyper-V feature failed to enable."
    goto :eof
)

:: Step 4: Final result
if "%installFail%"=="true" (
    call :log warning "Some packages failed, but Hyper-V feature was enabled. A restart may be required."
) else (
    call :log success "Hyper-V installation and enablement complete."
)

pause
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