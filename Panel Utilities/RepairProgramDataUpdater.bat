@echo off
:: Ensure the script runs as Administrator
NET SESSION >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo This script requires Administrator privileges. Please run as Administrator.
    exit /b 1
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
