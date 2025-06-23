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

:: ------ Configuration Section ------
:: Delimiters changed to pipes for reliable path parsing
set "SCRIPT_NAME=Windows Optimization Suite"
set "VERSION=3.1"
set "ERROR_COUNT=0"
set "BACKUP_ROOT=RegistryBackups"
set "TEMP_PATHS=%TEMP%|%windir%\Temp"
set "FIREWALL_BLOCKLIST=C:\Program Files\Adobe|C:\Program Files\Autodesk|C:\Program Files\Revit"
set "REBOOT_FLAG= Not Required"
set "HEALTH_STATUS= Optimized"
set "ADMIN_TIMEOUT=7"
set "ERR_ADMIN=100"
set "ERR_BACKUP=201"
set "PHASE_DELAY=2"
set "MAX_RETRIES=3"
set "PHASE_ERRORS=Phase1:0;Phase2:0;Phase3:0;Phase4:0"
set "SUPPORTED_WINVER=10.0"

::-------------------- ELEVATION CHECK AND SCRIPT OVERVIEW --------------------
:init
cls
call :log success "===================================================================================================================="
call :log info    "                                    WINDOWS DEBLOATER: PRIVACY, SECURITY, PERFORMANCE"
call :log success "===================================================================================================================="
echo.
call :log warning "  FEATURES"
echo.
call :log info    "  - Disables Tracking         | Blocks telemetry, diagnostics, and Copilot"
call :log info    "  - System Cleanup            | Deletes temp files (Temp, %%TEMP%%, Prefetch)"
call :log info    "  - Security Firewall         | Blocks Adobe, Autodesk, Revit via firewall rules"
call :log info    "  - Taskbar Tweaks            | Removes unneeded taskbar UI elements"
call :log info    "  - Registry Protection       | Stops tracking from re-enabling itself"
call :log info    "  - Backup and Recovery       | Backs up registry to %%ProgramData%%"
call :log info    "  - Admin Enforcement         | Ensures script runs as Administrator"
call :log info    "  - Error Handling            | Logs actions, catches failures, retries as needed"
echo.
call :log warning "  WARNINGS AND DISADVANTAGES"
echo.
call :log info    "  - Copilot, telemetry, and other features will be permanently disabled"
call :log info    "  - Adobe/Autodesk/Revit may not work correctly when blocked"
call :log info    "  - Taskbar changes may affect your Windows UI experience"
call :log info    "  - Registry backups are located in %%ProgramData%% if recovery is needed"
echo.
call :log success "===================================================================================================================="
call :log info    "  [0] Cancel"
call :log info    "  [1] Proceed"
call :log success "===================================================================================================================="

:: Get user input
echo.
set "choice="
set /p "choice=>> "
if /i "%choice%"=="0" (exit /b) else if "%choice%"=="1" (goto :proceed)
call :log error "Invalid choice. Please try again."
timeout /t 2 >nul & cls & goto :menu

:: Proceed with script execution
:proceed
cls
call :check_windows_version
net session >nul 2>&1 || goto :elevate
call :log success "Admin privileges verified"
goto :main

:: Elevation handling if not running as admin
:elevate
set "elevate_cmd=%~f0"
if "%PROCESSOR_ARCHITECTURE%"=="AMD64" set "elevate_cmd=%SystemRoot%\Sysnative\cmd.exe /c "%~f0""

set "attempt=0"
set "MAX_RETRIES=3"
:reelevate
set /a attempt+=1
call :log warning "[!] Admin required for system modifications"
call :log warning "[!] Attempt !attempt! of %MAX_RETRIES%"

:: Try to elevate using runas
runas /savecred /user:Administrator "!elevate_cmd!" || (
    if !attempt! lss %MAX_RETRIES% (
        timeout /t 2 >nul
        goto :reelevate
    )
    call :log critical "Persistent elevation failure"
    exit /b 1
)
exit /b

:: Secondary elevation fallback using PowerShell
if errorlevel 2 (
    if exist "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" (
        powershell -Command "Start-Process -Verb RunAs cmd -ArgumentList '/c "%~f0"'"
    ) else (
        runas /user:Administrator "%~f0"
        if errorlevel 1 (
            call :log error "Failed to elevate privileges."
            choice /c AR /t 10 /d R /m "Retry as admin? (A)bort/(R)etry"
            if errorlevel 2 goto :elevate
            exit /b 1
        )
    )
)
exit /b 1

