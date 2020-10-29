
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
Import-Module -Name Project.AllPlatforms.Logging
Import-Module -Name Project.Windows.UserInfo
#
# Setup local variables
$Group = "Basic Networking - IPv4"
$FirewallProfile = "Any"
$Accept = "Outbound rules for basic networking will be loaded, required for proper network funcioning"
$Deny = "Skip operation, outbound basic networking rules will not be loaded into firewall"

# User prompt
Update-Context "IPv$IPVersion" $Direction $Group @Logs
if (!(Approve-Execute -Accept $Accept -Deny $Deny @Logs)) { exit }

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore @Logs

# TODO: specifying -InterfaceAlias $Loopback does not work, dropped packets
# NOTE: even though we specify "IPv4 the loopback interface alias is the same for for IPv4 and IPv6,
# meaning there is only one loopback interface!"
# $Loopback = Get-NetIPInterface | Where-Object {
# 	$_.InterfaceAlias -like "*Loopback*" -and $_.AddressFamily -eq "IPv4"
# } | Select-Object -ExpandProperty InterfaceAlias

#
# Predefined rules from Core Networking are here
#

#
# Loopback
# Used on TCP, UDP, IGMP
#

New-NetFirewallRule -DisplayName "Loopback" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol Any `
	-LocalAddress Any -RemoteAddress 127.0.0.1 `
	-LocalPort Any -RemotePort Any `
	-LocalUser Any `
	-InterfaceType Any `
	-Description "Network software and utilities use loopback address to access a local computer's
TCP/IP network resources." `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Loopback" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol Any `
	-LocalAddress 127.0.0.1 -RemoteAddress Any `
	-LocalPort Any -RemotePort Any `
	-LocalUser Any `
	-InterfaceType Any `
	-Description "Network software and utilities use loopback address to access a local computer's
TCP/IP network resources." `
	@Logs | Format-Output @Logs

#
# DNS (Domain Name System)
#

# TODO: official rule uses loose source mapping
New-NetFirewallRule -DisplayName "Domain Name System" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Dnscache -Program $ServiceHost -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress DNS4 `
	-LocalPort Any -RemotePort 53 `
	-LocalUser Any `
	-InterfaceType $Interface `
	-LocalOnlyMapping $false -LooseSourceMapping $true `
	-Description "Allow DNS requests.
DNS responses based on requests that matched this rule will be permitted regardless of source
address.
This behavior is classified as loose source mapping." `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Domain Name System" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Any -Program System -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress DefaultGateway4 `
	-LocalPort Any -RemotePort 53 `
	-LocalUser $NT_AUTHORITY_System `
	-InterfaceType $Interface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Allow DNS requests by System to default gateway." `
	@Logs | Format-Output @Logs

#
# mDNS (Multicast Domain Name System)
# NOTE: this should be placed in Multicast.ps1 like it is for IPv6, but it's here because of
# specific address, which is part of "Local Network Control Block" (224.0.0.0 - 224.0.0.255)
# mDNS message is a multicast UDP packet sent using the following addressing:
# IPv4 address 224.0.0.251 or IPv6 address ff02::fb
# UDP port 5353
# https://en.wikipedia.org/wiki/Multicast_DNS
# TODO: both IPv4 and IPv6 have some dropped packets, need to test if LooseSourceMapping or
# would make any difference LocalOnlyMapping
#

New-NetFirewallRule -DisplayName "Multicast Domain Name System" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private, Domain `
	-Service Dnscache -Program $ServiceHost -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress 224.0.0.251 `
	-LocalPort 5353 -RemotePort 5353 `
	-LocalUser Any `
	-InterfaceType $Interface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "In computer networking, the multicast DNS (mDNS) protocol resolves hostnames to
IP addresses
within small networks that do not include a local name server.
It is a zero-configuration service, using essentially the same programming interfaces,
packet formats and operating semantics as the unicast Domain Name System (DNS)." `
	@Logs | Format-Output @Logs

# TODO: $PhysicalAdapters = Get-InterfaceAlias IPv4
# -InterfaceAlias $PhysicalAdapters
New-NetFirewallRule -DisplayName "Multicast Domain Name System" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Public `
	-Service Dnscache -Program $ServiceHost -Group $Group `
	-Enabled True -Action Block -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress 224.0.0.251 `
	-LocalPort 5353 -RemotePort 5353 `
	-LocalUser Any `
	-InterfaceType $Interface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "In computer networking, the multicast DNS (mDNS) protocol resolves hostnames to
IP addresses
within small networks that do not include a local name server.
It is a zero-configuration service, using essentially the same programming interfaces,
packet formats and operating semantics as the unicast Domain Name System (DNS)." `
	@Logs | Format-Output @Logs

#
# DHCP (Dynamic Host Configuration Protocol)
#

New-NetFirewallRule -DisplayName "DHCP Client" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Dhcp -Program $ServiceHost -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress DHCP4 `
	-LocalPort 68 -RemotePort 67 `
	-LocalUser Any `
	-InterfaceType $Interface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Allow DHCPv4 messages for stateful auto-configuration.
UDP port number 67 is the destination port of a server, and UDP port number 68 is used by the client." `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "DHCP Client (Discovery)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Any `
	-Service Dhcp -Program $ServiceHost -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress 255.255.255.255 `
	-LocalPort 68 -RemotePort 67 `
	-LocalUser Any `
	-InterfaceType $Interface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "The DHCP client broadcasts a DHCPDISCOVER message on the network subnet using
the destination address 255.255.255.255 (limited broadcast) or
the specific subnet broadcast address (directed broadcast).
In response to the DHCP offer, the client replies with a DHCPREQUEST message, broadcast to the server,
requesting the offered address." `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "DHCP Server" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Any `
	-Service Dhcp -Program $ServiceHost -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress 255.255.255.255 `
	-LocalPort 67 -RemotePort 68 `
	-LocalUser Any `
	-InterfaceType $Interface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "When a DHCP server receives a DHCPDISCOVER message from a client, which is an IP
address lease request, the DHCP server reserves an IP address for the client and makes a lease offer
by sending a DHCPOFFER message to the client" `
	@Logs | Format-Output @Logs

#
# IGMP (Internet Group Management Protocol)
#

New-NetFirewallRule -DisplayName "Internet Group Management Protocol" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Any -Program System -Group $Group `
	-Enabled True -Action Allow `
	-Direction $Direction -Protocol 2 -LocalAddress Any -RemoteAddress LocalSubnet4, 224.0.0.0/24 `
	-LocalPort Any -RemotePort Any `
	-LocalUser $NT_AUTHORITY_System `
	-InterfaceType $Interface `
	-Description "IGMP messages are sent and received by nodes to create,
join and depart multicast groups." `
	@Logs | Format-Output @Logs

#
# IPHTTPS (IPv4 over HTTPS)
#

New-NetFirewallRule -DisplayName "IPv4 over HTTPS" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort IPHTTPSout `
	-LocalUser $NT_AUTHORITY_System `
	-InterfaceType $Interface `
	-Description "Allow IPv4 IPHTTPS tunneling technology to provide connectivity across HTTP
proxies and firewalls." `
	@Logs | Format-Output @Logs

#
# Teredo
#

New-NetFirewallRule -DisplayName "Teredo" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service iphlpsvc -Program $ServiceHost -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort 3544 `
	-LocalUser Any `
	-InterfaceType $Interface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Allow Teredo edge traversal, a technology that provides address assignment and
automatic tunneling for unicast IPv6 traffic when an IPv6/IPv4 host is located behind an IPv4
network address translator." `
	@Logs | Format-Output @Logs

Update-Log
