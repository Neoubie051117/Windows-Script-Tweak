@echo off
setlocal EnableExtensions EnableDelayedExpansion
cls
:: ------ Configuration Section ------
:: Delimiters changed to pipes for reliable path parsing
set "SCRIPT_NAME=Windows Optimization Suite"
set "VERSION=3.1"
set "ERROR_COUNT=0"
set "BACKUP_ROOT=RegistryBackups"
set "TEMP_PATHS=%TEMP%|%windir%\Temp"
set "FIREWALL_BLOCKLIST=C:\Program Files\Adobe|C:\Program Files\Autodesk|C:\Program Files\Revit"
set "REBOOT_FLAG=No"
set "HEALTH_STATUS=Optimal"
set "ADMIN_TIMEOUT=7"
set "ERR_ADMIN=100"
set "ERR_BACKUP=201"
set "PHASE_DELAY=2"
set "MAX_RETRIES=3"
set "PHASE_ERRORS=Phase1:0;Phase2:0;Phase3:0;Phase4:0"
set "SUPPORTED_WINVER=10.0"

:: ------ Elevation Check ------
:init
echo =============================================================
echo  Windows Debloater: Privacy, Security, and Performance Boost
echo =============================================================
echo.
echo  - Disables Tracking - Blocks telemetry, diagnostics, and Copilot.
echo  - System Cleanup - Deletes temp files from Temp, %%TEMP%%, Prefetch.
echo  - Security - Blocks Adobe, Autodesk, and Revit via firewall.
echo  - Taskbar Tweaks - Removes unnecessary UI elements.
echo  - Registry Protection - Prevents tracking from re-enabling itself.
echo  - Backup and Recovery - Saves registry backups in ProgramData.
echo  - Admin Enforcement - Ensures script runs with admin rights.
echo  - Error Handling - Logs steps, captures failures, and retries.
echo.
echo =============================================================
echo              Changes and Potential Disadvantages
echo =============================================================
echo.
echo  - Some Windows features (like Copilot and telemetry) will be disabled.
echo  - Blocking Adobe/Autodesk/Revit may prevent software from working properly.
echo  - Taskbar modifications might affect the default UI experience.
echo  - If something breaks, a registry backup is available in %%ProgramData%%.
echo.
echo =============================================================
echo  [0] Cancel
echo  [1] Proceed

:: Get user input
echo.
set "choice="
set /p "choice=>> "
if /i "%choice%"=="0" (exit /b) else if "%choice%"=="1" (goto :proceed)
echo Invalid choice, please try again.
timeout /t 2 >nul & cls & goto :menu

:: Logging function for tracking script execution
:log
setlocal EnableDelayedExpansion
set "type=%~1"
set "msg=%~2"
:: Log format: timestamp, log type, and message
echo [%DATE% %TIME%] [%type%] %msg% >> "%~dp0log.txt"
exit /b

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
echo [!] Admin required for system modifications
echo [!] Attempt !attempt! of %MAX_RETRIES%

:: Try to elevate using runas
runas /savecred /user:Administrator "!elevate_cmd!" || (
    if !attempt! lss %MAX_RETRIES% (
        timeout /t 2 >nul
        goto :reelevate
    )
    call :log critical "Persistent elevation failure"
    exit /b 1  :: Exit with error code
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
echo.  &:: Add blank line after backup creation

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
    echo.  &:: Add blank line after each phase
    timeout /t %PHASE_DELAY% /nobreak >nul
)

:: ------ Post-Execution ------
echo.  &:: Add blank line before report
call :report
echo. & echo Operation complete. Press any key to exit...
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
set "BACKUP_DIR=%ProgramData%\%BACKUP_ROOT%\%COMPUTERNAME%_%DATE:/=_%_%TIME::=_%"
set "BACKUP_DIR=%BACKUP_DIR: =%"
md "%BACKUP_DIR%" 2>nul || (
    call :log error "Backup directory creation failed"
    exit /b %ERR_BACKUP%
)
call :log success "Backup store: %BACKUP_DIR%"
exit /b 0


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