:main
:: ------ Pre-Execution Setup ------
title %SCRIPT_NAME% v%VERSION% - Administrator
call :log info "Initializing %SCRIPT_NAME% v%VERSION%"
call :create_backup_dir || exit /b %ERR_BACKUP%
echo.  
:: Add blank line after backup creation

:: ------ Phase Execution ------
set "phases=Implementing_Bloat_Features Clean_System Security_Configuration Validate_System"
set "phase_count=4"
set "current_phase=0"

for %%P in (%phases%) do (
    set /a "current_phase+=1"
    call :log phase "Phase !current_phase! of %phase_count%: %%P"
    timeout /t %PHASE_DELAY% /nobreak >nul
    call :%%P
    if errorlevel 1 (
        call :log error "Phase %%P failed"
        set /a ERROR_COUNT+=1
        set "PHASE_ERRORS=!PHASE_ERRORS:Phase%current_phase%:0=Phase%current_phase%:1!"
    )
    echo.  
    :: Add blank line after each phase
    timeout /t %PHASE_DELAY% /nobreak >nul
)

:: ------ Post-Execution ------
echo.  
:: Add blank line before report
call :report
echo. 
call :log info "Press any key to exit..."
pause >nul
exit /b 0

:: ------ Core Functions ------
:check_windows_version
ver | findstr /i "%SUPPORTED_WINVER%" >nul || (
    call :log error "Unsupported OS. Requires Windows 10/11."
    exit /b 1
)
exit /b 0

:create_backup_dir
setlocal EnableDelayedExpansion

:: Get cleaned timestamp (remove symbols)
for /f "tokens=1-4 delims=/:. " %%a in ("%TIME%") do (
    set "clean_time=%%a%%b%%c"
)
for /f "tokens=1-3 delims=/" %%x in ("%DATE%") do (
    set "clean_date=%%x_%%y_%%z"
)

set "BACKUP_DIR=%ProgramData%\%BACKUP_ROOT%\%COMPUTERNAME%_!clean_date!_!clean_time!"
md "!BACKUP_DIR!" 2>nul || (
    call :log error "Backup directory creation failed"
    exit /b %ERR_BACKUP%
)

:: Export registry hives to backup folder
reg export HKLM "!BACKUP_DIR!\HKLM.reg" /y >nul 2>&1 || (
    call :log error "Failed to export HKLM"
)
reg export HKCU "!BACKUP_DIR!\HKCU.reg" /y >nul 2>&1 || (
    call :log error "Failed to export HKCU"
)

call :log success "Backup store created at: !BACKUP_DIR!"
endlocal & exit /b 0

::Start of Phase 1 Functions
:Implementing_Bloat_Features
call :log info "Starting privacy configuration..."
setlocal EnableDelayedExpansion
set "REG_FAIL=0"

:: Create registry hierarchy for new features
for %%K in (
    "Policies"
    "Policies\Microsoft"
    "Policies\Microsoft\Windows"
    "Policies\Microsoft\Windows\DataCollection"
    "Policies\Microsoft\Windows\Windows Copilot"
    "Policies\Microsoft\Windows\Widgets"
    "Policies\Microsoft\Windows\System"
    "Policies\Microsoft\Windows\Windows Feeds"
    "Policies\Microsoft\Windows\Windows Search"
) do (
    reg add "HKLM\SOFTWARE\%%~K" /f /reg:64 >nul 2>&1 || (
        call :log warn "Creating parent key: %%K"
        call :take_ownership "SOFTWARE\%%~K"
        reg add "HKLM\SOFTWARE\%%~K" /f /reg:64 >nul 2>&1 || (
            call :log error "Failed to create: %%K"
            set /a REG_FAIL+=1
        )
    )
)

