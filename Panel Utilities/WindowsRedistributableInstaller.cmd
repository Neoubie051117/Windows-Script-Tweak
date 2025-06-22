@echo off
cls
setlocal enabledelayedexpansion

:: Colors: 
:: A - GREEN (Text UI Messages / Success)
:: C - RED (Errors / Warnings)
:: E - YELLOW (Message Updates)

:: Check if running as Administrator
net session >nul 2>&1
if %errorlevel% neq 0 (
    color C
    echo.
    echo ^<^> Windows Tool Script must be run as administrator.
    echo.
    echo ^<^> Run the script as administrator to: 
    echo            - Access restricted parts of your system
    echo            - Modify system settings
    echo            - Access protected files
    echo            - Make changes that affect other users
    echo.
    echo ^<^> How to run as admin:
    echo            - Right-click script or shortcut
    echo            - Choose 'Run as Administrator'
    echo.
    echo ^<^> Warning: This program will close in 30 seconds.
    timeout /t 30 >nul
    exit /b
)

:: Configuration URLs
set "XNA_URL=https://download.microsoft.com/download/E/C/6/EC62E161-6B6E-45D6-8D4D-7D8A0DF6E7B4/xnafx40_redist.msi"
set "DIRECTX_URL=https://download.microsoft.com/download/8/4/A/84A35BF1-DAFE-4AE8-82AF-AD2AE20B6B14/directx_Jun2010_redist.exe"
set "OPENAL_URL=https://github.com/kcat/openal-soft/releases/download/1.21.1/openal-soft-1.21.1-bin.zip"
set "VCREDIST_URL=https://aka.ms/vs/17/release/vc_redist.x64.exe"
set "DOTNET_URL=https://download.visualstudio.microsoft.com/download/pr/6d5e68e1-3ad3-4e1d-95e3-6d7d6bdc3b22/40b2b15a6a7f3b0a2c7d8a4c4d8e4e7e/dotnet-sdk-6.0.100-win-x64.exe"

:: Architecture
set "ARCH=%PROCESSOR_ARCHITECTURE%"
if "%ARCH%"=="AMD64" (set "SYS_DIR=System32") else (set "SYS_DIR=SysWOW64")

:: Install Components
call :InstallXNA
call :InstallDirectX
call :InstallOpenAL
call :InstallVCRedist
call :InstallDotNet

call :log success "All components installed successfully."
pause
exit /b 0

:InstallXNA
:: Check for XNA Framework registry key and version
set "xnaRegPath=HKLM\SOFTWARE\Microsoft\XNA\Framework\v4.0"
reg query "%xnaRegPath%" /v Installed >nul 2>&1
if %errorlevel%==0 (
    call :log info "XNA Framework 4.0 already installed."
    exit /b 0
)

call :log progress "Installing XNA Framework 4.0..."
set "FILENAME=%TEMP%\xnafx40.msi"

:: Try downloading using PowerShell
powershell -Command "try { Invoke-WebRequest -Uri '%XNA_URL%' -OutFile '%FILENAME%' -ErrorAction Stop } catch { exit 1 }"
if not exist "%FILENAME%" (
    call :log warning "Primary download failed. Trying fallback URL for XNA..."
    :: Add alternative source or skip
    call :log error "Download failed for XNA Framework. Skipping installation."
    exit /b 1
)

msiexec /i "%FILENAME%" /quiet /norestart
set "code=%ERRORLEVEL%"
if %code% neq 0 (
    call :log error "XNA installation failed with error code %code%."
) else (
    call :log success "XNA Framework 4.0 installed successfully."
)
del /f /q "%FILENAME%"
exit /b %code%

