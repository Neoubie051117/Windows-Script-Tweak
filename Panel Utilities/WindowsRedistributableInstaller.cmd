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

::-------------------- SET DOWNLOAD URLS FOR REDIST COMPONENTS --------------------
set "XNA_URL=https://download.microsoft.com/download/E/C/6/EC62E161-6B6E-45D6-8D4D-7D8A0DF6E7B4/xnafx40_redist.msi"
set "DIRECTX_URL=https://download.microsoft.com/download/8/4/A/84A35BF1-DAFE-4AE8-82AF-AD2AE20B6B14/directx_Jun2010_redist.exe"
set "OPENAL_URL=https://github.com/kcat/openal-soft/releases/download/1.21.1/openal-soft-1.21.1-bin.zip"
set "VCREDIST_URL=https://aka.ms/vs/17/release/vc_redist.x64.exe"
set "DOTNET_URL=https://download.visualstudio.microsoft.com/download/pr/6d5e68e1-3ad3-4e1d-95e3-6d7d6bdc3b22/40b2b15a6a7f3b0a2c7d8a4c4d8e4e7e/dotnet-sdk-6.0.100-win-x64.exe"

::-------------------- DETECT ARCHITECTURE --------------------
set "ARCH=%PROCESSOR_ARCHITECTURE%"
if "%ARCH%"=="AMD64" (set "SYS_DIR=System32") else (set "SYS_DIR=SysWOW64")

::-------------------- INSTALL EACH COMPONENT --------------------
call :log warning "Windows Redistributable Installer" && echo.
call :InstallXNA
call :InstallDirectX
call :InstallOpenAL
call :InstallVCRedist
call :InstallDotNet

call :log success "All components installed successfully."
pause
exit /b 0

::-------------------- XNA INSTALLER --------------------
:InstallXNA
set "xnaRegPath=HKLM\SOFTWARE\Microsoft\XNA\Framework\v4.0"
reg query "%xnaRegPath%" /v Installed >nul 2>&1
if %errorlevel%==0 (
    call :log info "XNA Framework 4.0 already installed."
    exit /b 0
)

call :log progress "Installing XNA Framework 4.0..."
set "FILENAME=%TEMP%\xnafx40.msi"
set "FALLBACK_XNA=https://archive.org/download/xnafx40_redist/xnafx40_redist.msi"
if exist "%FILENAME%" del /f /q "%FILENAME%"
powershell -Command "try { Invoke-WebRequest -Uri '%XNA_URL%' -OutFile '%FILENAME%' -ErrorAction Stop } catch { exit 1 }"

set "tryFallback="
if not exist "%FILENAME%" set "tryFallback=true"
for %%I in ("%FILENAME%") do set "size=%%~zI"
if "!size!" LSS 1000000 set "tryFallback=true"

if defined tryFallback (
    call :log warning "Primary download failed or file too small. Trying fallback..."
    if exist "%FILENAME%" del /f /q "%FILENAME%"
    for /f "tokens=2 delims=:" %%A in ('powershell -Command "(Invoke-WebRequest '%FALLBACK_XNA%').Headers['Content-Length']"') do set "expectedSize=%%A"
    powershell -Command "try { Invoke-WebRequest -Uri '%FALLBACK_XNA%' -OutFile '%FILENAME%' -ErrorAction Stop } catch { exit 1 }"
    if not exist "%FILENAME%" (
        call :log error "Fallback download failed. Manual install may be needed:"
        echo https://archive.org/download/xnafx40_redist/xnafx40_redist.msi
        exit /b 1
    )
    for %%I in ("%FILENAME%") do set "actualSize=%%~zI"
    if defined expectedSize (
        set /a margin=%expectedSize%*90/100
        if !actualSize! LSS !margin! (
            call :log warning "Fallback downloaded, but size is low (!actualSize! bytes). Expected ~%expectedSize% bytes. Proceeding anyway..."
        ) else (
            call :log success "Downloaded XNA Framework from fallback URL. Size: !actualSize! bytes"
        )
    ) else (
        call :log info "Could not verify expected size. Downloaded size: !actualSize! bytes"
    )
)

msiexec /i "%FILENAME%" /quiet /norestart
set "code=%ERRORLEVEL%"
if %code% neq 0 (
    call :log error "XNA installation failed with code %code%."
) else (
    call :log success "XNA Framework 4.0 installed successfully."
)
del /f /q "%FILENAME%"
exit /b %code%

::-------------------- DIRECTX INSTALLER --------------------
:InstallDirectX
if exist "%WINDIR%\%SYS_DIR%\d3dx9_43.dll" (
    call :log info "DirectX already installed."
    exit /b 0
)
call :log progress "Installing DirectX Runtime..."
set "FILENAME=%TEMP%\directx.exe"
powershell -Command "try { Invoke-WebRequest '%DIRECTX_URL%' -OutFile '%FILENAME%' -ErrorAction Stop } catch { exit 1 }"
if not exist "%FILENAME%" (
    call :log warning "Primary DirectX download failed. Trying fallback..."
    set "FALLBACK_DIRECTX=https://web.archive.org/web/20211231235959/https://download.microsoft.com/download/8/4/A/84A35BF1-DAFE-4AE8-82AF-AD2AE20B6B14/directx_Jun2010_redist.exe"
    powershell -Command "try { Invoke-WebRequest '%FALLBACK_DIRECTX%' -OutFile '%FILENAME%' -ErrorAction Stop } catch { exit 1 }"
    if not exist "%FILENAME%" (
        call :log error "DirectX download failed from fallback. Skipping."
        exit /b 1
    ) else (
        call :log success "Downloaded DirectX from fallback URL."
    )
)
start /wait "" "%FILENAME%" /silent
set "code=%ERRORLEVEL%"
del /f /q "%FILENAME%"
exit /b %code%

::-------------------- OPENAL INSTALLER --------------------
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

::-------------------- VC++ REDIST INSTALLER --------------------
:InstallVCRedist
reg query "HKLM\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64" /v Version >nul 2>&1
if %errorlevel%==0 (
    for /f "tokens=3" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64" /v Version 2^>nul') do (
        set "installedVersion=%%a"
    )
    set "requiredVersion=14.38.33135.0"
    set "installedVersion=!installedVersion:v=!"
    if "!installedVersion!" GEQ "%requiredVersion%" (
        call :log info "VC++ Redistributable is up to date (!installedVersion!)."
        exit /b 0
    ) else (
        call :log warning "VC++ Redistributable is outdated (!installedVersion!). Proceeding with update..."
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

::-------------------- .NET SDK INSTALLER --------------------
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