:: Disable Windows Widgets
call :log info "Disabling Windows Widgets completely..."
set "KEY_WIDGETS=HKLM\SOFTWARE\Policies\Microsoft\Windows\Widgets"
set "VAL_WIDGETS=DisableWidgets"
call :safe_reg_add "!KEY_WIDGETS!" "!VAL_WIDGETS!" 1 || (
    call :take_ownership "!KEY_WIDGETS!"
    call :safe_reg_add "!KEY_WIDGETS!" "!VAL_WIDGETS!" 1 || set /a REG_FAIL+=1
)

:: Kill Widgets process if running
taskkill /f /im Widgets.exe >nul 2>&1

:: Optional: Leave Web Experience Pack installed to prevent Settings issues
call :log info "Leaving Windows Web Experience Pack installed (avoiding Settings break)..."
REM powershell -Command "Get-AppxPackage *WebExperience* | Remove-AppxPackage" >nul 2>&1

:: Disable Windows Recall
call :log info "Disabling Windows Recall (Activity Feed)..."
set "KEY_RECALL=HKLM\SOFTWARE\Policies\Microsoft\Windows\System"
set "VAL_RECALL=EnableActivityFeed"
call :safe_reg_add "!KEY_RECALL!" "!VAL_RECALL!" 0 || (
    call :take_ownership "!KEY_RECALL!"
    call :safe_reg_add "!KEY_RECALL!" "!VAL_RECALL!" 0 || set /a REG_FAIL+=1
)

:: Disable News and Weather
call :log info "Disabling News and Interests (Feeds)..."
set "KEY_FEEDS=HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds"
set "VAL_FEEDS=EnableFeeds"
call :safe_reg_add "!KEY_FEEDS!" "!VAL_FEEDS!" 0 || (
    call :take_ownership "!KEY_FEEDS!"
    call :safe_reg_add "!KEY_FEEDS!" "!VAL_FEEDS!" 0 || set /a REG_FAIL+=1
)

:: Enable Taskbar End Task option
call :log info "Enabling End Task option in Taskbar right-click..."
set "KEY_ENDTASK=HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
set "VAL_ENDTASK=TaskbarEndTask"
call :safe_reg_add "!KEY_ENDTASK!" "!VAL_ENDTASK!" 1 || (
    call :log warn "Failed to set End Task feature, retrying..."
    reg add "!KEY_ENDTASK!" /v "!VAL_ENDTASK!" /t REG_DWORD /d 1 /f >nul 2>&1 || set /a REG_FAIL+=1
)

:: Disable Web Search from Start Menu
call :log info "Disabling Web Search Suggestions in Start Menu..."
reg add "HKCU\Software\Policies\Microsoft\Windows\Explorer" /v "DisableSearchBoxSuggestions" /t REG_DWORD /d 1 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "BingSearchEnabled" /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "CortanaConsent" /t REG_DWORD /d 0 /f >nul

:: Disable Bing Web Search and Suggestions in Start Menu
set "KEY_BING=HKCU\Software\Microsoft\Windows\CurrentVersion\Search"
call :safe_reg_add "!KEY_BING!" "BingSearchEnabled" 0 || (
    call :take_ownership "!KEY_BING!"
    call :safe_reg_add "!KEY_BING!" "BingSearchEnabled" 0 || set /a REG_FAIL+=1
)
call :safe_reg_add "!KEY_BING!" "CortanaConsent" 0 || (
    call :safe_reg_add "!KEY_BING!" "CortanaConsent" 0 || set /a REG_FAIL+=1
)

:: Disable Search Box Suggestions
set "KEY_SEARCHPOL=HKCU\Software\Policies\Microsoft\Windows\Explorer"
call :safe_reg_add "!KEY_SEARCHPOL!" "DisableSearchBoxSuggestions" 1 || (
    call :take_ownership "!KEY_SEARCHPOL!"
    call :safe_reg_add "!KEY_SEARCHPOL!" "DisableSearchBoxSuggestions" 1 || set /a REG_FAIL+=1
)

:: Skip Outlook indexing policy to prevent breaking Windows Search integration
call :log info "Skipping Outlook indexing block to preserve system search..."
REM set "KEY_INDEXING=HKCU\Software\Policies\Microsoft\Windows\Search"
REM call :safe_reg_add "!KEY_INDEXING!" "PreventIndexingOutlook" 1

