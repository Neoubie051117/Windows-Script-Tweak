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

::-------------------- DNS CONFIGURATION MENU --------------------
:AddDNSConfiguration
cls
color 0A
call :log success "=================================================[ DNS Configuration Menu ]========================================="
echo.
call :log warning "        DNS                 IPV4                                                IPV6                                Hostname"
echo.
call :log info " [1] Google DNS      (8.8.8.8 / 8.8.4.4)                   (2001:4860:4860::8888 / 2001:4860:4860::8844)        dns.google"
call :log info " [2] Adguard DNS     (94.140.14.14 / 94.140.15.15)         (2a10:50c0::ad1:ff / 2a10:50c0::ad2:ff)              dns.adguard.com"
call :log info " [3] Cloudflare DNS  (1.1.1.1 / 1.0.0.1)                   (2606:4700:4700::1111 / 2606:4700:4700::1001)        one.one.one.one"
call :log info " [4] Open DNS        (208.67.220.220 / 208.67.222.222)     (2620:119:35::35 / 2620:119:53::53)                  dns.opendns.com"
call :log warning " [5] Remove DNS Settings (IPv4 and IPv6)"
echo.
call :log warning " [0] Back to Main Menu"
echo.
echo.
set /p "choice=>> "


if "%choice%"=="1" call :ConfigureDNS "Google" "8.8.8.8" "8.8.4.4" "2001:4860:4860::8888" "2001:4860:4860::8844"
if "%choice%"=="2" call :ConfigureDNS "Adguard" "94.140.14.14" "94.140.15.15" "2a10:50c0::ad1:ff" "2a10:50c0::ad2:ff"
if "%choice%"=="3" call :ConfigureDNS "Cloudflare" "1.1.1.1" "1.0.0.1" "2606:4700:4700::1111" "2606:4700:4700::1001"
if "%choice%"=="4" call :ConfigureDNS "OpenDNS" "208.67.220.220" "208.67.222.222" "2620:119:35::35" "2620:119:53::53"
if "%choice%"=="5" call :RemoveDNS
if "%choice%"=="0" goto :eof

call :log error "Invalid choice. Please try again."
timeout /t 2 >nul
goto AddDNSConfiguration

::-------------------- CONFIGURE SELECTED DNS --------------------
:ConfigureDNS
cls
call :log progress "[%1] DNS Configuration (IPv4: %2 / %3) (IPv6: %4 / %5)"
call :ApplyDNS "%2" "%3" "%4" "%5"
goto AddDNSConfiguration

::-------------------- CONFIGURE RANDOM DNS --------------------
:AutoDNS
cls
call :log progress "[Auto] DNS Configuration (Random selection)"
set /a randomDNS=%random% %% 4 + 1

if %randomDNS%==1 call :ConfigureDNS "Google" "8.8.8.8" "8.8.4.4" "2001:4860:4860::8888" "2001:4860:4860::8844"
if %randomDNS%==2 call :ConfigureDNS "Adguard" "94.140.14.14" "94.140.15.15" "2a10:50c0::ad1:ff" "2a10:50c0::ad2:ff"
if %randomDNS%==3 call :ConfigureDNS "Cloudflare" "1.1.1.1" "1.0.0.1" "2606:4700:4700::1111" "2606:4700:4700::1001"
if %randomDNS%==4 call :ConfigureDNS "OpenDNS" "208.67.220.220" "208.67.222.222" "2620:119:35::35" "2620:119:53::53"
goto AddDNSConfiguration

:RemoveDNS
cls
call :log progress "[Remove DNS] Cleaning all DNS entries from active interfaces..."

for /f "tokens=1,2,3,*" %%A in ('netsh interface show interface ^| findstr /i "Connected"') do (
    set "interface=%%D"
    call :log progress "Removing DNS from: %%D"

    :: Remove IPv4 DNS
    netsh interface ip delete dns name="%%D" all >nul 2>&1 || call :log warning "IPv4 DNS removal failed on %%D"

    :: Remove IPv6 DNS if applicable
    set "IPv6Enabled=0"
    for /f "tokens=*" %%Z in ('netsh interface ipv6 show interfaces ^| findstr /i "%%D"') do (
        set "IPv6Enabled=1"
    )

    if "!IPv6Enabled!"=="1" (
        netsh interface ipv6 delete dns name="%%D" all >nul 2>&1 || call :log warning "IPv6 DNS removal failed on %%D"
    ) else (
        call :log info "IPv6 not enabled on %%D. Skipping."
    )

    echo.
)

