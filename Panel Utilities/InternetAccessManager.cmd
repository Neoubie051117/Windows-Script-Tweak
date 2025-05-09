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


:: Configuration
set "WINGET_IGNORE_LIST=%SystemDrive%\winget_ignore.txt"
set "EXCLUSIONS=C:\Program Files\WindowsApps;C:\Program Files\winget"
color 07

:InternetAccessManager
cls
color A
echo.
echo ^<^> Internet Access Manager
echo.
echo.
echo [1] Block Internet Access
echo [2] Unblock Internet Access
echo.
echo [0] Cancel
echo.
set /p choice=">> " 

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