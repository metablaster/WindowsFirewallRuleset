
<#
MIT License

Project: "Windows Firewall Ruleset" serves to manage firewall on Windows systems
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

. $PSScriptRoot\..\..\..\Config\ProjectSettings.ps1

# Check requirements for this project
Import-Module -Name Project.AllPlatforms.System
Test-SystemRequirements

# Imports
. $PSScriptRoot\DirectionSetup.ps1
. $PSScriptRoot\..\IPSetup.ps1
Import-Module -Name Project.AllPlatforms.Logging
Import-Module -Name Project.Windows.UserInfo @Logs
Import-Module -Name Project.AllPlatforms.Utility @Logs

#
# Setup local variables:
#
$Group = "Network Discovery"
$FirewallProfile = "Private, Domain"

# Ask user if he wants to load these rules
Update-Context "IPv$IPVersion" $Direction $Group @Logs
if (!(Approve-Execute @Logs)) { exit }

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore @Logs

#
# Network Discovery predefined rules + additional rules
# Rules apply to network discovery on LAN
#

New-NetFirewallRule -DisplayName "Link Local Multicast Name Resolution" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Dnscache -Program $ServiceHost -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress LocalSubnet4 `
	-LocalPort Any -RemotePort 5355 `
	-LocalUser Any `
	-InterfaceType $Interface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Rule for Network Discovery to allow Link Local Multicast Name Resolution.
The DNS Client service (dnscache) caches Domain Name System (DNS) names and registers the full
computer name for this computer.
If the rule is disabled, DNS names will continue to be resolved.
However, the results of DNS name queries will not be cached and the computer's name will
not be registered." `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "NetBIOS Datagram" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private `
	-Service Any -Program System -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress LocalSubnet4 `
	-LocalPort Any -RemotePort 138 `
	-LocalUser $NT_AUTHORITY_System `
	-InterfaceType $Interface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Rule for Network Discovery to allow NetBIOS Datagram transmission and
reception." `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "NetBIOS Datagram" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Domain `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress Intranet4 `
	-LocalPort Any -RemotePort 138 `
	-LocalUser $NT_AUTHORITY_System `
	-InterfaceType $Interface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Rule for Network Discovery to allow NetBIOS Datagram transmission and
reception." `
	@Logs | Format-Output @Logs

# TODO: wont work to send to other subnets, applies to all traffic that sends to other
# local subnets such as Hyper-V subnets
New-NetFirewallRule -DisplayName "NetBIOS Name" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private `
	-Service Any -Program System -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress LocalSubnet4 `
	-LocalPort Any -RemotePort 137 `
	-LocalUser $NT_AUTHORITY_System `
	-InterfaceType $Interface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Rule for Network Discovery to allow NetBIOS Name Resolution." `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "NetBIOS Name" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Domain `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress Intranet4 `
	-LocalPort Any -RemotePort 137 `
	-LocalUser $NT_AUTHORITY_System `
	-InterfaceType $Interface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Rule for Network Discovery to allow NetBIOS Name Resolution." `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Function Discovery Resource Publication WSD" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service FDResPub -Program $ServiceHost -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress LocalSubnet4 `
	-LocalPort Any -RemotePort 3702 `
	-LocalUser Any `
	-InterfaceType $Interface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Rule for Network Discovery to discover devices via Function Discovery.
Publishes this computer and resources attached to this computer so they can be discovered over
the network.
If this rule is disabled, network resources will no longer be published and they will not be
discovered by other computers on the network." `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "SSDP Discovery" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service SSDPSRV -Program $ServiceHost -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress LocalSubnet4 `
	-LocalPort Any -RemotePort 1900 `
	-LocalUser Any `
	-InterfaceType $Interface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Rule for Network Discovery to allow use of the Simple Service Discovery Protocol.
Service discovers networked devices and services that use the SSDP discovery protocol,
such as UPnP devices.
Also announces SSDP devices and services running on the local computer.
If this rule is disabled, SSDP-based devices will not be discovered." `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "UPnP Device Host" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service upnphost -Program $ServiceHost -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress LocalSubnet4 `
	-LocalPort Any -RemotePort 2869 `
	-LocalUser Any `
	-InterfaceType $Interface `
	-Description "Rule for Network Discovery to allow use of Universal Plug and Play.
