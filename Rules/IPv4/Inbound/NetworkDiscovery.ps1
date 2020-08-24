
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

. $PSScriptRoot\..\..\..\Config\ProjectSettings.ps1

# Check requirements
Initialize-Project

# Imports
. $PSScriptRoot\DirectionSetup.ps1
. $PSScriptRoot\..\IPSetup.ps1
Import-Module -Name Project.AllPlatforms.Logging
Import-Module -Name Project.Windows.UserInfo

#
# Setup local variables
#
$Group = "Network Discovery"
$FirewallProfile = "Private, Domain"

# User prompt
Update-Context "IPv$IPVersion" $Direction $Group @Logs
if (!(Approve-Execute @Logs)) { exit }

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore @Logs

#
# Network Discovery predefined rules + additional rules
# Rules apply to network discovery on LAN
#

New-NetFirewallRule -Platform $Platform `
	-DisplayName "Link Local Multicast Name Resolution" -Service Dnscache -Program $ServiceHost `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $FirewallProfile -InterfaceType $Interface `
	-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress LocalSubnet4 -LocalPort 5355 -RemotePort Any `
	-EdgeTraversalPolicy Block -LocalUser Any -LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Rule for Network Discovery to allow Link Local Multicast Name Resolution.
The DNS Client service (dnscache) caches Domain Name System (DNS) names and registers the full computer name for this computer.
If the rule is disabled, DNS names will continue to be resolved.
However, the results of DNS name queries will not be cached and the computer's name will not be registered." @Logs | Format-Output @Logs

New-NetFirewallRule -Platform $Platform `
	-DisplayName "NetBIOS Datagram" -Service Any -Program System `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile Private -InterfaceType $Interface `
	-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress LocalSubnet4 -LocalPort 138 -RemotePort Any `
	-EdgeTraversalPolicy Block -LocalUser $NT_AUTHORITY_System -LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Rule for Network Discovery to allow NetBIOS Datagram transmission and reception." @Logs | Format-Output @Logs

New-NetFirewallRule -Platform $Platform `
	-DisplayName "NetBIOS Datagram" -Service Any -Program System `
	-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile Domain -InterfaceType $Interface `
	-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress Intranet4 -LocalPort 138 -RemotePort Any `
	-EdgeTraversalPolicy Block -LocalUser $NT_AUTHORITY_System -LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Rule for Network Discovery to allow NetBIOS Datagram transmission and reception." @Logs | Format-Output @Logs

New-NetFirewallRule -Platform $Platform `
	-DisplayName "NetBIOS Name" -Service Any -Program System `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile Private -InterfaceType $Interface `
	-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress LocalSubnet4 -LocalPort 137 -RemotePort Any `
	-EdgeTraversalPolicy Block -LocalUser $NT_AUTHORITY_System -LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Rule for Network Discovery to allow NetBIOS Name Resolution." @Logs | Format-Output @Logs

New-NetFirewallRule -Platform $Platform `
	-DisplayName "NetBIOS Name" -Service Any -Program System `
	-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile Domain -InterfaceType $Interface `
	-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress Intranet4 -LocalPort 137 -RemotePort Any `
	-EdgeTraversalPolicy Block -LocalUser $NT_AUTHORITY_System -LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Rule for Network Discovery to allow NetBIOS Name Resolution." @Logs | Format-Output @Logs

New-NetFirewallRule -Platform $Platform `
	-DisplayName "Function Discovery Resource Publication (WSD)" -Service FDResPub -Program $ServiceHost `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $FirewallProfile -InterfaceType $Interface `
	-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress LocalSubnet4 -LocalPort 3702 -RemotePort Any `
	-EdgeTraversalPolicy Block -LocalUser Any -LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Rule for Network Discovery to discover devices via Function Discovery.
Publishes this computer and resources attached to this computer so they can be discovered over the network.
If this rule is disabled, network resources will no longer be published and they will not be discovered by other computers on the network." @Logs | Format-Output @Logs

New-NetFirewallRule -Platform $Platform `
	-DisplayName "SSDP Discovery" -Service SSDPSRV -Program $ServiceHost `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $FirewallProfile -InterfaceType $Interface `
	-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress LocalSubnet4 -LocalPort 1900 -RemotePort Any `
	-EdgeTraversalPolicy Block -LocalUser Any -LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Rule for Network Discovery to allow use of the Simple Service Discovery Protocol.
Service discovers networked devices and services that use the SSDP discovery protocol, such as UPnP devices.
Also announces SSDP devices and services running on the local computer.
If this rule is disabled, SSDP-based devices will not be discovered." @Logs | Format-Output @Logs

