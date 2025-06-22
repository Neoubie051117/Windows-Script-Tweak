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


:: Run System File Checker
:RunSFC
cls
call :log progress "System File Checker is running..."
timeout /t 2 >nul
call :log progress "[1/5] Scanning for integrity violations..."
sfc /scannow

echo.
call :log progress "[2/5] Processing possible interruptions..."
call :log info "Attempting to start Background Intelligent Transfer Service" && net start bits && timeout /t 5 >nul
call :log info "Attempting to start Data Sharing Service" && net start dosvc && timeout /t 5 >nul
call :log info "Attempting to start Update Orchestrator Service" && net start usosvc && timeout /t 5 >nul
call :log info "Attempting to start Windows Modules Installer Service" && net start trustedinstaller && timeout /t 5 >nul
call :log info "Attempting to start Windows Update Service" && net start wuauserv && timeout /t 5 >nul

echo.
call :log progress "[3/5] Running Deployment Image Servicing and Management"
dism /online /cleanup-image /restorehealth && timeout /t 5 >nul

echo.
call :log progress "[4/5] Running Check Disk utility"
chkdsk && timeout /t 5 >nul

echo.
call :log progress "[5/5] Scanning once again"
sfc /scannow && call :log success "System scan completed successfully." && timeout /t 5 >nul

echo.
call :log warning "False positive error message:"
call :log warning "Windows Resource Protection found corrupt files but was unable to fix some of them"
call :log info "This message occurs due to missing Windows features, updates, or third-party software."
timeout /t 2 >nul
call :log info "If using a genuine copy of Windows, you can ignore this message."
echo.
call :log warning "Note: Backup your data using cloud storage or external storage devices to prevent data loss."
call :log success "System File Checker finished scanning the system."
timeout /t 5 >nul
pause
cls
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