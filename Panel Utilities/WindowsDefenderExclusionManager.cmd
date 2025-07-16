@echo off
setlocal enabledelayedexpansion

::-------------------- CHECK FOR ADMIN PRIVILEGES --------------------
net session >nul 2>&1
if errorlevel 1 (
    call :log warning "Windows Security Antivirus Exclusion Manager must be run as administrator."
    call :log error "   - Administrator rights are required to manage exclusions"
    echo.
    call :log warning "Please right-click the script and select 'Run as administrator'"
    timeout /t 30 >nul
    exit /b
)

::-------------------- CONFIGURATION --------------------
set "PS_EXE=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
color 07

:: Check Windows Defender service status
call :CheckDefenderService
if errorlevel 1 exit /b 1

:MainMenu
cls
echo.
call :log success "===================================================================================================================="
call :log info "                                  WINDOWS SECURITY ANTIVIRUS EXCLUSION MANAGER"
call :log success "===================================================================================================================="
echo.
call :log info " [1] Add Antivirus Exclusion Path"
call :log info " [2] Remove Antivirus Exclusion Path"
call :log info " [3] List Current Antivirus Exclusions"
echo.
call :log warning " [0] Exit"
echo.
set "choice="
set /p "choice= >> " 

if "!choice!"=="1" goto AddExclusion
if "!choice!"=="2" goto RemoveExclusion
if "!choice!"=="3" goto ListExclusions
if "!choice!"=="0" exit /b

call :log error "Invalid option. Please choose 1, 2, 3, or 0"
timeout /t 2 >nul
goto MainMenu

:AddExclusion
call :GetPath "Enter path to exclude from antivirus scanning"
if not defined input_path goto MainMenu

:: Check if already excluded
call :IsExcluded "!input_path!"
if not errorlevel 1 (
    call :log warning "Path is already excluded: !input_path!"
    timeout /t 3 >nul
    goto AddExclusion
)

:: Add to exclusions with multi-method retry
call :AddExclusionWithRetry "!input_path!"
if errorlevel 1 (
    call :log critical "Failed to add exclusion after retries"
    call :log debug "Last error code: !errorlevel!"
) else (
    call :log success "Successfully excluded from antivirus scanning: !input_path!"
)
timeout /t 3 >nul
goto MainMenu

:RemoveExclusion
call :GetPath "Enter path to remove from antivirus exclusions"
if not defined input_path goto MainMenu

:: Check if excluded
call :IsExcluded "!input_path!"
if errorlevel 1 (
    call :log warning "Path is not currently excluded: !input_path!"
    timeout /t 3 >nul
    goto RemoveExclusion
)

:: Remove exclusion with multi-method retry
call :RemoveExclusionWithRetry "!input_path!"
if errorlevel 1 (
    call :log critical "Failed to remove exclusion after retries"
    call :log debug "Last error code: !errorlevel!"
) else (
    call :log success "Successfully removed antivirus exclusion for: !input_path!"
)
timeout /t 3 >nul
goto MainMenu

:ListExclusions
call :log info "Current Antivirus Exclusions:"
echo.
%PS_EXE% -NoProfile -Command "Get-MpPreference | Select-Object -ExpandProperty ExclusionPath" | more
echo.
call :log info "End of exclusion list"
timeout /t 7 >nul
goto MainMenu

:GetPath
set "input_path="
echo.
echo %~1:
echo.
set "raw_path="
set /p "raw_path=   Path: "
if "!raw_path!"=="" (
    call :log warning "No input provided. Returning to main menu..."
    timeout /t 2 >nul
    goto :eof
)

:: Robust path normalization
set "clean_path=!raw_path!"
:: Remove surrounding quotes
if "!clean_path:~0,1!"=="^"" if "!clean_path:~-1!"=="^"" set "clean_path=!clean_path:~1,-1!"
:: Remove leading/trailing spaces
for /f "tokens=*" %%a in ("!clean_path!") do set "clean_path=%%a"
:trim_trailing
if "!clean_path:~-1!"==" " set "clean_path=!clean_path:~0,-1!" & goto trim_trailing
:: Convert forward to backslashes
set "clean_path=!clean_path:/=\!"
:: Handle trailing backslashes
if defined clean_path (
    if "!clean_path:~-1!"=="\" (
        if not "!clean_path:~-2!"==":\" set "clean_path=!clean_path:~0,-1!"
    )
)