New-NetFirewallRule -Platform $Platform `
	-DisplayName "UPnP Device Host" -Service Any -Program System `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile Private -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress LocalSubnet4 -LocalPort 2869 -RemotePort Any `
	-EdgeTraversalPolicy Block -LocalUser $NT_AUTHORITY_System `
	-Description "Rule for Network Discovery to allow use of Universal Plug and Play.
Allows UPnP devices to be hosted on this computer.
If this rule is disabled, any hosted UPnP devices will stop functioning and no additional hosted devices can be added." @Logs | Format-Output @Logs

New-NetFirewallRule -Platform $Platform `
	-DisplayName "UPnP Device Host" -Service Any -Program System `
	-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile Domain -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Intranet4 -LocalPort 2869 -RemotePort Any `
	-EdgeTraversalPolicy Block -LocalUser $NT_AUTHORITY_System `
	-Description "Rule for Network Discovery to allow use of Universal Plug and Play.
Allows UPnP devices to be hosted on this computer.
If this rule is disabled, any hosted UPnP devices will stop functioning and no additional hosted devices can be added." @Logs | Format-Output @Logs

New-NetFirewallRule -Platform $Platform `
	-DisplayName "WSD Events" -Service Any -Program System `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile Private -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress LocalSubnet4 -LocalPort 5357 -RemotePort Any `
	-EdgeTraversalPolicy Block -LocalUser $NT_AUTHORITY_System `
	-Description "Rule for Network Discovery to allow WSDAPI Events via Function Discovery." @Logs | Format-Output @Logs

New-NetFirewallRule -Platform $Platform `
	-DisplayName "WSD Events" -Service Any -Program System `
	-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile Domain -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Intranet4 -LocalPort 5357 -RemotePort Any `
	-EdgeTraversalPolicy Block -LocalUser $NT_AUTHORITY_System `
	-Description "Rule for Network Discovery to allow WSDAPI Events via Function Discovery." @Logs | Format-Output @Logs

New-NetFirewallRule -Platform $Platform `
	-DisplayName "WSD Events Secure" -Service Any -Program System `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile Private -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress LocalSubnet4 -LocalPort 5358 -RemotePort Any `
	-EdgeTraversalPolicy Block -LocalUser $NT_AUTHORITY_System `
	-Description "Rule for Network Discovery to allow Secure WSDAPI Events via Function Discovery." @Logs | Format-Output @Logs

New-NetFirewallRule -Platform $Platform `
	-DisplayName "WSD Events Secure" -Service Any -Program System `
	-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile Domain -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Intranet4 -LocalPort 5358 -RemotePort Any `
	-EdgeTraversalPolicy Block -LocalUser $NT_AUTHORITY_System `
	-Description "Rule for Network Discovery to allow Secure WSDAPI Events via Function Discovery." @Logs | Format-Output @Logs

New-NetFirewallRule -Platform $Platform `
	-DisplayName "FDPHost (WSD)" -Service fdPHost -Program $ServiceHost `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $FirewallProfile -InterfaceType $Interface `
	-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress LocalSubnet4 -LocalPort 3702 -RemotePort Any `
	-EdgeTraversalPolicy Block -LocalUser Any -LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Rule for Network Discovery to discover devices via Function Discovery." @Logs | Format-Output @Logs

New-NetFirewallRule -Platform $Platform `
	-DisplayName "Device Association Framework Provider Host (WSD)" -Service Any -Program "%SystemRoot%\System32\dasHost.exe" `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $FirewallProfile -InterfaceType $Interface `
	-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress LocalSubnet4 -LocalPort 3702 -RemotePort Any `
	-EdgeTraversalPolicy Block -LocalUser $NT_AUTHORITY_LocalService `
	-Description "Rule for Network Discovery to discover devices via Function Discovery.
This service is new since Windows 8.
Executable also known as Device Association Framework Provider Host" @Logs | Format-Output @Logs

New-NetFirewallRule -Platform $Platform `
	-DisplayName "Teredo SSDP Discovery" -Service SSDPSRV -Program $ServiceHost `
	-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile Public -InterfaceType $Interface `
	-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress Any -LocalPort Any -RemotePort Any `
	-EdgeTraversalPolicy Block -LocalUser Any -LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Rule for Network Discovery to allow use of the Simple Service Discovery Protocol." @Logs | Format-Output @Logs

New-NetFirewallRule -Platform $Platform `
	-DisplayName "Teredo UPnP Discovery" -Service Any -Program System `
	-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile Public -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Any -LocalPort Any -RemotePort Any `
	-EdgeTraversalPolicy Block -LocalUser $NT_AUTHORITY_LocalService `
	-Description "Rule for Network Discovery to allow use of the Simple Service Discovery Protocol." @Logs | Format-Output @Logs

Update-Log
