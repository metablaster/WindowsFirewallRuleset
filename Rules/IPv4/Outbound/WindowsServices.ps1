
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019, 2020 metablaster zebal@protonmail.ch

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

<#
.SYNOPSIS
Outbound firewall rules for Windows services

.DESCRIPTION
Windows services rules
Rules which apply to Windows services which are not handled by predefined rules

.EXAMPLE
PS> .\WindowsServices.ps1

.INPUTS
None. You cannot pipe objects to WindowsServices.ps1

.OUTPUTS
None. WindowsServices.ps1 does not generate any output

.NOTES
None.
#>

#region Initialization
#Requires -RunAsAdministrator
. $PSScriptRoot\..\..\..\Config\ProjectSettings.ps1

# Check requirements
Initialize-Project -Abort

# Imports
. $PSScriptRoot\DirectionSetup.ps1
Import-Module -Name Ruleset.UserInfo

# Setup local variables
$Group = "Windows Services"
$Accept = "Outbound rules for system services will be loaded, required for proper functioning of operating system"
$Deny = "Skip operation, outbound rules for system services will not be loaded into firewall"

# Extension rules are special rules for problematic services, see "ProblematicTraffic.md" for more info
$ExtensionAccounts = Get-SDDL -Domain "NT AUTHORITY" -User "SYSTEM", "LOCAL SERVICE", "NETWORK SERVICE"
Merge-SDDL ([ref] $ExtensionAccounts) $UsersGroupSDDL

# User prompt
Update-Context "IPv$IPVersion" $Direction $Group
if (!(Approve-Execute -Accept $Accept -Deny $Deny)) { exit }
#endregion

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore

#
# Rules for Windows services
#

New-NetFirewallRule -DisplayName "Delivery Optimization" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private, Domain `
	-Service DoSvc -Program $ServiceHost -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort 80, 443 `
	-LocalUser Any `
	-InterfaceType $DefaultInterface `
	-Description "Service responsible for delivery optimization.
Windows Update Delivery Optimization works by letting you get Windows updates and Microsoft Store
apps from sources in addition to Microsoft, like other PCs on your local network, or PCs on the
Internet that are downloading the same files.
Delivery Optimization also sends updates and apps from your PC to other PCs on your local network
or PCs on the Internet, based on your settings." |
Format-Output

# TODO: duplicate description
New-NetFirewallRule -DisplayName "Delivery Optimization" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private, Domain `
	-Service DoSvc -Program $ServiceHost -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress LocalSubnet4 `
	-LocalPort Any -RemotePort 7680 `
	-LocalUser Any `
	-InterfaceType $DefaultInterface `
	-Description "Service responsible for delivery optimization.
Windows Update Delivery Optimization works by letting you get Windows updates and Microsoft Store
apps from sources in addition to Microsoft, like other PCs on your local network, or PCs on the
Internet that are downloading the same files.
Delivery Optimization also sends updates and apps from your PC to other PCs on your local network
or PCs on the Internet, based on your settings." |
Format-Output

New-NetFirewallRule -DisplayName "Delivery Optimization" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private, Domain `
	-Service DoSvc -Program $ServiceHost -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress LocalSubnet4 `
	-LocalPort Any -RemotePort 7680 `
	-LocalUser Any `
	-InterfaceType $DefaultInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Service responsible for delivery optimization.
Windows Update Delivery Optimization works by letting you get Windows updates and Microsoft Store
apps from sources in addition to Microsoft, like other PCs on your local network, or PCs on the
Internet that are downloading the same files.
Delivery Optimization also sends updates and apps from your PC to other PCs on your local network
or PCs on the Internet, based on your settings." |
Format-Output

New-NetFirewallRule -DisplayName "Windows Modules Installer" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service TrustedInstaller -Program $ServiceHost -Group $Group `
	-Enabled True -Action Block -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort 443 `
	-LocalUser Any `
	-InterfaceType $DefaultInterface `
	-Description "Enables installation, modification, and removal of Windows updates and optional
components.
If this service is disabled, install or uninstall of Windows updates might fail for this computer." |
Format-Output

New-NetFirewallRule -DisplayName "Windows Time (NTP/SNTP)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service W32Time -Program $ServiceHost -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort 123 `
	-LocalUser Any `
	-InterfaceType $DefaultInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Maintains date and time synchronization on all clients and servers in the network.
If this service is stopped, date and time synchronization will be unavailable.
If this service is disabled, any services that explicitly depend on it will fail to start." |
Format-Output

New-NetFirewallRule -DisplayName "Windows Time (DayTime)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service W32Time -Program $ServiceHost -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort 13 `
	-LocalUser Any `
	-InterfaceType $DefaultInterface `
	-Description "Maintains date and time synchronization on all clients and servers in the network.