:: Disable Windows Copilot
call :log info "Disabling Windows Copilot..."
set "KEY_COPILOT=HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Copilot"
set "VAL_COPILOT=TurnOffWindowsCopilot"
call :safe_reg_add "!KEY_COPILOT!" "!VAL_COPILOT!" 1 || (
    call :take_ownership "!KEY_COPILOT!"
    call :safe_reg_add "!KEY_COPILOT!" "!VAL_COPILOT!" 1 || set /a REG_FAIL+=1
)

:: Disable Telemetry (safe setting for Pro/Home)
call :log info "Disabling Windows Telemetry (Basic level)..."
set "KEY_TELEMETRY=HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
set "VAL_TELEMETRY=AllowTelemetry"
call :safe_reg_add "!KEY_TELEMETRY!" "!VAL_TELEMETRY!" 1 || (
    call :take_ownership "!KEY_TELEMETRY!"
    call :safe_reg_add "!KEY_TELEMETRY!" "!VAL_TELEMETRY!" 1 || set /a REG_FAIL+=1
)

if %REG_FAIL% gtr 0 (
    call :log warn "Partial configuration applied"
    exit /b 1
) else (
    call :log success "Restarting Explorer to apply changes..."
    taskkill /f /im explorer.exe >nul && (
        timeout /t 1 >nul
        start explorer.exe
    )
)
endlocal
exit /b %REG_FAIL%

:: Enhanced registry handling functions
:take_ownership
setlocal EnableDelayedExpansion
set "key=%~1"

:: Determine the root of the key (HKLM or HKCU)
echo "!key!" | findstr /I /B "HKLM HKCU" >nul || (
    call :log warn "Skipping invalid registry path: !key!"
    exit /b 1
)

call :log info "Taking ownership of: !key!"

:: Convert HKLM or HKCU format for icacls
set "key_path=!key:HKLM\=!"
set "key_path=!key:HKCU\=HKEY_CURRENT_USER\!"

:: Assign ownership to Administrators and grant full control
reg add "!key!" /f >nul 2>&1
if errorlevel 1 (
    call :log error "Failed to create or access registry key: !key!"
    exit /b 1
)

:: Take ownership using regini alternative
takeown /f "!key_path!" /r /d Y >nul 2>&1
if errorlevel 1 (
    call :log error "Failed to take ownership of !key!"
    exit /b 1
)

icacls "!key_path!" /grant Administrators:F /t /c >nul 2>&1
if errorlevel 1 (
    call :log error "Failed to set permissions for !key!"
    exit /b 1
)

call :log success "Ownership granted: !key!"
exit /b 0


:safe_reg_add
setlocal EnableDelayedExpansion
set "key=%~1"
set "value=%~2"
set "data=%~3"
set "retries=0"

:reg_retry
reg add "!key!" /f /reg:64 >nul 2>&1 || (
    call :take_ownership "!key!"
    reg add "!key!" /f /reg:64 >nul 2>&1 || (
        call :log error "Key creation failed: !key!"
        exit /b 1
    )
)

reg add "!key!" /v "!value!" /t REG_DWORD /d !data! /f /reg:64 >nul 2>&1
if errorlevel 1 (
    set /a retries+=1
    if !retries! leq %MAX_RETRIES% (
        call :take_ownership "!key!"
        timeout /t 1 >nul
        goto :reg_retry
    )
    call :log error "Persistent failure: !key!\!value!"
    exit /b 1
)
exit /b 0
::End of Phase 1 Functions

::Start of Phase 2 Functions Processes
:Clean_System
call :log info "Starting deep clean operation..."
setlocal enabledelayedexpansion
set "CLEAN_FAIL=0"

:: Ensure admin privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    call :log error "Administrator privileges required. Exiting..."
    exit /b 1
)

:: Cleaning Temporary Files
for %%P in ("%TEMP%", "%SystemRoot%\Temp") do (
    if exist "%%~P" (
        call :log info "Cleaning %%~P..."
        del /f /s /q "%%~P\*.*" 2>nul
        rd /s /q "%%~P" 2>nul || (
            call :log warning "Failed to remove %%~P (some files may be in use)"
        )
    )
)

