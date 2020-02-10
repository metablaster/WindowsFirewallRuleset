
<#
MIT License

Copyright (c) 2019, 2020 metablaster zebal@protonmail.ch

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

# Check requirements for this project
Import-Module -Name $PSScriptRoot\..\..\..\Modules\System
Test-SystemRequirements

# Includes
. $PSScriptRoot\DirectionSetup.ps1
. $PSScriptRoot\..\IPSetup.ps1
Import-Module -Name $PSScriptRoot\..\..\..\Modules\UserInfo
Import-Module -Name $PSScriptRoot\..\..\..\Modules\FirewallModule

#
# Setup local variables:
#
$Group = "Network Discovery"
$Profile = "Private, Domain"

# Ask user if he wants to load these rules
Update-Context $IPVersion $Direction $Group
if (!(Approve-Execute)) { exit }

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction SilentlyContinue

#
# Network Discovery predefined rules + additional rules
# Rules apply to network discovery on LAN
#

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Link Local Multicast Name Resolution" -Service Dnscache -Program $ServiceHost `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress LocalSubnet4 -LocalPort Any -RemotePort 5355 `
-LocalUser Any -LocalOnlyMapping $false -LooseSourceMapping $false `
-Description "Rule for Network Discovery to allow Link Local Multicast Name Resolution.
The DNS Client service (dnscache) caches Domain Name System (DNS) names and registers the full computer name for this computer.
If the rule is disabled, DNS names will continue to be resolved.
However, the results of DNS name queries will not be cached and the computer's name will not be registered." | Format-Output

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "NetBIOS Datagram" -Service Any -Program System `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile Private -InterfaceType $Interface `
-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress LocalSubnet4 -LocalPort Any -RemotePort 138 `
-LocalUser $NT_AUTHORITY_System -LocalOnlyMapping $false -LooseSourceMapping $false `
-Description "Rule for Network Discovery to allow NetBIOS Datagram transmission and reception." | Format-Output

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "NetBIOS Datagram" -Service Any -Program System `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile Domain -InterfaceType $Interface `
-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress Intranet4 -LocalPort Any -RemotePort 138 `
-LocalUser $NT_AUTHORITY_System -LocalOnlyMapping $false -LooseSourceMapping $false `
-Description "Rule for Network Discovery to allow NetBIOS Datagram transmission and reception." | Format-Output

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "NetBIOS Name" -Service Any -Program System `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile Private -InterfaceType $Interface `
-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress LocalSubnet4 -LocalPort Any -RemotePort 137 `
-LocalUser $NT_AUTHORITY_System -LocalOnlyMapping $false -LooseSourceMapping $false `
-Description "Rule for Network Discovery to allow NetBIOS Name Resolution." | Format-Output

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "NetBIOS Name" -Service Any -Program System `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile Domain -InterfaceType $Interface `
-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress Intranet4 -LocalPort Any -RemotePort 137 `
-LocalUser $NT_AUTHORITY_System -LocalOnlyMapping $false -LooseSourceMapping $false `
-Description "Rule for Network Discovery to allow NetBIOS Name Resolution." | Format-Output

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Function Discovery Resource Publication WSD" -Service FDResPub -Program $ServiceHost `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress LocalSubnet4 -LocalPort Any -RemotePort 3702 `
-LocalUser Any -LocalOnlyMapping $false -LooseSourceMapping $false `
-Description "Rule for Network Discovery to discover devices via Function Discovery.
Publishes this computer and resources attached to this computer so they can be discovered over the network.
If this rule is disabled, network resources will no longer be published and they will not be discovered by other computers on the network." | Format-Output

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "SSDP Discovery" -Service SSDPSRV -Program $ServiceHost `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress LocalSubnet4 -LocalPort Any -RemotePort 1900 `
-LocalUser Any -LocalOnlyMapping $false -LooseSourceMapping $false `
-Description "Rule for Network Discovery to allow use of the Simple Service Discovery Protocol.
Service discovers networked devices and services that use the SSDP discovery protocol, such as UPnP devices.
Also announces SSDP devices and services running on the local computer.
If this rule is disabled, SSDP-based devices will not be discovered." | Format-Output

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "UPnP Device Host" -Service upnphost -Program $ServiceHost `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress LocalSubnet4 -LocalPort Any -RemotePort 2869 `
-LocalUser Any `
-Description "Rule for Network Discovery to allow use of Universal Plug and Play.
Allows UPnP devices to be hosted on this computer.
If this rule is disabled, any hosted UPnP devices will stop functioning and no additional hosted devices can be added." | Format-Output

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Function Discovery Provider Host" -Service fdPHost -Program $ServiceHost `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile Private -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress LocalSubnet4 -LocalPort Any -RemotePort 2869 `
-LocalUser Any `
-Description "Rule for Network Discovery to allow use of Universal Plug and Play.
The FDPHOST service hosts the Function Discovery (FD) network discovery providers.
These FD providers supply network discovery services for the Simple Services Discovery Protocol (SSDP) and Web Services - Discovery (WS-D) protocol.
Disabling this rule will disable network discovery for these protocols when using FD." | Format-Output

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Function Discovery Provider Host" -Service fdPHost -Program $ServiceHost `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile Domain -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Intranet4 -LocalPort Any -RemotePort 2869 `
-LocalUser Any `
-Description "Rule for Network Discovery to allow use of Universal Plug and Play.
The FDPHOST service hosts the Function Discovery (FD) network discovery providers.
These FD providers supply network discovery services for the Simple Services Discovery Protocol (SSDP) and Web Services - Discovery (WS-D) protocol.
Disabling this rule will disable network discovery for these protocols when using FD." | Format-Output

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "WSD Events" -Service fdPHost -Program $ServiceHost `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile Private -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress LocalSubnet4 -LocalPort Any -RemotePort 5357 `
-LocalUser Any `
-Description "Rule for Network Discovery to allow WSDAPI Events via Function Discovery." | Format-Output

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "WSD Events" -Service fdPHost -Program $ServiceHost `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile Domain -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Intranet4 -LocalPort Any -RemotePort 5357 `
-LocalUser Any `
-Description "Rule for Network Discovery to allow WSDAPI Events via Function Discovery." | Format-Output

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "WSD Events Secure" -Service fdPHost -Program $ServiceHost `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile Private -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress LocalSubnet4 -LocalPort Any -RemotePort 5358 `
-LocalUser Any `
-Description "Rule for Network Discovery to allow Secure WSDAPI Events via Function Discovery." | Format-Output

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "WSD Events Secure" -Service fdPHost -Program $ServiceHost `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile Domain -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Intranet4 -LocalPort Any -RemotePort 5358 `
-LocalUser Any `
-Description "Rule for Network Discovery to allow Secure WSDAPI Events via Function Discovery." | Format-Output

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "FDPHost (WSD)" -Service fdPHost -Program $ServiceHost `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress LocalSubnet4 -LocalPort Any -RemotePort 3702 `
-LocalUser Any -LocalOnlyMapping $false -LooseSourceMapping $false `
-Description "Rule for Network Discovery to discover devices via Function Discovery." | Format-Output

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Device Association Framework Provider Host (WSD)" -Service Any -Program "%SystemRoot%\System32\dasHost.exe" `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress DefaultGateway4 -LocalPort Any -RemotePort Any `
-LocalUser $NT_AUTHORITY_LocalService `
-Description "Rule for Network Discovery to discover devices via Function Discovery.
This service is new since Windows 8.
Executable also known as Device Association Framework Provider Host" | Format-Output

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Network infrastructure discovery" -Service fdPHost -Program $ServiceHost `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress DefaultGateway4 -LocalPort Any -RemotePort Any `
-Description "Used to discover router in workgroup. The FDPHOST service hosts the Function Discovery (FD) network discovery providers.
These FD providers supply network discovery services for the Simple Services Discovery Protocol (SSDP) and Web Services." | Format-Output