Allows UPnP devices to be hosted on this computer.
If this rule is disabled, any hosted UPnP devices will stop functioning and no additional hosted
devices can be added." `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Function Discovery Provider Host" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private `
	-Service fdPHost -Program $ServiceHost -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress LocalSubnet4 `
	-LocalPort Any -RemotePort 2869 `
	-LocalUser Any `
	-InterfaceType $Interface `
	-Description "Rule for Network Discovery to allow use of Universal Plug and Play.
The FDPHOST service hosts the Function Discovery (FD) network discovery providers.
These FD providers supply network discovery services for the Simple Services Discovery Protocol
(SSDP) and Web Services - Discovery (WS-D) protocol.
Disabling this rule will disable network discovery for these protocols when using FD." `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Function Discovery Provider Host" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Domain `
	-Service fdPHost -Program $ServiceHost -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Intranet4 `
	-LocalPort Any -RemotePort 2869 `
	-LocalUser Any `
	-InterfaceType $Interface `
	-Description "Rule for Network Discovery to allow use of Universal Plug and Play.
The FDPHOST service hosts the Function Discovery (FD) network discovery providers.
These FD providers supply network discovery services for the Simple Services Discovery Protocol
(SSDP) and Web Services - Discovery (WS-D) protocol.
Disabling this rule will disable network discovery for these protocols when using FD." `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "WSD Events" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private `
	-Service fdPHost -Program $ServiceHost -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress LocalSubnet4 `
	-LocalPort Any -RemotePort 5357 `
	-LocalUser Any `
	-InterfaceType $Interface `
	-Description "Rule for Network Discovery to allow WSDAPI Events via Function Discovery." `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "WSD Events" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Domain `
	-Service fdPHost -Program $ServiceHost -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Intranet4 `
	-LocalPort Any -RemotePort 5357 `
	-LocalUser Any `
	-InterfaceType $Interface `
	-Description "Rule for Network Discovery to allow WSDAPI Events via Function Discovery." `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "WSD Events Secure" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private `
	-Service fdPHost -Program $ServiceHost -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress LocalSubnet4 `
	-LocalPort Any -RemotePort 5358 `
	-LocalUser Any `
	-InterfaceType $Interface `
	-Description "Rule for Network Discovery to allow Secure WSDAPI Events via Function
Discovery." `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "WSD Events Secure" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Domain `
	-Service fdPHost -Program $ServiceHost -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Intranet4 `
	-LocalPort Any -RemotePort 5358 `
	-LocalUser Any `
	-InterfaceType $Interface `
	-Description "Rule for Network Discovery to allow Secure WSDAPI Events via Function
Discovery." `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "FDPHost (WSD)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service fdPHost -Program $ServiceHost -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress LocalSubnet4 `
	-LocalPort Any -RemotePort 3702 `
	-LocalUser Any `
	-InterfaceType $Interface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Rule for Network Discovery to discover devices via Function Discovery." `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Device Association Framework Provider Host (WSD)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Any -Program "%SystemRoot%\System32\dasHost.exe" -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress DefaultGateway4 `
	-LocalPort Any -RemotePort Any `
	-LocalUser $NT_AUTHORITY_LocalService `
	-InterfaceType $Interface `
	-Description "Rule for Network Discovery to discover devices via Function Discovery.
This service is new since Windows 8.
Executable also known as Device Association Framework Provider Host" `
	@Logs | Format-Output @Logs

# TODO: missing local user
New-NetFirewallRule -DisplayName "Network infrastructure discovery" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service fdPHost -Program $ServiceHost -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress DefaultGateway4 `
	-LocalPort Any -RemotePort Any `
	-InterfaceType $Interface `
	-Description "Used to discover router in workgroup. The FDPHOST service hosts the
Function Discovery (FD) network discovery providers.
These FD providers supply network discovery services for the Simple Services Discovery Protocol
(SSDP) and Web Services." `
	@Logs | Format-Output @Logs

Update-Log