call :log success "All DNS settings removed from active interfaces."
timeout /t 2 >nul
goto AddDNSConfiguration


::-------------------- DETECT CONNECTED NETWORK INTERFACE --------------------
:GetNetworkInterface
setlocal enabledelayedexpansion
set "interface_name="

:: Step 1: Look for connected interface with IPv4 and default gateway (best match)
for /f "tokens=1,2,3,*" %%A in ('netsh interface show interface ^| findstr /i "Connected"') do (
    set "candidate_interface=%%D"

    for /f "tokens=2 delims=:" %%G in ('netsh interface ipv4 show config name="%%D" ^| findstr /i "Default Gateway"') do (
        if not "%%G"=="None" (
            set "interface_name=%%~D"
            goto :found
        )
    )
)

:: Step 2: Fallback — any connected interface with IPv4 address
if not defined interface_name (
    for /f "tokens=1,2,3,*" %%A in ('netsh interface show interface ^| findstr /i "Connected"') do (
        set "candidate_interface=%%D"
        for /f "tokens=2 delims=:" %%X in ('netsh interface ipv4 show address name="%%D" ^| findstr /i "IP Address"') do (
            set "interface_name=%%D"
            goto :found
        )
    )
)

:: Step 3: Last resort — use WMIC for any enabled interface
if not defined interface_name (
    for /f "delims=" %%I in ('powershell -Command "Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | Select -ExpandProperty Name"') do (
        set "interface_name=%%I"
        goto :found
    )
)

:found
if not defined interface_name (
    call :log error "No active network interface with valid IP or internet access found."
    timeout /t 5 >nul
    endlocal
    exit /b 1
)

endlocal & set "interface_name=%interface_name%"
call :log info "Detected active interface: %interface_name%"
exit /b 0

::-------------------- APPLY DNS SETTINGS TO INTERFACE --------------------
:ApplyDNS
setlocal enabledelayedexpansion
set "dns_primary=%~1"
set "dns_secondary=%~2"
set "dns_primary_v6=%~3"
set "dns_secondary_v6=%~4"

call :log info "Scanning all connected network interfaces..."

:: Loop through all interfaces marked as "Connected"
for /f "tokens=1,2,3,*" %%A in ('netsh interface show interface ^| findstr /i "Connected"') do (
    set "interface=%%D"

    :: Check if it has an IPv4 address
    for /f "tokens=2 delims=:" %%G in ('netsh interface ipv4 show address name="%%D" ^| findstr /i "IP Address"') do (
        call :log progress "Applying DNS to: \"%%D\""

        :: Clean existing IPv4 DNS
        netsh interface ip delete dns name="%%D" all >nul 2>&1

        :: Apply IPv4 DNS
        netsh interface ipv4 set dnsservers name="%%D" source=static address="%dns_primary%" >nul 2>&1 || call :log error "Primary IPv4 DNS failed on %%D"
        netsh interface ipv4 add dnsservers name="%%D" address="%dns_secondary%" index=2 >nul 2>&1 || call :log error "Secondary IPv4 DNS failed on %%D"

        :: Check for IPv6
        set "IPv6Enabled=0"
        for /f "tokens=*" %%Z in ('netsh interface ipv6 show interfaces ^| findstr /i "%%D"') do (
            set "IPv6Enabled=1"
        )

        if "!IPv6Enabled!"=="1" (
            call :log progress "Applying IPv6 DNS to: %%D"
            netsh interface ipv6 delete dns name="%%D" all >nul 2>&1
            netsh interface ipv6 set dnsservers name="%%D" static %dns_primary_v6% >nul 2>&1 || call :log error "Primary IPv6 DNS failed on %%D"
            netsh interface ipv6 add dnsservers name="%%D" %dns_secondary_v6% index=2 >nul 2>&1 || call :log error "Secondary IPv6 DNS failed on %%D"
        ) else (
            call :log info "IPv6 not enabled on %%D. Skipping IPv6 DNS config."
        )

        echo.
    )
)

call :log success "DNS settings applied to all active interfaces."
timeout /t 2 >nul
endlocal
exit /b 0

::-------------------- RETURN TO MAIN MENU --------------------
:MainMenu
cls
call :log info "Returning to Main Menu..."
timeout /t 2 >nul
exit /b 0

::-------------------- LOG FUNCTION WITH ANSI COLOR OUTPUT --------------------
:log
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
exit /b 0
