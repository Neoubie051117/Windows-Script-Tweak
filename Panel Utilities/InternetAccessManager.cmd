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

::-------------------- CONFIGURATION ::--------------------
set "WINGET_IGNORE_LIST=%SystemDrive%\winget_ignore.txt"
set "EXCLUSIONS=C:\Program Files\WindowsApps;C:\Program Files\winget"
color 07

:InternetAccessManager
cls
echo.
call :log success "===================================================================================================================="
call :log info "                                                   INTERNET ACCESS MANAGER"
call :log success "===================================================================================================================="
echo.
echo.
call :log info " [1] Block Internet Access      "
call :log info " [2] Unblock Internet Access"
call :log info ""
call :log warning " [0] Cancel"
echo.
set /p choice=" >> " 

:: Validate menu option
if "%choice%"=="1" goto blockInternetAccess
if "%choice%"=="2" goto unblockInternetAccess
if "%choice%"=="0" exit /b

color C
echo Invalid option. Returning to menu...
timeout /t 2 >nul
goto InternetAccessManager

:: Block Internet Access
:blockInternetAccess
cls
color B
echo.
echo ^<^> Preset Path Block Internet Access
echo.
echo.
echo [1] C:\Program Files\Microsoft Office              (Block Microsoft Office)
echo [2] C:\Program Files\Adobe                         (Block Adobe)       
echo [3] C:\Program Files (x86)\Microsoft\Edge          (Block Microsoft Edge)
echo [4] C:\Program Files\Autodesk                      (Block Autodesk)
echo [5] Enter a specific path for folder / program     (Block a specific path/folder/program)
echo.
echo [0] Return to Internet Access Manager Options
echo.
echo.
set /p block_choice=">> " 

:: Validate preset choice
if "%block_choice%"=="0" goto InternetAccessManager
if "%block_choice%"=="1" set block_path=C:\Program Files\Microsoft Office
if "%block_choice%"=="2" set block_path=C:\Program Files\Adobe
if "%block_choice%"=="3" set block_path=C:\Program Files (x86)\Microsoft\Edge
if "%block_choice%"=="4" set block_path=C:\Program Files\Autodesk
if "%block_choice%"=="5" (
    set /p block_path=Enter a specific path for folder/program: 
)

if not defined block_path (
    color C
    echo Invalid option. Returning to preset selection...
    timeout /t 2 >nul
    goto blockInternetAccess
)

:: Validate if path exists
if exist "%block_path%" (
    color E
    echo Blocking Internet access for all executables in "%block_path%" and its subfolders...
    for /r "%block_path%" %%F in (*.exe) do (
        netsh advfirewall firewall add rule name="Block_%%~nF" dir=out action=block program="%%F" >nul 2>&1
    )
    if %errorlevel%==0 (
        color A
        echo Blocked successfully.
        timeout /t 4 >nul
    ) else (
        color C
        echo Failed to block. Please try again.
        timeout /t 4 >nul
    )
) else (
    color C
    echo Invalid input or path does not exist. Please enter a valid path.
    timeout /t 3 >nul
    goto blockInternetAccess
)

:post_blockInternetAccess
cls
color E
echo.
echo Do you want to continue blocking Internet Access ?
echo.
echo.
echo [1] Continue Blocking
echo [2] Go to Unblock Internet Access (I've changed my mind)   
echo.
echo [0] Close and Exit
echo.
echo.
set /p post_blockInternetAccess_option=">> " 

if "%post_blockInternetAccess_option%"=="1" goto blockInternetAccess
if "%post_blockInternetAccess_option%"=="2" goto unblockInternetAccess
if "%post_blockInternetAccess_option%"=="0" goto exit

color C
echo Invalid input. Returning to selection...
timeout /t 2 >nul
goto post_blockInternetAccess

:: Unblock Internet Access
:unblockInternetAccess
cls
color B
echo.
echo ^<^> Preset Path Unblock Internet Access
echo.
echo.
echo [1] C:\Program Files\Microsoft Office              (Unblock Microsoft Office)
echo [2] C:\Program Files\Adobe                         (Unblock Adobe)
echo [3] C:\Program Files (x86)\Microsoft\Edge          (Unblock Microsoft Edge)
echo [4] C:\Program Files\Autodesk                      (Unblock Autodesk)
echo [5] Enter a specific path for folder / program     (Unblock a specific path/folder/program)    
echo.
echo [0] Return to Menu
echo.
echo.  
set /p unblock_choice=">> " 

:: Validate preset choice
if "%unblock_choice%"=="0" goto InternetAccessManager
if "%unblock_choice%"=="1" set unblock_path=C:\Program Files\Microsoft Office
if "%unblock_choice%"=="2" set unblock_path=C:\Program Files\Adobe
if "%unblock_choice%"=="3" set unblock_path=C:\Program Files (x86)\Microsoft\Edge
if "%unblock_choice%"=="4" set unblock_path=C:\Program Files\Autodesk
if "%unblock_choice%"=="5" (
    set /p unblock_path=Enter a specific path for folder/program: 
)

if not defined unblock_path (
    color C
    echo Invalid option. Returning to preset selection...
    timeout /t 2 >nul
    goto unblockInternetAccess
)

:: Validate if path exists
if exist "%unblock_path%" (
    color E
    echo Unblocking Internet access for all executables in "%unblock_path%" and its subfolders...
    for /r "%unblock_path%" %%F in (*.exe) do (
        netsh advfirewall firewall delete rule name="Block_%%~nF" dir=out program="%%F" >nul 2>&1
    )
    if %errorlevel%==0 (
        color A
        echo Unblocked successfully.
        timeout /t 4 >nul
    ) else (
        color C
        echo Failed to unblock. Please try again.
        timeout /t 4 >nul
    )
) else (
    color C
    echo Invalid input or path does not exist. Please enter a valid path.
    timeout /t 3 >nul
    goto unblockInternetAccess
)

:post_unblockInternetAccess
cls
color E
echo Do you want to continue Unblock Internet Access?
echo.
echo.
echo [1] Continue to Unblock
echo [2] Go to Block Internet Access (I've changed my mind) 
echo.
echo [0] Close and Exit
echo.
echo.
set /p post_unblockInternetAccess_option=Select an option: 

if "%post_unblockInternetAccess_option%"=="1" goto unblockInternetAccess
if "%post_unblockInternetAccess_option%"=="2" goto blockInternetAccess
if "%post_unblockInternetAccess_option%"=="0" goto exit

color C
echo Invalid input. Returning to selection...
timeout /t 2 >nul
goto post_unblockInternetAccess

:exit
cls
color A
echo Exiting program...
timeout /t 3 >nul
exit

goto :eof

:: Validate if the user input is a valid menu option
:ValidateInput
setlocal
set "input=%1"
set "valid=false"

:: Check if input is a number between 0 and 10
for /f "delims=0123456789" %%i in ("%input%") do (
    set "valid=false"
    goto :eof
)

if "%input%" geq "0" if "%input%" leq "12" (
    set "valid=true"
)

if "%valid%"=="false" (
    color C
    echo ^<^> Invalid selection, please choose a valid option.
    timeout /t 2 >nul
    exit /b 1
)
endlocal
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