:: Validate path format
set "valid_path=0"
if defined clean_path (
    set "first_two=!clean_path:~0,2!"
    set "first_three=!clean_path:~0,3!"

    if "!first_two!"=="\\" (
        set "valid_path=1"
    ) else if not "!first_three!"=="" (
        if "!first_three:~1,1!"==":" (
            if "!first_three:~2,1!"=="\" (
                set "valid_path=1"
            )
        )
    )
)

if "!valid_path!"=="0" (
    call :log error "Invalid path format: !raw_path!"
    call :log debug "Cleaned path: '!clean_path!'"
    call :log info "Valid formats:"
    call :log info "   - Local path: C:\Folder\File.ext"
    call :log info "   - Network path: \\Server\Share\Folder"
    timeout /t 5 >nul
    goto :eof
)

set "input_path=!clean_path!"
goto :eof

:AddExclusionWithRetry
set "path_to_add=%~1"
set "retry_count=0"

:add_retry
set /a retry_count+=1
call :log info "Attempting to add exclusion (!retry_count!/3)..."
call :log debug "Method: PowerShell"

%PS_EXE% -Command "Add-MpPreference -ExclusionPath '!path_to_add!'" >nul 2>&1
if not errorlevel 1 (
    call :VerifyExclusion "!path_to_add!" && exit /b 0
) else (
    call :log debug "PowerShell failed (Error: !errorlevel!)"
)

if !retry_count! geq 3 (
    call :log error "Access denied. Possible causes:"
    call :log error "1. Group Policy restrictions"
    call :log error "2. Third-party security software blocking changes"
    call :log info "Troubleshooting:"
    call :log info "   - Check Windows Security settings"
    call :log info "   - Verify exclusions are allowed in Group Policy"
    exit /b 1
)

call :log warning "Retrying in 2 seconds..."
timeout /t 2 >nul
goto :add_retry

:RemoveExclusionWithRetry
set "path_to_remove=%~1"
set "retry_count=0"

:remove_retry
set /a retry_count+=1
call :log info "Attempting to remove exclusion (!retry_count!/3)..."
call :log debug "Method: PowerShell"

%PS_EXE% -Command "Remove-MpPreference -ExclusionPath '!path_to_remove!'" >nul 2>&1
if not errorlevel 1 (
    call :VerifyRemoval "!path_to_remove!" && exit /b 0
) else (
    call :log debug "PowerShell failed (Error: !errorlevel!)"
)

if !retry_count! geq 3 (
    call :log error "Access denied. Possible causes:"
    call :log error "1. Group Policy restrictions"
    call :log error "2. Third-party security software blocking changes"
    call :log info "Troubleshooting:"
    call :log info "   - Check Windows Security settings"
    call :log info "   - Verify exclusions are allowed in Group Policy"
    exit /b 1
)

call :log warning "Retrying in 2 seconds..."
timeout /t 2 >nul
goto :remove_retry

:CheckDefenderService
%PS_EXE% -Command "Get-Service -Name WinDefend | Where-Object { $_.Status -eq 'Running' }" >nul 2>&1
if not errorlevel 1 exit /b 0

call :log critical "Windows Defender service is not running!"
call :log error "Antivirus exclusions cannot be managed while Defender is disabled"
call :log info "Possible solutions:"
call :log info "1. Enable Windows Defender service"
    call :log info "   - Run: sc config WinDefend start=auto & net start WinDefend"
call :log info "2. Check Group Policy settings"
timeout /t 10 >nul
exit /b 1

:IsExcluded
%PS_EXE% -Command "& {if ((Get-MpPreference).ExclusionPath -contains '%~1') { exit 0 } else { exit 1 }}" >nul 2>&1
exit /b %errorlevel%

:VerifyExclusion
call :IsExcluded "%~1"
exit /b %errorlevel%

:VerifyRemoval
call :IsExcluded "%~1"
if errorlevel 1 exit /b 0
exit /b 1

::-------------------- LOG FUNCTION --------------------
:log
setlocal
set "type=%~1"
set "msg=%~2"

set "ESC=["

set "color="
if /i "%type%"=="error" set "color=91"          :: Bright Red
if /i "%type%"=="warning" set "color=93"        :: Bright Yellow
if /i "%type%"=="info" set "color=96"           :: Bright Cyan
if /i "%type%"=="success" set "color=92"        :: Bright Green
if /i "%type%"=="critical" set "color=91;107"   :: Red text on White background
if /i "%type%"=="debug" set "color=90"          :: Dark Gray

if not "%color%"=="" (
    <nul set /p="!ESC!!color!m"
)

echo %msg%

if not "%color%"=="" (
    <nul set /p="!ESC!0m"
)
endlocal
goto :eof