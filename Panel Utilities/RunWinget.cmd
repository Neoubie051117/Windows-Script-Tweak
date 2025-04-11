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


:: Configuration ----------------------------
set "COLOR_INFO=E"
set "COLOR_ERROR=C"
set "COLOR_SUCCESS=A"
set "COLOR_DEFAULT=07"
set "WAIT_TIMEOUT=15"
:: ------------------------------------------

:: Initialization ---------------------------
set "ADMIN_CHECK=0"
set "WINGET_CHECK=0"
:: -------------------------------------------

:: Verify Winget Installation ---------------
where winget >nul 2>&1
if %errorlevel% neq 0 (
    call :log error "Winget not found. Requires Windows 10 1709+ or Windows 11"
    timeout /t %WAIT_TIMEOUT% >nul
    exit /b 1
)
:: -------------------------------------------

:: Main Execution ---------------------------
:RunWinGet
cls
call :log info "Windows Package Manager Initialized"
winget --version

:: Package Upgrade --------------------------
:upgrade
call :log progress "Processing system upgrades..."
winget upgrade --all --include-unknown --accept-package-agreements --force
if errorlevel 1618 (
    call :log critical "Critical security verification failed: Potential corrupted download or server-side issue."
    exit /b 1
)
if errorlevel 1 (
    call :log warning "Partial updates completed with errors. Check logs."
    exit /b 1
)
:: -------------------------------------------

:: Success Finalization ---------------------
call :log success "System updated without critical errors. Some packages may need manual review."
timeout /t %WAIT_TIMEOUT% >nul
exit /b 0
:: -------------------------------------------

:: Logging Function -------------------------
:log
setlocal
set "type=%~1"
set "msg=%~2"
set "color="

:: Color mapping based on message type
if "%type%"=="error" (
    set "color=%COLOR_ERROR%"
) else if "%type%"=="warning" (
    set "color=6"
) else if "%type%"=="success" (
    set "color=%COLOR_SUCCESS%"
) else if "%type%"=="info" (
    set "color=%COLOR_INFO%"
) else if "%type%"=="progress" (
    set "color=e"
) else if "%type%"=="critical" (
    set "color=4F"
)


:: Apply color and output message
color %color%
echo [%type%] %msg%
color %COLOR_DEFAULT%
endlocal
exit /b 0
