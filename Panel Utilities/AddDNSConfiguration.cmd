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
    call :log error "<> Windows Tool Script must be run as administrator."
    echo.
    call :log error "<> Run the script as administrator to:" 
    call :log error "   - Access restricted parts of your system"
    call :log error "   - Modify system settings"
    call :log error "   - Access protected files"
    call :log error "   - Make changes that affect other users on the computer"
    echo.
    call :log error "<> To run a program as an administrator on Windows:"
    call :log error "   - Locate the program you want to run"
    call :log error "   - Right-click the program's shortcut or executable file"
    call :log error "   - Select Properties"
    call :log error "   - In the Compatibility tab, check the 'Run this program as an administrator' option"
    call :log error "   - Click Apply, then OK"
    call :log error "   - Depending on your Windows Account Settings, you may receive a warning message"
    call :log error "   - Click Continue to confirm the changes"
    echo.
    call :log warning "<> Warning: This program will close in after 30 seconds."
    timeout /t 30 >nul && exit /b
)

:: DNS Configuration Menu
:AddDNSConfiguration
cls
color 0A
echo.
call :log success "=================================================[ DNS Configuration Menu ]========================================="
echo.
echo.
echo.
call :log warning "        DNS                 IPV4                                                IPV6                                Hostname"
echo.
call :log info " [1] Google DNS      (8.8.8.8 / 8.8.4.4)                   (2001:4860:4860::8888 / 2001:4860:4860::8844)        dns.google"
call :log info " [2] Adguard DNS     (94.140.14.14 / 94.140.15.15)         (2a10:50c0::ad1:ff / 2a10:50c0::ad2:ff)              dns.adguard.com"
call :log info " [3] Cloudflare DNS  (1.1.1.1 / 1.0.0.1)                   (2606:4700:4700::1111 / 2606:4700:4700::1001)        one.one.one.one"
call :log info " [4] Open DNS        (208.67.220.220 / 208.67.222.222)     (2620:119:35::35 / 2620:119:53::53)                  dns.opendns.com"
echo.
call :log info " [5] Auto (Randomly selects a DNS server)"
echo.
call :log warning " [0] Back to Main Menu
echo.
echo.
set /p "choice=>> "

if "%choice%"=="1" call :ConfigureDNS "Google" "8.8.8.8" "8.8.4.4" "2001:4860:4860::8888" "2001:4860:4860::8844"
if "%choice%"=="2" call :ConfigureDNS "Adguard" "94.140.14.14" "94.140.15.15" "2a10:50c0::ad1:ff" "2a10:50c0::ad2:ff"
if "%choice%"=="3" call :ConfigureDNS "Cloudflare" "1.1.1.1" "1.0.0.1" "2606:4700:4700::1111" "2606:4700:4700::1001"
if "%choice%"=="4" call :ConfigureDNS "OpenDNS" "208.67.220.220" "208.67.222.222" "2620:119:35::35" "2620:119:53::53"
if "%choice%"=="5" call :AutoDNS
if "%choice%"=="0" goto :eof

call :log error "Invalid choice. Please try again."
timeout /t 2 >nul
goto AddDNSConfiguration

:ConfigureDNS
cls
echo [%1] DNS Configuration (IPv4: %2 / %3) (IPv6: %4 / %5)
call :ApplyDNS "%2" "%3" "%4" "%5"
goto AddDNSConfiguration

:AutoDNS
cls
echo [Auto] DNS Configuration (Random selection)
set /a randomDNS=%random% %% 4 + 1

if "!randomDNS!"=="1" call :ConfigureDNS "Google" "8.8.8.8" "8.8.4.4" "2001:4860:4860::8888" "2001:4860:4860::8844"
if "!randomDNS!"=="2" call :ConfigureDNS "Adguard" "94.140.14.14" "94.140.15.15" "2a10:50c0::ad1:ff" "2a10:50c0::ad2:ff"
if "!randomDNS!"=="3" call :ConfigureDNS "Cloudflare" "1.1.1.1" "1.0.0.1" "2606:4700:4700::1111" "2606:4700:4700::1001"
if "!randomDNS!"=="4" call :ConfigureDNS "OpenDNS" "208.67.220.220" "208.67.222.222" "2620:119:35::35" "2620:119:53::53"

goto AddDNSConfiguration

:GetNetworkInterface
set "interface_name="
for /f "tokens=4" %%A in ('netsh interface show interface ^| findstr "Connected"') do (
    set "interface_name=%%A"
    goto :break_loop
)
:break_loop

if "%interface_name%"=="" (
    for /f "tokens=2 delims==" %%I in ('wmic nic where "NetEnabled=True" get NetConnectionID /value 2^>nul') do (
        set "interface_name=%%I"
        goto :break_wmic
    )
)
:break_wmic

if "%interface_name%"=="" (
    color C
    echo [ERROR] No connected network interface detected.
    timeout /t 5 >nul
    exit /b 1
)
exit /b 0

:ApplyDNS
set "dns_primary=%~1"
set "dns_secondary=%~2"
set "dns_primary_v6=%~3"
set "dns_secondary_v6=%~4"

call :GetNetworkInterface || (
    call :log error "Failed to find active interface"
    exit /b 1
)

set "IPv6Enabled=0"
for /f "delims=" %%A in ('netsh interface ipv6 show interfaces ^| findstr /c:"%interface_name%"') do set "IPv6Enabled=1"

echo [Status] Updating IPv4 DNS...
netsh interface ip delete dns "%interface_name%" all >nul 2>&1
netsh interface ip add dns name="%interface_name%" addr="%dns_primary%" >nul 2>&1 || echo [Error] Failed to set Primary IPv4 DNS
netsh interface ip add dns name="%interface_name%" addr="%dns_secondary%" index=2 >nul 2>&1 || echo [Error] Failed to set Secondary IPv4 DNS

if "%IPv6Enabled%"=="1" (
    echo [Status] Updating IPv6 DNS...
    netsh interface ipv6 delete dns "%interface_name%" all >nul 2>&1
    netsh interface ipv6 add dns "%interface_name%" "%dns_primary_v6%" >nul 2>&1 || echo [Error] Failed to set Primary IPv6 DNS
    netsh interface ipv6 add dns "%interface_name%" "%dns_secondary_v6%" index=2 >nul 2>&1 || echo [Error] Failed to set Secondary IPv6 DNS
) else (
    echo [Info] IPv6 not enabled. Skipping IPv6 DNS configuration.
)

call :log success "DNS settings updated successfully."
timeout /t 2 >nul
exit /b 0

:MainMenu
cls
echo Returning to Main Menu...
timeout /t 2 >nul
exit /b 0

:: Updated logging subsystem (no prefixes)
:log
setlocal EnableDelayedExpansion
set "type=%~1"
set "msg=%~2"

set "ESC=["  :: You can paste real ESC here or use a helper if needed

:: Bright colors
set "color="

if /i "%type%"=="error" set "color=91"          :: Bright Red
if /i "%type%"=="warning" set "color=93"        :: Bright Yellow
if /i "%type%"=="info" set "color=96"           :: Bright Cyan
if /i "%type%"=="progress" set "color=90"       :: Gray (Bright Black)
if /i "%type%"=="critical" set "color=97;41"    :: Bright White on Red background
if /i "%type%"=="" set "color=92"               :: Bright Green (Success default)

:: Print using ANSI colors
<nul set /p="!ESC!!color!m%msg%!ESC!0m"
echo.

endlocal
exit /b 0
