
<#
MIT License

Copyright (c) 2019 metablaster zebal@protonmail.ch

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
#>

#
# Import global variables
#
Import-Module -Name $PSScriptRoot\..\FirewallModule

# Ask user if he wants to load these rules
if (!(Approve-Execute)) { exit }

#
# Setup local variables:
#
$Group = "Windows Services"
$Profile = "Private, Public"
$Direction = "Outbound"
# Extension rules are special rules for problematic services, see ProblematicTraffic.md for more info
[string[]] $ExtensionAccounts = @("NT AUTHORITY\SYSTEM", "NT AUTHORITY\LOCAL SERVICE", "NT AUTHORITY\NETWORK SERVICE")
$ExtensionAccounts += $UserAccounts
$ExtensionUsers = (Get-AccountSDDL $ExtensionAccounts)

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction SilentlyContinue

#
# Windows services rules
# Rules that apply to Windows services which are not handled by predefined rules
#

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Delivery Optimization" -Service DoSvc -Program $ServiceHost `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile Private, Domain -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
-LocalUser Any `
-Description "Service responsible for delivery optimization.
Windows Update Delivery Optimization works by letting you get Windows updates and Microsoft Store apps from sources in addition to Microsoft,
like other PCs on your local network, or PCs on the Internet that are downloading the same files.
Delivery Optimization also sends updates and apps from your PC to other PCs on your local network or PCs on the Internet, based on your settings."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Delivery Optimization" -Service DoSvc -Program $ServiceHost `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile Private, Domain -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress LocalSubnet4 -LocalPort Any -RemotePort 7680 `
-LocalUser Any `
-Description "Service responsible for delivery optimization.
Windows Update Delivery Optimization works by letting you get Windows updates and Microsoft Store apps from sources in addition to Microsoft,
like other PCs on your local network, or PCs on the Internet that are downloading the same files.
Delivery Optimization also sends updates and apps from your PC to other PCs on your local network or PCs on the Internet, based on your settings."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Delivery Optimization" -Service DoSvc -Program $ServiceHost `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile Private, Domain -InterfaceType $Interface `
-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress LocalSubnet4 -LocalPort Any -RemotePort 7680 `
-LocalUser Any -LocalOnlyMapping $false -LooseSourceMapping $false `
-Description "Service responsible for delivery optimization.
Windows Update Delivery Optimization works by letting you get Windows updates and Microsoft Store apps from sources in addition to Microsoft,
like other PCs on your local network, or PCs on the Internet that are downloading the same files.
Delivery Optimization also sends updates and apps from your PC to other PCs on your local network or PCs on the Internet, based on your settings."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Windows Modules Installer" -Service TrustedInstaller -Program $ServiceHost `
-PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
-LocalUser Any `
-Description "Enables installation, modification, and removal of Windows updates and optional components.
If this service is disabled, install or uninstall of Windows updates might fail for this computer."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Windows Time (NTP/SNTP)" -Service W32Time -Program $ServiceHost `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 123 `
-LocalUser Any -LocalOnlyMapping $false -LooseSourceMapping $false `
-Description "Maintains date and time synchronization on all clients and servers in the network.
If this service is stopped, date and time synchronization will be unavailable.
If this service is disabled, any services that explicitly depend on it will fail to start."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Windows Time (DayTime)" -Service W32Time -Program $ServiceHost `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 13 `
-LocalUser Any `
-Description "Maintains date and time synchronization on all clients and servers in the network.
If this service is stopped, date and time synchronization will be unavailable.
If this service is disabled, any services that explicitly depend on it will fail to start."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Windows Time (DayTime)" -Service W32Time -Program $ServiceHost `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 13 `
-LocalUser Any -LocalOnlyMapping $false -LooseSourceMapping $false `
-Description "Maintains date and time synchronization on all clients and servers in the network.
If this service is stopped, date and time synchronization will be unavailable.
If this service is disabled, any services that explicitly depend on it will fail to start."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Windows Time (TIME)" -Service W32Time -Program $ServiceHost `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 37 `
-LocalUser Any `
-Description "Maintains date and time synchronization on all clients and servers in the network.
If this service is stopped, date and time synchronization will be unavailable.
If this service is disabled, any services that explicitly depend on it will fail to start."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Windows Time (TIME)" -Service W32Time -Program $ServiceHost `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 37 `
-LocalUser Any -LocalOnlyMapping $false -LooseSourceMapping $false `
-Description "Maintains date and time synchronization on all clients and servers in the network.
If this service is stopped, date and time synchronization will be unavailable.
If this service is disabled, any services that explicitly depend on it will fail to start."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Windows Push Notifications System Service" -Service WpnService -Program $ServiceHost `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
-LocalUser Any `
-Description "This service runs in session 0 and hosts the notification platform and connection provider
which handles the connection between the device and WNS server."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Windows Push Notifications User Service" -Service WpnUserService_e13583 -Program $ServiceHost `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
-LocalUser Any `
-Description "This service hosts Windows notification platform which provides support for local and push notifications.
Supported notifications are tile, toast and raw."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Windows Insider Service" -Service wisvc -Program $ServiceHost `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
-LocalUser Any `
-Description "Provides infrastructure support for the Windows Insider Program.
This service must remain enabled for the Windows Insider Program to work."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Group Policy Client" -Service gpsvc -Program $ServiceHost `
-PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile Private, Domain -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
-LocalUser Any `
-Description "The service is responsible for applying settings configured by administrators for the computer and users through the Group Policy component.
If the service is disabled, the settings will not be applied and applications and components will not be manageable through Group Policy.
Any components or applications that depend on the Group Policy component might not be functional if the service is disabled."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Device Setup Manager" -Service DsmSvc -Program $ServiceHost `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80 `
-LocalUser Any `
-Description "Enables the detection, download and installation of device-related software.
If this service is disabled, devices may be configured with outdated software, and may not work correctly."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Network Location Awareness" -Service NlaSvc -Program $ServiceHost `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile Any -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80 `
-LocalUser Any `
-Description "Collects and stores configuration information for the network and notifies programs when this information is modified.
If this rule is disabled, configuration information might be unavailable."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Network services discovery" -Service FDResPub -Program $ServiceHost `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress LocalSubnet4 -LocalPort Any -RemotePort 3702 `
-LocalUser Any -LocalOnlyMapping $false -LooseSourceMapping $false `
-Description "Web Services Dynamic Discovery (WS-Discovery) is a technical specification that defines a multicast discovery protocol
to locate services on a local network.
It operates over TCP and UDP port 3702 and uses IP multicast address 239.255.255.250."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Router SSDP discovery" -Service SSDPSRV -Program $ServiceHost `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress DefaultGateway4 -LocalPort Any -RemotePort 48300 `
-LocalUser Any `
-Description "SSDP service discovers networked devices and services that use the SSDP discovery protocol, such as UPnP devices.
Also announces SSDP devices and services running on the local computer.
If this rule is blocked, router SSDP-based services will not be discovered."

#
# Windows services extension rules
# see ProblematicTraffic.md for more info
#

# TODO: how do we make use of an array of user accounts for Get-SDDLFromAccounts
# TODO: network service use for wlidsvc doesn't seem to work, BITS also fails connecting to router sometimes but receives data.
New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Extension rule for complex services" -Service Any -Program $ServiceHost `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
-LocalUser $ExtensionUsers `
-Description "Extension rule for active users and NT localsystem, following services need access based on loged on user:
Cryptographic Services(CryptSvc),
Microsoft Account Sign-in Assistant(wlidsvc),
Windows Update(wuauserv),
Background Intelligent Transfer Service(BITS),
BITS and CryptSvc in addition need System account and wlidsvc needs both Network Service and local service account"

# TODO: Temporary using network service account
New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Extension rule for Router capability check (BITS)" -Service Any -Program $ServiceHost `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress DefaultGateway4 -LocalPort Any -RemotePort 48300 `
-LocalUser $ExtensionUsers `
-Description "Extension rule for active users to allow BITS to Internet gateway device (IGD)"