If this service is stopped, date and time synchronization will be unavailable.
If this service is disabled, any services that explicitly depend on it will fail to start." |
Format-Output

New-NetFirewallRule -DisplayName "Windows Time (DayTime)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service W32Time -Program $ServiceHost -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort 13 `
	-LocalUser Any `
	-InterfaceType $DefaultInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Maintains date and time synchronization on all clients and servers in the network.
If this service is stopped, date and time synchronization will be unavailable.
If this service is disabled, any services that explicitly depend on it will fail to start." |
Format-Output

New-NetFirewallRule -DisplayName "Windows Time (TIME)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service W32Time -Program $ServiceHost -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort 37 `
	-LocalUser Any `
	-InterfaceType $DefaultInterface `
	-Description "Maintains date and time synchronization on all clients and servers in the network.
If this service is stopped, date and time synchronization will be unavailable.
If this service is disabled, any services that explicitly depend on it will fail to start." |
Format-Output

New-NetFirewallRule -DisplayName "Windows Time (TIME)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service W32Time -Program $ServiceHost -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort 37 `
	-LocalUser Any `
	-InterfaceType $DefaultInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Maintains date and time synchronization on all clients and servers in the network.
If this service is stopped, date and time synchronization will be unavailable.
If this service is disabled, any services that explicitly depend on it will fail to start." |
Format-Output

New-NetFirewallRule -DisplayName "Windows Push Notifications System Service" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service WpnService -Program $ServiceHost -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort 443 `
	-LocalUser Any `
	-InterfaceType $DefaultInterface `
	-Description "This service runs in session 0 and hosts the notification platform and connection
provider which handles the connection between the device and WNS server." |
Format-Output

# NOTE: this service's name isn't constant, need to query correct name
$Service = Get-Service | Where-Object {
	$_.ServiceName -like "WpnUserService*" -or
	$_.DisplayName -like "Windows Push Notifications User Service*"
} | Select-Object -ExpandProperty Name

