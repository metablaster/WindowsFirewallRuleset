
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
https://www.iana.org/assignments/ipv6-multicast-addresses/ipv6-multicast-addresses.xhtml
https://www.ronaldschlager.com/2014/ipv6-addresses-scopes-zones/

IPv6 multicast addresses are distinguished from unicast addresses by the value of the high-order
octet of the addresses:
a value of 0xFF (binary 11111111) identifies an address as a multicast address;
any other value identifies an address as a unicast address.

ff00::/16	Reserved
ff01::/16	Interface-Local scope
ff02::/16	Link-Local scope
ff03::/16	Realm-Local scope
ff04::/16	Admin-Local scope
ff05::/16   Site-Local scope
ff06::/16	Unassigned
ff07::/16	Unassigned
ff08::/16	Organization-Local scope
ff09::/16 - ff0D/16 Unassigned
ff0e::/16	Global scope
ff0f::/16  	Reserved

Interface-local scope:
IPv6 addresses of interface-local scope are mainly used for loopback tests.

Link-local scope:
IPv6 addresses of link-local scope have the same scope as link-local unicast addresses
(limited to one link, one physical network and one layer 2 broadcast domain).

Realm-local scope:
the zone of Realm-local scope must fall within zones of larger scope.

Admin-local scope:
the scope of IPv6 addresses of admin-local scope must be configured by the address administrator,
it is not automatically derived from any configuration data.

Site-local scope:
an IPv6 address of site-local scope span the same topological region as its communicating partners.

Organization-local scope:
an IPv6 address of organization-local scope is valid at all locations of the same organization
or corporation.

Global scope:
these IPv6 addresses are valid globally and are globally routable.
#>

# TODO: local address should be known for outbound, for inbound rules remote should be known

. $PSScriptRoot\..\..\..\Config\ProjectSettings.ps1

# Check requirements
Initialize-Project -Abort

# Imports
. $PSScriptRoot\DirectionSetup.ps1
. $PSScriptRoot\..\IPSetup.ps1
Import-Module -Name Project.AllPlatforms.Logging
Import-Module -Name Project.Windows.UserInfo

# Setup local variables
$Group = "Multicast IPv6"
# TODO: For untested traffic default does not include public profile
$DefaultProfile = "Private, Domain"
$MulticastProfile = "Any"
$Description = "https://www.iana.org/assignments/ipv6-multicast-addresses/ipv6-multicast-addresses.xhtml"
$MulticastUsers = Get-SDDL -Domain "NT AUTHORITY" -User "NETWORK SERVICE", "LOCAL SERVICE" @Logs

# NOTE: we need Any to include IPv6 loopback interface because IPv6 loopback rule does not work
# on boot, (neither ::1 address nor interface alias)
$MulticastInterface = "Wired, Wireless"
$Accept = "Outbound rules for IPv6 multicast will be loaded, recommended for proper network functioning"
$Deny = "Skip operation, outbound IPv6 multicast rules will not be loaded into firewall"

# User prompt
Update-Context "IPv$IPVersion" $Direction $Group @Logs
if (!(Approve-Execute -Accept $Accept -Deny $Deny @Logs)) { exit }

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore @Logs

#
# Interface-Local Multicast filtering (All destinations)
#

New-NetFirewallRule -DisplayName "Interface-Local Multicast" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Any `
	-Service Any -Program Any -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress ff01::/16 `
	-LocalPort Any -RemotePort Any `
	-LocalUser $MulticastUsers `
	-InterfaceType $MulticastInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description $Description `
	@Logs | Format-Output @Logs

#
# Interface-Local Multicast filtering (Individual destinations)
#

New-NetFirewallRule -DisplayName "Interface-Local Multicast - All Nodes" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Any `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress ff01::1 `
	-LocalPort Any -RemotePort Any `
	-LocalUser $MulticastUsers `
	-InterfaceType $MulticastInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description $Description `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Interface-Local Multicast - All Routers" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Any `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress ff01::2 `
	-LocalPort Any -RemotePort Any `
	-LocalUser $MulticastUsers `
	-InterfaceType $MulticastInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description $Description `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Interface-Local Multicast - mDNSv6" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Any `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress ff01::fb `
	-LocalPort Any -RemotePort Any `
	-LocalUser $MulticastUsers `
	-InterfaceType $MulticastInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description $Description `
	@Logs | Format-Output @Logs

#
# Link-Local Multicast filtering (All destinations)
#

New-NetFirewallRule -DisplayName "Link-Local Multicast" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Block -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress ff02::/16 `
	-LocalPort Any -RemotePort Any `
	-LocalUser $MulticastUsers `
	-InterfaceType $MulticastInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description $Description `
	@Logs | Format-Output @Logs

#
# Link-Local Multicast filtering (Individual destinations)
#

