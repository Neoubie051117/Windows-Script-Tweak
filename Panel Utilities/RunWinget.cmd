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

::-------------------- INITIALIZATION --------------------
set "WAIT_TIMEOUT=5"
cls
call :log success "================================================================================"
call :log success "                                 WINDOWS PACKAGE MANAGER TOOL (WINGET)"
call :log success "================================================================================"
echo.

::-------------------- VERIFY WINGET INSTALLATION --------------------
where winget >nul 2>&1
if errorlevel 1 (
    call :log error "Winget is not installed. Requires Windows 10 1709+ or Windows 11."
    timeout /t %WAIT_TIMEOUT% >nul
    exit /b 1
)
call :log info "Winget detected and ready."
echo.

::-------------------- DISPLAY WINGET VERSION --------------------
call :log progress "Checking Winget version..."
winget --version >nul 2>&1
if errorlevel 1 (
    call :log error "Winget failed to return version. Skipping upgrades."
    timeout /t %WAIT_TIMEOUT% >nul
    exit /b 1
)
echo.

::-------------------- EXCLUSION KEYWORDS (DO NOT EDIT STRUCTURE) --------------------
:: Backend readable format using commas, line-breaks for maintainability

set "RAW_SKIP_LIST=edge,roblox,autodesk,autocad,revit,civil,identity,batch,save,app,featured,accelerator,openstudio,"
set "RAW_SKIP_LIST=!RAW_SKIP_LIST!sketchup,wps,adobe,photoshop,illustrator,premiere,lightroom,after,effects,"
set "RAW_SKIP_LIST=!RAW_SKIP_LIST!iobit,booster"

:: Parse comma-separated to space-separated list
set "SKIP_WORDS=%RAW_SKIP_LIST:,= %"

::-------------------- UPGRADE ALL PACKAGES --------------------
call :log progress "Retrieving upgradable packages..."
echo.

set "foundUpgrades=false"

for /f "tokens=*" %%L in ('winget upgrade --accept-source-agreements --include-unknown 2^>nul') do (
    set "packageLine=%%L"
    set "skip=false"

    rem Skip non-valid output lines
    echo(!packageLine! | findstr /r /c:"^[a-zA-Z0-9]" >nul || (
        rem call :log info "Skipping non-package line: !packageLine!"
        goto :continueLoop
    )

 rem Check if package line contains any exclusion word
for %%K in (!SKIP_WORDS!) do (
    echo !packageLine! | findstr /i "%%~K" >nul && set "skip=true"
)

if "!skip!"=="true" (
        call :log warning "Skipping: !packageLine!"
    ) else (
        set "foundUpgrades=true"
        call :log progress "Upgrading: !packageLine!"
winget upgrade "!packageLine!" --accept-package-agreements --include-unknown --force
if errorlevel 1618 (
    call :log critical "Install conflict: !packageLine! (restart needed or another installer running)."
) else if errorlevel 1 (
    call :log warning "Upgrade warning for: !packageLine!"
)

    )

)
:continueLoop
)


if "%foundUpgrades%"=="false" (
    call :log info "No packages to upgrade or all were skipped."
)
echo.

::-------------------- UPGRADE COMPLETE --------------------
call :log success "Winget upgrade completed. Manual review may be needed for skipped packages."
call :log info "Press any key to exit..."
pause >nul
goto :eof

::-------------------- LOG FUNCTION WITH ANSI COLOR OUTPUT --------------------
:log
setlocal enabledelayedexpansion
set "type=%~1"
set "msg=%~2"
set "ESC=["

set "color="
if /i "%type%"=="error" set "color=91"
if /i "%type%"=="warning" set "color=93"
if /i "%type%"=="info" set "color=96"
if /i "%type%"=="progress" set "color=92"
if /i "%type%"=="critical" set "color=91;107"
if /i "%type%"=="" set "color=97"

<nul set /p="!ESC!!color!m%msg%!ESC!0m"
echo.
endlocal
goto :eof