if ($Service)
{
	# TODO: Service may change it's name randomly, which makes this rule useless
	New-NetFirewallRule -DisplayName "Windows Push Notifications User Service" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service $Service -Program $ServiceHost -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 80, 443 `
		-LocalUser Any `
		-InterfaceType $DefaultInterface `
		-Description "This service hosts Windows notification platform which provides support for
local and push notifications. Supported notifications are tile, toast and raw." |
	Format-Output
}
else
{
	# NOTE: this may not be found on fresh installed system, need to reload later
	Write-Warning -Message "Windows Push Notifications User Service was not found"
}

New-NetFirewallRule -DisplayName "Windows Insider Service" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service wisvc -Program $ServiceHost -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort 443 `
	-LocalUser Any `
	-InterfaceType $DefaultInterface `
	-Description "Provides infrastructure support for the Windows Insider Program.
This service must remain enabled for the Windows Insider Program to work." |
Format-Output

# TODO: utcsvc was seen in "Education" edition but soon dissapeared
# Looks like Diagnostic Tracking Service or DiagTrack
# https://www.thewindowsclub.com/utcsvc-high-cpu-and-disk-usage

New-NetFirewallRule -DisplayName "Connected User Experiences and Telemetry" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service DiagTrack -Program $ServiceHost -Group $Group `
	-Enabled True -Action Block -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort 443 `
	-LocalUser Any `
	-InterfaceType $DefaultInterface `
	-Description "Enables features that support in-application and connected user experiences.
Additionally, this service manages the event driven collection and transmission of diagnostic and
usage information when the diagnostics and usage privacy option settings are enabled under Feedback
and Diagnostics." | Format-Output

New-NetFirewallRule -DisplayName "Group Policy Client" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private, Domain `
	-Service gpsvc -Program $ServiceHost -Group $Group `
	-Enabled True -Action Block -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort 443 `
	-LocalUser Any `
	-InterfaceType $DefaultInterface `
	-Description "The service is responsible for applying settings configured by administrators for
the computer and users through the Group Policy component.
If the service is disabled, the settings will not be applied and applications and components will
not be manageable through Group Policy.
Any components or applications that depend on the Group Policy component might not be functional
if the service is disabled." |
Format-Output

# NOTE: Account detected is: SECURITY_LOCAL_SYSTEM_RID S-1-5-18 A special account used by the operating system.
New-NetFirewallRule -DisplayName "Device Setup Manager" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service DsmSvc -Program $ServiceHost -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort 80 `
	-LocalUser Any `
	-InterfaceType $DefaultInterface `
	-Description "Enables the detection, download and installation of device-related software.
If this service is disabled, devices may be configured with outdated software, and may not work
correctly." |
Format-Output

New-NetFirewallRule -DisplayName "Network Location Awareness" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Any `
	-Service NlaSvc -Program $ServiceHost -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort 80 `
	-LocalUser Any `
	-InterfaceType $DefaultInterface `
	-Description "Collects and stores configuration information for the network and notifies
programs when this information is modified.
If this rule is disabled, configuration information might be unavailable." |
Format-Output

New-NetFirewallRule -DisplayName "Network services discovery" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service FDResPub -Program $ServiceHost -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress LocalSubnet4 `
	-LocalPort Any -RemotePort 3702 `
	-LocalUser Any `
	-InterfaceType $DefaultInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Web Services Dynamic Discovery (WS-Discovery) is a technical specification that
defines a multicast discovery protocol
to locate services on a local network.
It operates over TCP and UDP port 3702 and uses IP multicast address 239.255.255.250." |
Format-Output

New-NetFirewallRule -DisplayName "Router SSDP discovery" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service SSDPSRV -Program $ServiceHost -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress DefaultGateway4 `
	-LocalPort Any -RemotePort 48300 `
	-LocalUser Any `
	-InterfaceType $DefaultInterface `
	-Description "SSDP service discovers networked devices and services that use the SSDP discovery
protocol, such as UPnP devices.
Also announces SSDP devices and services running on the local computer.
If this rule is blocked, router SSDP-based services will not be discovered." |
Format-Output

#
# Windows services extension rules
# see "ProblematicTraffic.md" for more info
#

# TODO: how do we make use of an array of user accounts for Get-SDDLFromAccounts
# TODO: network service use for wlidsvc doesn't seem to work, BITS also fails connecting to router
# sometimes but receives data.
New-NetFirewallRule -DisplayName "Extension rule for complex services" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service Any -Program $ServiceHost -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort 80, 443 `
	-LocalUser $ExtensionAccounts `
	-InterfaceType $DefaultInterface `
	-Description "Extension rule for active users and NT localsystem, following services need
access based on logged on user:
Cryptographic Services(CryptSvc),
Microsoft Account Sign-in Assistant(wlidsvc),
Windows Update(wuauserv),
Background Intelligent Transfer Service(BITS),
BITS and CryptSvc in addition need System account and wlidsvc needs both Network Service and
local service account" |
Format-Output

#
# Following rules are in "ProblematicTraffic" pseudo group, these need extension rules (above)
#

# TODO: trying with localuser: Any
New-NetFirewallRule -DisplayName "Background Intelligent Transfer Service" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service BITS -Program $ServiceHost -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort 80, 443 `
	-LocalUser Any `
	-InterfaceType $DefaultInterface `
	-Description "Used for background update,
note that BITS is used by many third-party tools to download their own updates like AcrobatReader.
Transfers files in the background using idle network bandwidth. If the service is disabled,
then any applications that depend on BITS, such as Windows Update or MSN Explorer,
will be unable to automatically download programs and other information." |
Format-Output

# BITS to Router info: https://docs.microsoft.com/en-us/windows/win32/bits/network-bandwidth
# NOTE: Port was 48300, but other random ports can be used too
New-NetFirewallRule -DisplayName "Router capability check (BITS)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service BITS -Program $ServiceHost -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress DefaultGateway4 `
	-LocalPort Any -RemotePort Any `
	-LocalUser Any `
	-InterfaceType $DefaultInterface `
	-Description "BITS (Background Intelligent Transfer Service) monitors the network traffic
at the Internet gateway device (IGD) or the client's network interface card (NIC) and uses only the
idle portion of the network bandwidth.
If BITS uses the network interface card to measure traffic and there are no network applications
running on the client, BITS will consume most of the available bandwidth.
This can be an issue if the client has a fast network adapter but the full internet connection is
through a slow link (like a DSL router) because BITS will compete for the full bandwidth instead
of using only the available bandwidth on the slow link;
To use a gateway device, the device must support byte counters
(the device must respond to the GetTotalBytesSent and GetTotalBytesReceived actions)
and Universal Plug and Play (UPnP) must be enabled." |
Format-Output

# TODO: fails on port 80 regardless of extension rule
New-NetFirewallRule -DisplayName "Cryptographic Services" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service CryptSvc -Program $ServiceHost -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort 80, 443 `
	-LocalUser Any `
	-InterfaceType $DefaultInterface `
	-Description "Provides three management services:
Catalog Database Service, which confirms the signatures of Windows files and allows new programs
to be installed;
Protected Root Service, which adds and removes Trusted Root Certification Authority certificates
from this computer;
and Automatic Root Certificate Update Service, which retrieves root certificates from
Windows Update and enable scenarios such as SSL." |
Format-Output

New-NetFirewallRule -DisplayName "Windows update service" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service wuauserv -Program $ServiceHost -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort 80, 443 `
	-LocalUser Any `
	-InterfaceType $DefaultInterface `
	-Description "Enables the detection, download, and installation of updates for Windows and
other programs.
If this service is disabled, users of this computer will not be able to use Windows Update or its
automatic updating feature,
and programs will not be able to use the Windows Update Agent (WUA) API." |
Format-Output

New-NetFirewallRule -DisplayName "Microsoft Account Sign-in Assistant" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service wlidsvc -Program $ServiceHost -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort 443 `
	-LocalUser Any `
	-InterfaceType $DefaultInterface `
	-Description "Enables user sign-in through Microsoft account identity services.
If this service is stopped, users will not be able to logon to the computer with their
Microsoft account." |
Format-Output

#
# Recommended Troubleshooting predefined rule
#

# NOTE: does not exist in Windows Server 2019
New-NetFirewallRule -DisplayName "Recommended Troubleshooting Client" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private, Public `
	-Service TroubleshootingSvc -Program $ServiceHost -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Any `
	-LocalPort Any -RemotePort 80, 443 `
	-LocalUser Any `
	-InterfaceType $DefaultInterface `
	-Description "Allow outbound HTTP/HTTPS traffic from Recommended Troubleshooting Client." |
Format-Output

#
# @FirewallAPI.dll,-80204 predefined rule
#

New-NetFirewallRule -DisplayName "Windows Camera Frame Server" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private, Public `
	-Service FrameServer -Program $ServiceHost -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress LocalSubnet4 `
	-LocalPort Any -RemotePort 554, 8554-8558 `
	-LocalUser Any `
	-InterfaceType $DefaultInterface `
	-Description "Service enables multiple clients to access video frames from camera devices." |
Format-Output

Update-Log