:InstallDirectX
if exist "%WINDIR%\%SYS_DIR%\d3dx9_43.dll" (
    call :log info "DirectX already installed."
    exit /b 0
)
call :log progress "Installing DirectX Runtime..."
set "FILENAME=%TEMP%\directx.exe"
powershell -Command "Invoke-WebRequest '%DIRECTX_URL%' -OutFile '%FILENAME%'"
if not exist "%FILENAME%" (
    call :log error "Download failed for DirectX."
    exit /b 1
)
start /wait "" "%FILENAME%" /silent
set "code=%ERRORLEVEL%"
del /f /q "%FILENAME%"
exit /b %code%

:InstallOpenAL
if exist "%WINDIR%\%SYS_DIR%\OpenAL32.dll" (
    call :log info "OpenAL already installed."
    exit /b 0
)
call :log progress "Installing OpenAL..."
set "ZIP_FILE=%TEMP%\openal.zip"
set "UNZIP_DIR=%TEMP%\openal"
powershell -Command "Invoke-WebRequest '%OPENAL_URL%' -OutFile '%ZIP_FILE%'"
if not exist "%ZIP_FILE%" (
    call :log error "Download failed for OpenAL."
    exit /b 1
)
powershell -Command "Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%UNZIP_DIR%'"
copy /y "%UNZIP_DIR%\openal-soft-1.21.1-bin\bin\Win64\soft_oal.dll" "%WINDIR%\System32\OpenAL32.dll" >nul
copy /y "%UNZIP_DIR%\openal-soft-1.21.1-bin\bin\Win32\soft_oal.dll" "%WINDIR%\SysWOW64\OpenAL32.dll" >nul
rmdir /s /q "%UNZIP_DIR%"
del /f /q "%ZIP_FILE%"
exit /b 0

:InstallVCRedist
:: Check if VC++ Redist 2015-2022 x64 is installed and get version
reg query "HKLM\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64" /v Version >nul 2>&1
if %errorlevel%==0 (
    for /f "tokens=3" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64" /v Version 2^>nul') do (
        set "installedVersion=%%a"
    )
    set "requiredVersion=14.38.33135.0"
    if "!installedVersion!"=="%requiredVersion%" (
        call :log info "VC++ Redistributable is up to date (v!installedVersion!)."
        exit /b 0
    ) else (
        call :log warning "VC++ Redistributable is outdated (v!installedVersion!). Updating..."
    )
) else (
    call :log progress "VC++ Redistributable not found. Installing..."
)

set "FILENAME=%TEMP%\vcredist.exe"
powershell -Command "try { Invoke-WebRequest '%VCREDIST_URL%' -OutFile '%FILENAME%' -ErrorAction Stop } catch { exit 1 }"
if not exist "%FILENAME%" (
    call :log error "Download failed for VC++ Redistributable."
    exit /b 1
)

start /wait "" "%FILENAME%" /install /quiet /norestart
set "code=%ERRORLEVEL%"
if %code% neq 0 (
    call :log error "VC++ installation failed with code %code%."
) else (
    call :log success "VC++ Redistributable installed/updated successfully."
)
del /f /q "%FILENAME%"
exit /b %code%

:InstallDotNet
where /q dotnet.exe && (
    call :log info ".NET SDK 6.0 already installed."
    exit /b 0
)
call :log progress "Installing .NET SDK 6.0..."
set "FILENAME=%TEMP%\dotnet-sdk.exe"
powershell -Command "Invoke-WebRequest '%DOTNET_URL%' -OutFile '%FILENAME%'"
if not exist "%FILENAME%" (
    call :log error "Download failed for .NET SDK."
    exit /b 1
)
start /wait "" "%FILENAME%" /install /quiet /norestart
set "code=%ERRORLEVEL%"
del /f /q "%FILENAME%"
exit /b %code%

:log
setlocal
set "type=%~1"
set "msg=%~2"

:: Color mapping
if "%type%"=="error" set "color=C"
if "%type%"=="warning" set "color=E"
if "%type%"=="success" set "color=A"
if "%type%"=="info" set "color=7"
if "%type%"=="progress" set "color=E"
if "%type%"=="critical" set "color=4F"

:: Fallback echo
echo.
echo [%type%] %msg%
echo.
endlocal
exit /b 0
