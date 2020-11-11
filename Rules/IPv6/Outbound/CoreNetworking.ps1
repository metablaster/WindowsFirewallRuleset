
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
Initialize-Project -Abort

# Imports
. $PSScriptRoot\DirectionSetup.ps1
. $PSScriptRoot\..\IPSetup.ps1
Import-Module -Name Ruleset.Logging
Import-Module -Name Ruleset.UserInfo

# Setup local variables
$Group = "Core Networking - IPv6"
$FirewallProfile = "Any"
$Accept = "Outbound rules for IPv6 core networking will be loaded, required for proper network functioning"
$Deny = "Skip operation, outbound IPv6 core networking rules will not be loaded into firewall"

# User prompt
Update-Context "IPv$IPVersion" $Direction $Group @Logs
if (!(Approve-Execute -Accept $Accept -Deny $Deny @Logs)) { exit }

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore @Logs

#
# Predefined rules from Core Networking are here
#

#
# Loop back
# TODO: why specifying loopback address ::1/128 doesn't work?
# NOTE: IPv6 loopback rule does not work
# NOTE: even though we specify "IPv6 the loopback interface alias is the same for IPv4 and IPv6,
# meaning there is only one loopback interface!"
# $Loopback = Get-NetIPInterface | Where-Object {
# 	$_.InterfaceAlias -like "*Loopback*" -and $_.AddressFamily -eq "IPv6"
# } | Select-Object -ExpandProperty InterfaceAlias


# New-NetFirewallRule -DisplayName "Loopback IP" `
# 	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
# 	-Service Any -Program Any -Group $Group `
# 	-Enabled True -Action Allow -Direction $Direction -Protocol Any `
# 	-LocalAddress Any -RemoteAddress Any `
# 	-LocalPort Any -RemotePort Any `
# 	-LocalUser Any `
#	-InterfaceType Any -InterfaceAlias $Loopback `
# 	-Description "This rule covers both IPv4 and IPv6 loopback interface.
# Network software and utilities use loopback address to access a local computer's TCP/IP network
# resources." `
# 	@Logs | Format-Output @Logs

#
# DNS (Domain Name System)
#

New-NetFirewallRule -DisplayName "DNS Client" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Dnscache -Program $ServiceHost -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress DNS6 `
	-LocalPort Any -RemotePort 53 `
	-LocalUser Any `
	-InterfaceType $Interface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Rule to allow IPv6 DNS (Domain Name System) requests." `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Domain Name System" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress DefaultGateway6 `
	-LocalPort Any -RemotePort 53 `
	-LocalUser $NT_AUTHORITY_System `
	-InterfaceType $Interface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Rule to allow IPv6 DNS (Domain Name System) requests by System to default gateway." `
	@Logs | Format-Output @Logs

#
# mDNS (Multicast Domain Name System)
# NOTE: this should be placed in Multicast.ps1 like it is for IPv6, but it's here because of
# specific address, which is part of "Local Network Control Block" (224.0.0.0 - 224.0.0.255)
# An mDNS message is a multicast UDP packet sent using the following addressing:
# IPv4 address 224.0.0.251 or IPv6 address ff02::fb
# UDP port 5353
# https://en.wikipedia.org/wiki/Multicast_DNS
#

New-NetFirewallRule -DisplayName "Multicast DNS" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private, Domain `
	-Service Dnscache -Program $ServiceHost -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress ff02::fb `
	-LocalPort 5353 -RemotePort 5353 `
	-LocalUser Any `
	-InterfaceType $Interface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "In computer networking, the multicast DNS (mDNS) protocol resolves hostnames to IP
addresses within small networks that do not include a local name server.
It is a zero-configuration service, using essentially the same programming interfaces,
packet formats and operating semantics as the unicast Domain Name System (DNS)." `
 @Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Multicast DNS" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Public `
	-Service Dnscache -Program $ServiceHost -Group $Group `
	-Enabled False -Action Block -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress ff02::fb `
	-LocalPort 5353 -RemotePort 5353 `
	-LocalUser Any `
	-InterfaceType $Interface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "In computer networking, the multicast DNS (mDNS) protocol resolves hostnames to IP
addresses within small networks that do not include a local name server.
It is a zero-configuration service, using essentially the same programming interfaces,
packet formats and operating semantics as the unicast Domain Name System (DNS)." `
 @Logs | Format-Output @Logs

#
# DHCP (Dynamic Host Configuration Protocol)
# TODO: Need a rule for DHCP server
# https://tools.ietf.org/html/rfc8415
#

New-NetFirewallRule -DisplayName "DHCP Client" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Dhcp -Program $ServiceHost -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress DHCP6 `
	-LocalPort 546 -RemotePort 547 `
	-LocalUser Any `
	-InterfaceType $Interface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Dynamic Host Configuration Protocol (DHCP) allows DHCPv6 messages for stateful
auto-configuration." `
	@Logs | Format-Output @Logs

#
# IGMP (Internet Group Management Protocol)
#

# Multicast Listener Discovery (MLD) is a component of the Internet Protocol Version 6 (IPv6) suite.
# MLD is used by IPv6 routers for discovering multicast listeners on a directly attached link,
# much like Internet Group Management Protocol (IGMP) is used in IPv4.

#
# IPHTTPS (IP over HTTPS)
# https://en.wikipedia.org/wiki/IP-HTTPS
#

New-NetFirewallRule -DisplayName "IP over HTTPS" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service iphlpsvc -Program $ServiceHost -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Any `
	-LocalPort Any -RemotePort IPHTTPSout `
	-LocalUser Any `
	-InterfaceType $Interface `
	-Description "Allow IPHTTPS tunneling technology to provide connectivity across HTTP
proxies and firewalls.
IP over HTTPS is a Microsoft network tunneling protocol.
The IP-HTTPS protocol transports IPv6 packets across non-IPv6 networks.
It does a similar job as the earlier 6to4 or Teredo tunneling mechanisms." `
	@Logs | Format-Output @Logs

#
# IPv6 Encapsulation
# https://en.wikipedia.org/wiki/6to4
# https://en.wikipedia.org/wiki/ISATAP
#

New-NetFirewallRule -DisplayName "IPv6 Encapsulation" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol 41 `
	-LocalAddress Any -RemoteAddress Any `
	-LocalPort Any -RemotePort Any `
	-LocalUser $NT_AUTHORITY_System `
	-InterfaceType $Interface `
	-Description "Rule required to permit IPv6 traffic for
ISATAP (Intra-Site Automatic Tunnel Addressing Protocol) and 6to4 tunneling services.
ISATAP is an IPv6 transition mechanism meant to transmit IPv6 packets between dual-stack nodes on
top of an IPv4 network.
6to4 ia a system that allows IPv6 packets to be transmitted over an IPv4 network" `
	@Logs | Format-Output @Logs

#
# Teredo
# https://en.wikipedia.org/wiki/Teredo_tunneling
#

New-NetFirewallRule -DisplayName "Teredo" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service iphlpsvc -Program $ServiceHost -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress Any `
	-LocalPort Any -RemotePort 3544 `
	-LocalUser Any `
	-InterfaceType $Interface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Allow Teredo edge traversal, a technology that provides address assignment and
automatic tunneling for unicast IPv6 traffic when an IPv6/IPv4 host is located behind an IPv4
network address translator.
Teredo is a transition technology that gives full IPv6 connectivity for IPv6-capable hosts that are
on the IPv4 Internet but have no native connection to an IPv6 network.
Unlike similar protocols such as 6to4, it can perform its function even from behind network address
translation (NAT) devices such as home routers." `
	@Logs | Format-Output @Logs

Update-Log
