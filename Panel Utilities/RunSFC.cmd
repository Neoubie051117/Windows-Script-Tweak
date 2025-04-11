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

:: Log function
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

:: PowerShell-based color output
powershell -Command "[Console]::ForegroundColor='%color%'; Write-Host '[%type%] %msg%'; [Console]::ResetColor()" 2>nul || (
    :: Fallback to plain text if PowerShell unavailable
    echo [%type%] %msg%
)

endlocal
exit /b 0