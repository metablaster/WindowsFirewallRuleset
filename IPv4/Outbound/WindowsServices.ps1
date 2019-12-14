
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
. "$PSScriptRoot\..\..\Modules\GlobalVariables.ps1"

# Ask user if he wants to load these rules
if (!(RunThis)) { exit }

#
# Setup local variables:
#
$Group = "Windows Services"
$Profile = "Private, Public"
$Interface = "Wired, Wireless"
$ServiceHost = "%SystemRoot%\System32\svchost.exe"

#First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction Outbound -ErrorAction SilentlyContinue

#
# Windows services rules
# Rules that apply to Windows services which are not handled by predefined rules
#

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Background Intelligent Transfer Service" -Program $ServiceHost -Service BITS `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
-Description "Used for background update,
note that BITS is used by many third-party tools to download their own updates like AcrobatReader.
Transfers files in the background using idle network bandwidth. If the service is disabled,
then any applications that depend on BITS, such as Windows Update or MSN Explorer,
will be unable to automatically download programs and other information."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Cryptographic Services" -Program $ServiceHost -Service CryptSvc `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
-Description "Provides three management services:
Catalog Database Service, which confirms the signatures of Windows files and allows new programs to be installed;
Protected Root Service, which adds and removes Trusted Root Certification Authority certificates from this computer;
and Automatic Root Certificate Update Service, which retrieves root certificates from Windows Update and enable scenarios such as SSL."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Delivery Optimization" -Program $ServiceHost -Service DoSvc `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
-Description "Service responsible for delivery optimization.
Windows Update Delivery Optimization works by letting you get Windows updates and Microsoft Store apps from sources in addition to Microsoft,
like other PCs on your local network, or PCs on the Internet that are downloading the same files.
Delivery Optimization also sends updates and apps from your PC to other PCs on your local network or PCs on the Internet, based on your settings."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Windows update service" -Program $ServiceHost -Service wuauserv `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
-Description "Enables the detection, download, and installation of updates for Windows and other programs.
If this service is disabled, users of this computer will not be able to use Windows Update or its automatic updating feature,
and programs will not be able to use the Windows Update Agent (WUA) API."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Windows Modules Installer" -Program $ServiceHost -Service TrustedInstaller `
-PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
-Description "Enables installation, modification, and removal of Windows updates and optional components.
If this service is disabled, install or uninstall of Windows updates might fail for this computer."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Microsoft Account Sign-in Assistant" -Program $ServiceHost -Service wlidsvc `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
-Description "Enables user sign-in through Microsoft account identity services.
If this service is stopped, users will not be able to logon to the computer with their Microsoft account."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Windows Time (NTP/SNTP)" -Program $ServiceHost -Service W32Time `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol UDP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 123 `
-Description "Maintains date and time synchronization on all clients and servers in the network.
If this service is stopped, date and time synchronization will be unavailable.
If this service is disabled, any services that explicitly depend on it will fail to start."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Windows Time (DayTime)" -Program $ServiceHost -Service W32Time `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 13 `
-Description "Maintains date and time synchronization on all clients and servers in the network.
If this service is stopped, date and time synchronization will be unavailable.
If this service is disabled, any services that explicitly depend on it will fail to start."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Windows Time (DayTime)" -Program $ServiceHost -Service W32Time `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol UDP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 13 `
-Description "Maintains date and time synchronization on all clients and servers in the network.
If this service is stopped, date and time synchronization will be unavailable.
If this service is disabled, any services that explicitly depend on it will fail to start."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Windows Time (TIME)" -Program $ServiceHost -Service W32Time `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 37 `
-Description "Maintains date and time synchronization on all clients and servers in the network.
If this service is stopped, date and time synchronization will be unavailable.
If this service is disabled, any services that explicitly depend on it will fail to start."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Windows Time (TIME)" -Program $ServiceHost -Service W32Time `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol UDP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 37 `
-Description "Maintains date and time synchronization on all clients and servers in the network.
If this service is stopped, date and time synchronization will be unavailable.
If this service is disabled, any services that explicitly depend on it will fail to start."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Windows Push Notifications System Service" -Program $ServiceHost -Service WpnService `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
-Description "This service runs in session 0 and hosts the notification platform and connection provider
which handles the connection between the device and WNS server."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Windows Push Notifications User Service" -Program $ServiceHost -Service WpnUserService_e13583 `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
-Description "This service hosts Windows notification platform which provides support for local and push notifications.
Supported notifications are tile, toast and raw."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Windows Insider Service" -Program $ServiceHost -Service wisvc `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
-Description "Provides infrastructure support for the Windows Insider Program.
This service must remain enabled for the Windows Insider Program to work."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Group Policy Client" -Program $ServiceHost -Service gpsvc `
-PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
-Description "The service is responsible for applying settings configured by administrators for the computer and users through the Group Policy component.
If the service is disabled, the settings will not be applied and applications and components will not be manageable through Group Policy.
Any components or applications that depend on the Group Policy component might not be functional if the service is disabled."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Device Setup Manager" -Program $ServiceHost -Service DsmSvc `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80 `
-Description "Enables the detection, download and installation of device-related software.
If this service is disabled, devices may be configured with outdated software, and may not work correctly."