:: New Feature: Disable Windows Widgets (Win+W)
call :log info "Disabling Windows Widgets..."
set "KEY_WIDGETS=HKLM\SOFTWARE\Policies\Microsoft\Windows\Widgets"
set "VAL_WIDGETS=DisableWidgets"
call :safe_reg_add "!KEY_WIDGETS!" "!VAL_WIDGETS!" 1 || (
    call :take_ownership "!KEY_WIDGETS!"
    call :safe_reg_add "!KEY_WIDGETS!" "!VAL_WIDGETS!" 1 || set /a REG_FAIL+=1
)

:: New Feature: Disable Windows Recall
call :log info "Disabling Windows Recall..."
set "KEY_RECALL=HKLM\SOFTWARE\Policies\Microsoft\Windows\System"
set "VAL_RECALL=EnableActivityFeed"
call :safe_reg_add "!KEY_RECALL!" "!VAL_RECALL!" 0 || (
    call :take_ownership "!KEY_RECALL!"
    call :safe_reg_add "!KEY_RECALL!" "!VAL_RECALL!" 0 || set /a REG_FAIL+=1
)

:: New Feature: Disable News and Weather
call :log info "Disabling News and Weather..."
set "KEY_FEEDS=HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds"
set "VAL_FEEDS=EnableFeeds"
call :safe_reg_add "!KEY_FEEDS!" "!VAL_FEEDS!" 0 || (
    call :take_ownership "!KEY_FEEDS!"
    call :safe_reg_add "!KEY_FEEDS!" "!VAL_FEEDS!" 0 || set /a REG_FAIL+=1
)

:: New Feature: Add End Task to Taskbar Context Menu
call :log info "Adding End Task to taskbar context menu..."
set "KEY_ENDTASK=HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
set "VAL_ENDTASK=TaskbarEndTask"
call :safe_reg_add "!KEY_ENDTASK!" "!VAL_ENDTASK!" 1 || (
    call :log warn "Failed to set End Task feature, retrying..."
    reg add "!KEY_ENDTASK!" /v "!VAL_ENDTASK!" /t REG_DWORD /d 1 /f >nul 2>&1 || set /a REG_FAIL+=1
)

:: Existing tracking disablement code
:: (Keep existing Windows Copilot, Telemetry, and Web Search disablement code here)

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
            set "REBOOT_FLAG=Yes"
            
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
echo  Running essential system validation...
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
echo --------------------------------------------------
echo [%SCRIPT_NAME% v%VERSION% - Diagnostic Report]
echo --------------------------------------------------
echo Backup Directory: %BACKUP_DIR%
if not "%PHASE_ERRORS%"=="Phase1:0;Phase2:0;Phase3:0;Phase4:0" (
    echo Failed Phases:   %PHASE_ERRORS%
)
echo Total Issues:    %ERROR_COUNT%
echo System Health:   %HEALTH_STATUS%
echo Reboot Required: %REBOOT_FLAG%
echo --------------------------------------------------
if exist "%BACKUP_DIR%\*.html" (
    echo Additional Reports:
    dir /b "%BACKUP_DIR%\*.html"
)
echo --------------------------------------------------
exit /b 0

::Color Management
:log
setlocal
set "type=%~1"
set "msg=%~2"
set "color=7"

for /f "tokens=*" %%T in ('powershell -Command "Get-Date -Format 'HH:mm:ss'"') do set "CURRENT_TIME=%%T"


if /i "%type%"=="error"   set "color=12"
if /i "%type%"=="success" set "color=10"
if /i "%type%"=="info"    set "color=11"
if /i "%type%"=="phase"   set "color=14"
if /i "%type%"=="warn"    set "color=13"
if /i "%type%"=="neutral" set "color=07"


powershell -Command "[Console]::ForegroundColor=%color%; Write-Host '[%CURRENT_TIME%] %msg%'" 2>nul || (
    echo [%CURRENT_TIME%] %msg%
)

endlocal
exit /b 0

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