#
# Following rules are in "ProblematicTraffic" pseudo group, these need extension rules (above)
#

# TODO: try with localuser: Any
New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Background Intelligent Transfer Service" -Service BITS -Program $ServiceHost `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
-LocalUser Any `
-Description "Used for background update,
note that BITS is used by many third-party tools to download their own updates like AcrobatReader.
Transfers files in the background using idle network bandwidth. If the service is disabled,
then any applications that depend on BITS, such as Windows Update or MSN Explorer,
will be unable to automatically download programs and other information."

# BITS to Router info: https://docs.microsoft.com/en-us/windows/win32/bits/network-bandwidth
New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Router capability check (BITS)" -Service BITS -Program $ServiceHost `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress DefaultGateway4 -LocalPort Any -RemotePort 48300 `
-LocalUser Any `
-Description "BITS (Background Intelligent Transfer Service) monitors the network traffic at the Internet gateway device (IGD)
or the client's network interface card (NIC) and uses only the idle portion of the network bandwidth.
If BITS uses the network interface card to measure traffic and there are no network applications running on the client,
BITS will consume most of the available bandwidth.
This can be an issue if the client has a fast network adapter but the full internet connection is through a slow link (like a DSL router)
because BITS will compete for the full bandwidth instead of using only the available bandwidth on the slow link;
To use a gateway device, the device must support byte counters (the device must respond to the GetTotalBytesSent and GetTotalBytesReceived actions)
and Universal Plug and Play (UPnP) must be enabled."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Cryptographic Services" -Service CryptSvc -Program $ServiceHost `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
-LocalUser Any `
-Description "Provides three management services:
Catalog Database Service, which confirms the signatures of Windows files and allows new programs to be installed;
Protected Root Service, which adds and removes Trusted Root Certification Authority certificates from this computer;
and Automatic Root Certificate Update Service, which retrieves root certificates from Windows Update and enable scenarios such as SSL."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Windows update service" -Service wuauserv -Program $ServiceHost `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
-LocalUser Any `
-Description "Enables the detection, download, and installation of updates for Windows and other programs.
If this service is disabled, users of this computer will not be able to use Windows Update or its automatic updating feature,
and programs will not be able to use the Windows Update Agent (WUA) API."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Microsoft Account Sign-in Assistant" -Service wlidsvc -Program $ServiceHost `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
-LocalUser Any `
-Description "Enables user sign-in through Microsoft account identity services.
If this service is stopped, users will not be able to logon to the computer with their Microsoft account."

#
# Recommended Troubleshooting predefined rule
#

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Recommended Troubleshooting Client" -Service TroubleshootingSvc -Program $ServiceHost `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile Private, Public -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Any -LocalPort Any -RemotePort 80, 443 `
-LocalUser Any `
-Description "Allow outbound HTTP/HTTPS traffic from Recommended Troubleshooting Client."

#
# @FirewallAPI.dll,-80204 predefined rule
#

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Windows Camera Frame Server" -Service FrameServer -Program $ServiceHost `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile Private, Public -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress LocalSubnet4 -LocalPort Any -RemotePort 554, 8554-8558 `
-LocalUser Any `
-Description "Service enables multiple clients to access video frames from camera devices."
