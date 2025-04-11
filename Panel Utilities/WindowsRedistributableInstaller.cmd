cls
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
set "XNA_URL=https://download.microsoft.com/download/E/C/6/EC62E161-6B6E-45D6-8D4D-7D8A0DF6E7B4/xnafx40_redist.msi"
set "DIRECTX_URL=https://download.microsoft.com/download/8/4/A/84A35BF1-DAFE-4AE8-82AF-AD2AE20B6B14/directx_Jun2010_redist.exe"
set "OPENAL_URL=https://github.com/kcat/openal-soft/releases/download/1.21.1/openal-soft-1.21.1-bin.zip"
set "VCREDIST_URL=https://aka.ms/vs/17/release/vc_redist.x64.exe"
set "DOTNET_URL=https://download.visualstudio.microsoft.com/download/pr/6d5e68e1-3ad3-4e1d-95e3-6d7d6bdc3b22/40b2b15a6a7f3b0a2c7d8a4c4d8e4e7e/dotnet-sdk-6.0.100-win-x64.exe"

:: Architecture Detection
set "ARCH=%PROCESSOR_ARCHITECTURE%"
if "%ARCH%"=="AMD64" (set "SYS_DIR=System32") else (set "SYS_DIR=SysWOW64")

:: Main Logic
call :InstallXNA
call :InstallDirectX
call :InstallOpenAL
call :InstallVCRedist
call :InstallDotNet

call :log success "All components installed successfully."
pause
exit /b 0

:InstallXNA
reg query "HKLM\SOFTWARE\Microsoft\XNA\Framework\v4.0" /v Installed >nul 2>&1 && (
    call :log info "XNA Framework 4.0 is already installed."
    exit /b 0
)
call :log progress "Installing XNA Framework 4.0..."
set "FILENAME=%TEMP%\xnafx40.msi"
powershell -Command "Invoke-WebRequest -Uri '%XNA_URL%' -OutFile '%FILENAME%' -UseBasicParsing -ErrorAction Stop"
if not exist "%FILENAME%" (call :log error "Failed to download XNA." && exit /b 1)
msiexec /i "%FILENAME%" /quiet /norestart
del "%FILENAME%"
exit /b %ERRORLEVEL%

:InstallDirectX
if exist "%WINDIR%\%SYS_DIR%\d3dx9_43.dll" (
    call :log info "DirectX components are already installed."
    exit /b 0
)
call :log progress "Installing DirectX Runtime..."
set "FILENAME=%TEMP%\dxsetup.exe"
powershell -Command "Invoke-WebRequest -Uri '%DIRECTX_URL%' -OutFile '%FILENAME%' -UseBasicParsing"
if not exist "%FILENAME%" (call :log error "Failed to download DirectX." && exit /b 1)
start /wait "" "%FILENAME%" /silent
del "%FILENAME%"
exit /b %ERRORLEVEL%

:InstallOpenAL
if exist "%WINDIR%\%SYS_DIR%\OpenAL32.dll" (
    call :log info "OpenAL is already installed."
    exit /b 0
)
call :log progress "Installing OpenAL..."
set "ZIP_FILE=%TEMP%\openal.zip"
set "UNZIP_DIR=%TEMP%\openal"
powershell -Command "Invoke-WebRequest -Uri '%OPENAL_URL%' -OutFile '%ZIP_FILE%' -UseBasicParsing"
if not exist "%ZIP_FILE%" (call :log error "Failed to download OpenAL." && exit /b 1)
powershell -Command "Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%UNZIP_DIR%'"
copy /y "%UNZIP_DIR%\openal-soft-1.21.1-bin\bin\Win64\soft_oal.dll" "%WINDIR%\System32\OpenAL32.dll"
copy /y "%UNZIP_DIR%\openal-soft-1.21.1-bin\bin\Win32\soft_oal.dll" "%WINDIR%\SysWOW64\OpenAL32.dll"
rmdir /s /q "%UNZIP_DIR%"
del "%ZIP_FILE%"
exit /b 0

:InstallVCRedist
reg query "HKLM\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64" /v Installed >nul 2>&1 && (
    call :log info "VC++ 2015-2022 Redistributable is already installed."
    exit /b 0
)
call :log progress "Installing VC++ Redistributable..."
set "FILENAME=%TEMP%\vcredist.exe"
powershell -Command "Invoke-WebRequest -Uri '%VCREDIST_URL%' -OutFile '%FILENAME%' -UseBasicParsing"
if not exist "%FILENAME%" (call :log error "Failed to download VC++ Redist." && exit /b 1)
start /wait "" "%FILENAME%" /install /quiet /norestart
del "%FILENAME%"
exit /b %ERRORLEVEL%

:InstallDotNet
where /q dotnet.exe && (
    call :log info ".NET SDK 6.0 is already installed."
    exit /b 0
)
call :log progress "Installing .NET SDK 6.0..."
set "FILENAME=%TEMP%\dotnet-sdk.exe"
powershell -Command "Invoke-WebRequest -Uri '%DOTNET_URL%' -OutFile '%FILENAME%' -UseBasicParsing"
if not exist "%FILENAME%" (call :log error "Failed to download .NET SDK." && exit /b 1)
start /wait "" "%FILENAME%" /install /quiet /norestart
del "%FILENAME%"
exit /b %ERRORLEVEL%

:log
setlocal
echo off
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
    echo [%type%] %msg%
)

endlocal
exit /b 0