New-NetFirewallRule -DisplayName "Link-Local Multicast - All Nodes" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress ff02::1 `
	-LocalPort Any -RemotePort Any `
	-LocalUser $MulticastUsers `
	-InterfaceType $MulticastInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description $Description `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Link-Local Multicast - All Routers" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress ff02::2 `
	-LocalPort Any -RemotePort Any `
	-LocalUser $MulticastUsers `
	-InterfaceType $MulticastInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description $Description `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Link-Local Multicast - DVMRP Routers" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress ff02::4 `
	-LocalPort Any -RemotePort Any `
	-LocalUser $MulticastUsers `
	-InterfaceType $MulticastInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description $Description `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Link-Local Multicast - OSPFIGP" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress ff02::5 `
	-LocalPort Any -RemotePort Any `
	-LocalUser $MulticastUsers `
	-InterfaceType $MulticastInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description $Description `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Link-Local Multicast - OSPFIGP Designated Routers" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress ff02::6 `
	-LocalPort Any -RemotePort Any `
	-LocalUser $MulticastUsers `
	-InterfaceType $MulticastInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description $Description `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Link-Local Multicast - ST Routers" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress ff02::7 `
	-LocalPort Any -RemotePort Any `
	-LocalUser $MulticastUsers `
	-InterfaceType $MulticastInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description $Description `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Link-Local Multicast - ST Hosts" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress ff02::8 `
	-LocalPort Any -RemotePort Any `
	-LocalUser $MulticastUsers `
	-InterfaceType $MulticastInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description $Description `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Link-Local Multicast - RIP Routers" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress ff02::9 `
	-LocalPort Any -RemotePort Any `
	-LocalUser $MulticastUsers `
	-InterfaceType $MulticastInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description $Description `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Link-Local Multicast - EIGRP Routers" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress ff02::a `
	-LocalPort Any -RemotePort Any `
	-LocalUser $MulticastUsers `
	-InterfaceType $MulticastInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description $Description `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Link-Local Multicast - Mobile-Agents" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress ff02::b `
	-LocalPort Any -RemotePort Any `
	-LocalUser $MulticastUsers `
	-InterfaceType $MulticastInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description $Description `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Link-Local Multicast - SSDP" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress ff02::c `
	-LocalPort Any -RemotePort Any `
	-LocalUser $MulticastUsers `
	-InterfaceType $MulticastInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description $Description `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Link-Local Multicast - All PIM Routers" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress ff02::d `
	-LocalPort Any -RemotePort Any `
	-LocalUser $MulticastUsers `
	-InterfaceType $MulticastInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description $Description `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Link-Local Multicast - RSVP-ENCAPSULATION" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress ff02::e `
	-LocalPort Any -RemotePort Any `
	-LocalUser $MulticastUsers `
	-InterfaceType $MulticastInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description $Description `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Link-Local Multicast - UPnP" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress ff02::f `
	-LocalPort Any -RemotePort Any `
	-LocalUser $MulticastUsers `
	-InterfaceType $MulticastInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description $Description `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Link-Local Multicast - All-BBF-Access-Nodes" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress ff02::10 `
	-LocalPort Any -RemotePort Any `
	-LocalUser $MulticastUsers `
	-InterfaceType $MulticastInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description $Description `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Link-Local Multicast - VRRP" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress ff02::12 `
	-LocalPort Any -RemotePort Any `
	-LocalUser $MulticastUsers `
	-InterfaceType $MulticastInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description $Description `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Link-Local Multicast - All MLDv2-capable routers" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress ff02::16 `
	-LocalPort Any -RemotePort Any `
	-LocalUser $MulticastUsers `
	-InterfaceType $MulticastInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description $Description `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Link-Local Multicast - all-RPL-nodes" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress ff02::1a `
	-LocalPort Any -RemotePort Any `
	-LocalUser $MulticastUsers `
	-InterfaceType $MulticastInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description $Description `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Link-Local Multicast - All-Snoopers" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress ff02::6a `
	-LocalPort Any -RemotePort Any `
	-LocalUser $MulticastUsers `
	-InterfaceType $MulticastInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description $Description `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Link-Local Multicast - PTP-pdelay" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress ff02::6b `
	-LocalPort Any -RemotePort Any `
	-LocalUser $MulticastUsers `
	-InterfaceType $MulticastInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description $Description `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Link-Local Multicast - Saratoga" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress ff02::6c `
	-LocalPort Any -RemotePort Any `
	-LocalUser $MulticastUsers `
	-InterfaceType $MulticastInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description $Description `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Link-Local Multicast - LL-MANET-Routers" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress ff02::6d `
	-LocalPort Any -RemotePort Any `
	-LocalUser $MulticastUsers `
	-InterfaceType $MulticastInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description $Description `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Link-Local Multicast - IGRS" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress ff02::6e `
	-LocalPort Any -RemotePort Any `
	-LocalUser $MulticastUsers `
	-InterfaceType $MulticastInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description $Description `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Link-Local Multicast - iADT Discovery" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress ff02::6f `
	-LocalPort Any -RemotePort Any `
	-LocalUser $MulticastUsers `
	-InterfaceType $MulticastInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description $Description `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Link-Local Multicast - mDNSv6" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress ff02::fb `
	-LocalPort Any -RemotePort Any `
	-LocalUser $MulticastUsers `
	-InterfaceType $MulticastInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description $Description `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Link-Local Multicast - Link Name" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress ff02::1:1 `
	-LocalPort Any -RemotePort Any `
	-LocalUser $MulticastUsers `
	-InterfaceType $MulticastInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description $Description `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Link-Local Multicast - All-dhcp-agents" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $MulticastProfile `
	-Service Dhcp -Program $ServiceHost -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress ff02::1:2 `
	-LocalPort 546 -RemotePort 547 `
	-LocalUser Any `
	-InterfaceType $MulticastInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description $Description `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Link-Local Multicast - Link-local Multicast Name Resolution" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress ff02::1:3 `
	-LocalPort Any -RemotePort Any `
	-LocalUser $MulticastUsers `
	-InterfaceType $MulticastInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description $Description `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Link-Local Multicast - DTCP Announcement" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress ff02::1:4 `
	-LocalPort Any -RemotePort Any `
	-LocalUser $MulticastUsers `
	-InterfaceType $MulticastInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description $Description `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Link-Local Multicast - afore_vdp" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress ff02::1:5 `
	-LocalPort Any -RemotePort Any `
	-LocalUser $MulticastUsers `
	-InterfaceType $MulticastInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description $Description `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Link-Local Multicast - Babel" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress ff02::1:6 `
	-LocalPort Any -RemotePort Any `
	-LocalUser $MulticastUsers `
	-InterfaceType $MulticastInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description $Description `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Link-Local Multicast - Solicited-Node Address" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress ff02::1:ff00:0000/104 `
	-LocalPort Any -RemotePort Any `
	-LocalUser $MulticastUsers `
	-InterfaceType $MulticastInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description $Description `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Link-Local Multicast - Node Information Queries" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress FF02:0:0:0:0:2:FF00::/104 `
	-LocalPort Any -RemotePort Any `
	-LocalUser $MulticastUsers `
	-InterfaceType $MulticastInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description $Description `
	@Logs | Format-Output @Logs

#
# Site-Local Multicast filtering (All destinations)
#

New-NetFirewallRule -DisplayName "Site-Local Multicast - All Routers" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Block -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress ff05::/16 `
	-LocalPort Any -RemotePort Any `
	-LocalUser $MulticastUsers `
	-InterfaceType $MulticastInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description $Description `
	@Logs | Format-Output @Logs

#
# Site-Local Multicast filtering (Individual destinations)
#

New-NetFirewallRule -DisplayName "Site-Local Multicast - All Routers" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress ff05::2 `
	-LocalPort Any -RemotePort Any `
	-LocalUser $MulticastUsers `
	-InterfaceType $MulticastInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description $Description `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Site-Local Multicast - mDNSv6" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress ff05::fb `
	-LocalPort Any -RemotePort Any `
	-LocalUser $MulticastUsers `
	-InterfaceType $MulticastInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description $Description `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Site-Local Multicast - All-dhcp-servers" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $MulticastProfile `
	-Service Dhcp -Program $ServiceHost -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress ff05::1:3 `
	-LocalPort 546 -RemotePort 547 `
	-LocalUser Any `
	-InterfaceType $MulticastInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description $Description `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Site-Local Multicast - SL-MANET-ROUTERS" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress ff05::1:5 `
	-LocalPort Any -RemotePort Any `
	-LocalUser $MulticastUsers `
	-InterfaceType $MulticastInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description $Description `
	@Logs | Format-Output @Logs

#
# Realm-Local Multicast filtering (All destinations)
#

New-NetFirewallRule -DisplayName "Realm-Local Multicast" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Block -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress ff03::/16 `
	-LocalPort Any -RemotePort Any `
	-LocalUser $MulticastUsers `
	-InterfaceType $MulticastInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description $Description `
	@Logs | Format-Output @Logs

#
# Admin-Local Multicast filtering (All destinations)
#

New-NetFirewallRule -DisplayName "Admin-Local Multicast" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Block -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress ff04::/16 `
	-LocalPort Any -RemotePort Any `
	-LocalUser $MulticastUsers `
	-InterfaceType $MulticastInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description $Description `
	@Logs | Format-Output @Logs

#
# Organization-Local Multicast filtering (All destinations)
#

New-NetFirewallRule -DisplayName "Organization-Local Multicast" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Block -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress ff08::/16 `
	-LocalPort Any -RemotePort Any `
	-LocalUser $MulticastUsers `
	-InterfaceType $MulticastInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description $Description `
	@Logs | Format-Output @Logs

#
# Global scope Multicast filtering (All destinations)
#

New-NetFirewallRule -DisplayName "Global scope Multicast" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Block -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress ff0e::/16 `
	-LocalPort Any -RemotePort Any `
	-LocalUser $MulticastUsers `
	-InterfaceType $MulticastInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description $Description `
	@Logs | Format-Output @Logs

Update-Log