:: Cleaning Prefetch
if exist "C:\Windows\Prefetch" (
    call :log info "Cleaning Prefetch..."
    del /s /q C:\Windows\Prefetch\* 2>nul || (
        call :log warning "Failed to delete some Prefetch files"
    )
)

:: Disable diagnostic services
call :log info "Disabling diagnostic services..."
for %%S in (DiagTrack dmwappushservice) do (
    net stop %%S >nul 2>&1
    sc config %%S start= disabled >nul 2>&1 || (
        call :log error "Failed to disable %%S"
        set /a CLEAN_FAIL+=1
    )
)

:: Exit Handling
if %CLEAN_FAIL% gtr 0 (
    call :log error "System cleanup completed with errors."
    exit /b 1
) else (
    call :log success "System cleanup completed successfully."
)
exit /b 0
:: End of Phase 2 Functions Processes

::Start of Phase 3 Functions Processes
:Security_Configuration
call :log info "Cleaning...."
call :log info "C:\ProgramData\Microsoft\Windows Defender\Scans\History\Service"
setlocal enabledelayedexpansion
set "SECURITY_FAIL=0"

call :log warn "Creates persistent firewall rules..."
for /f "tokens=* delims=|" %%P in ("%FIREWALL_BLOCKLIST%") do (
    if exist "%%~P\" (
        call :log info "Processing %%~P..."
        for /r "%%~P" %%F in (*.exe) do (
            set "exe_path=%%~fF"
            set "rule_name=Block_%%~nF_%%~pF"
            set "rule_name=!rule_name:\=_!"
            set "rule_name=!rule_name: =_!"
            if "!rule_name!" geq "123" set "rule_name=!rule_name:~0,120!" 
            netsh advfirewall firewall show rule name="!rule_name!" >nul 2>&1 || (
                netsh advfirewall firewall add rule name="!rule_name!" dir=out program="!exe_path!" action=block 2>nul || (
                    call :log error "Failed to block !exe_path!"
                    set /a SECURITY_FAIL+=1
                )
            )
        )
    )
)

call :log info "Checking BitLocker status..."
setlocal enabledelayedexpansion
set "bl_status=0"
set "ENCRYPTED_DRIVES="

REM Get all fixed drives and check BitLocker status natively
for /f "skip=1" %%D in ('wmic logicaldisk where "drivetype=3" get deviceid 2^>nul') do (
    set "drive=%%D"
    if defined drive (
        manage-bde -status !drive! | find /i "Protection Status: On" >nul && (
            set "bl_status=1"
            set "ENCRYPTED_DRIVES=!ENCRYPTED_DRIVES! !drive!"
        )
    )
)

if !bl_status! equ 1 (
    echo.
    call :log warn "WARNING: The following drives have BitLocker enabled:!ENCRYPTED_DRIVES!"
    call :log warn "Disabling BitLocker will decrypt these drives!"
    
    choice /c YN /t 20 /d N /m "Are you ABSOLUTELY sure? (Y/N)"
    if errorlevel 2 (
        call :log info "Operation cancelled by user"
        exit /b 0
    )
    
    for %%D in (!ENCRYPTED_DRIVES!) do (
        call :log warn "Starting BitLocker disablement on %%D..."
        manage-bde -off %%D >nul 2>&1
        
        if !errorlevel! equ 0 (
            call :log success "Successfully disabled BitLocker on %%D"
            set "REBOOT_FLAG= Required"
            
            REM Check if decryption is complete
            manage-bde -status %%D | find "Percentage Encrypted: 0%%" >nul
            if !errorlevel! neq 0 (
                call :log warn "Drive %%D is still decrypting - this may take considerable time"
            )
        ) else (
            call :log error "Failed to disable BitLocker on %%D"
            set /a SECURITY_FAIL+=1
        )
    )
) else (
    call :log success "No BitLocker-protected drives found"
)
endlocal

if %SECURITY_FAIL% gtr 0 (
    exit /b 1
) else (
    call :log success "Security hardening applied"
)
exit /b 0
::End of Phase 3 Functions Processes

:: ===== Phase 4: System Validation =====
:Validate_System
echo.
call :log progress "Running essential system validation..."
echo.
goto :Essential_Validation

