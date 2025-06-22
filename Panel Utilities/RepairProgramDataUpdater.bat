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

:: Check if the task exists
schtasks /query /TN "\Microsoft\Windows\Application Experience\ProgramDataUpdater" >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo Task not found. Attempting to recreate it...

    :: Recreate the task correctly
    schtasks /create /TN "\Microsoft\Windows\Application Experience\ProgramDataUpdater" ^
    /SC ONDEMAND /RU SYSTEM /RL HIGHEST ^
    /TR "rundll32.exe aeinv.dll,UpdateSoftwareInventory" /F >nul 2>&1

    IF %ERRORLEVEL% NEQ 0 (
        echo ERROR: Failed to create the task. Ensure you have administrator privileges.
        exit /b 1
    ) ELSE (
        echo Task recreated successfully.
    )
) ELSE (
    echo Task already exists.
)

:: Check if the task is running before starting
schtasks /query /TN "\Microsoft\Windows\Application Experience\ProgramDataUpdater" /FO LIST | find "Running" >nul
IF %ERRORLEVEL% EQU 0 (
    echo Task is already running.
) ELSE (
    echo Starting the task...
    schtasks /run /TN "\Microsoft\Windows\Application Experience\ProgramDataUpdater" >nul 2>&1

    IF %ERRORLEVEL% NEQ 0 (
        echo ERROR: Failed to start the task.
        exit /b 1
    ) ELSE (
        echo Task executed successfully.
    )
)

pause