:: ===================== Essential Validation =====================
:Essential_Validation
call :log info "Running essential system validation..."

setlocal EnableDelayedExpansion
set "ESSENTIAL_ERRORS=0"

:: ----------- Validate Windows Update Service (wuauserv) -----------
call :log info "Checking Windows Update service status..."

sc query wuauserv >nul 2>&1
if !errorlevel! neq 0 (
    call :log error "Windows Update service does not exist on this system."
    set /a ESSENTIAL_ERRORS+=1
) else (
    
 set "WU_STATE=")

for /f "tokens=3" %%A in ('sc query wuauserv ^| findstr /i "STATE" 2^>nul') do (
    set "WU_STATE=%%A"
)

if defined WU_STATE (
    if "!WU_STATE!"=="RUNNING" (
        call :log success "Windows Update service is already running."
    ) else (
        call :log warn "Windows Update service is not running. Attempting repair..."

        sc qc wuauserv | findstr /i "DISABLED" >nul
        if !errorlevel! equ 0 (
            sc config wuauserv start= demand >nul 2>&1
            if !errorlevel! equ 0 (
                call :log info "Startup type set to Manual."
            ) else (
                call :log error "Failed to set Windows Update service startup type."
                set /a ESSENTIAL_ERRORS+=1
            )
        )

        net start wuauserv >nul 2>&1
        if !errorlevel! equ 0 (
            call :log error "Failed to start Windows Update service."
            set /a ESSENTIAL_ERRORS+=1
        ) else (
            call :log success "Windows Update service started successfully."
        )
    )
)

:: ----------- Validate Critical Registry Policies -----------
call :log info "Checking critical registry policy keys..."

reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies" >nul 2>&1
if !errorlevel! neq 0 (
    call :log warn "Critical registry policies missing. Attempting to restore..."
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies" /f >nul 2>&1
    if !errorlevel! neq 0 (
        call :log error "Failed to restore registry policies."
        set /a ESSENTIAL_ERRORS+=1
    ) else (
        call :log success "Registry policies restored successfully."
    )
) else (
    call :log success "Critical registry policies verified."
)

:: ----------- Final Summary Output -----------
if !ESSENTIAL_ERRORS! gtr 0 (
    call :log warn "Essential validation found !ESSENTIAL_ERRORS! issue(s)."
) else (
    call :log success "Essential validation complete - No critical issues detected."
)

:: Capture value and end scope cleanly
set "errorCount=!ESSENTIAL_ERRORS!"
endlocal
exit /b %errorCount%


:report
call :log success "--------------------------------------------------"
call :log info "[%SCRIPT_NAME% v%VERSION% - Diagnostic Report]"
call :log success "--------------------------------------------------"
call :log success "Backup Directory: %BACKUP_DIR% "
if not "%PHASE_ERRORS%"=="Phase1:0;Phase2:0;Phase3:0;Phase4:0"(
    call :log error "Failed Phases:   %PHASE_ERRORS% "
)
call :log warning "Total Issues:    %ERROR_COUNT% "
call :log info "System Health:   %HEALTH_STATUS% "
call :log warning "Reboot Required: %REBOOT_FLAG% "
call :log success "--------------------------------------------------
if exist "%BACKUP_DIR%\*.html"(
    call :log success "Additional Reports: "
    dir /b "%BACKUP_DIR%\*.html"
)
call :log success "-------------------------------------------------- "
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

:: Restores (imports) the existing registry backup files if present.  
:: This process will overwrite the current registry settings with the saved backup,  
:: effectively reverting any recent changes to the state when the backup was created.  
::  
:: If the backup files are missing or corrupted, the restoration process may fail,  
:: potentially leaving the system in an unstable state.  
:: It is recommended to verify the integrity of the backup before proceeding.  
::  
:: WARNING: This action cannot be undone unless a newer backup is available.  
:: Ensure you have a working backup before running this operation.  
:emergency_restore
call :log warn "Initiating emergency registry restore..."
for %%F in ("%BACKUP_DIR%\*.reg") do (
    reg import "%%F" 2>nul && (
        call :log success "Restored %%F"
    ) || (
        call :log error "Failed to restore %%F"
    )
)
exit /b 0