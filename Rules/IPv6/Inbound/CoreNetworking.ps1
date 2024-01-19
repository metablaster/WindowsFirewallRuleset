
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2024 metablaster zebal@protonmail.ch

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
Inbound firewall rules for core networking

.DESCRIPTION
Predefined rules from Core Networking are here excluding ICMP

.PARAMETER Domain
Computer name onto which to deploy rules

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\CoreNetworking.ps1

.INPUTS
None. You cannot pipe objects to CoreNetworking.ps1

.OUTPUTS
None. CoreNetworking.ps1 does not generate any output

.NOTES
None.
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding()]
param (
	[Parameter()]
	[Alias("ComputerName", "CN")]
	[string] $Domain = [System.Environment]::MachineName,

	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\..\..\Config\ProjectSettings.ps1 $PSCmdlet -Domain $Domain
Initialize-Project
. $PSScriptRoot\DirectionSetup.ps1

Import-Module -Name Ruleset.UserInfo

# Setup local variables
$Group = "Core Networking - IPv6"
$LocalProfile = "Any"
$Accept = "Inbound rules for IPv6 core networking will be loaded, required for proper network functioning"
$Deny = "Skip operation, inbound IPv6 core networking rules will not be loaded into firewall"
if (!(Approve-Execute -Accept $Accept -Deny $Deny -ContextLeaf $Group -Force:$Force)) { exit }
#endregion

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore

#
# Loop back
# TODO: why specifying IPv6 loopback address ::1/128 doesn't work?
# NOTE: even though we specify "IPv6 the loopback interface, interface alias is the same for IPv4
# and IPv6, meaning there is only one loopback interface and this rule applies to both IPv6 and IPv6"
if ($false)
{
	# HACK: Specifying loopback interface alias doesn't make IPv6 loopback traffic go trough
	# NOTE: Current workaround is to set InterfaceType to Any for IPv6 multicast rules
	$Loopback = Get-NetIPInterface | Where-Object {
		$_.InterfaceAlias -like "*Loopback*" -and $_.AddressFamily -eq "IPv6"
	} | Select-Object -ExpandProperty InterfaceAlias

	New-NetFirewallRule -DisplayName "Loopback IP" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
		-Service Any -Program Any -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol Any `
		-LocalAddress Any -RemoteAddress Any `
		-LocalPort Any -RemotePort Any `
		-LocalUser Any -EdgeTraversalPolicy Block `
		-InterfaceType Any -InterfaceAlias $Loopback `
		-Description "Due to limitations of "Windows Firewall with Advanced Security", this rule applies
to both IPv4 and IPv6 loopback traffic by allowing all traffic on loopback interface.
Network software and utilities use loopback address to access a local computer's TCP/IP network
resources." |
	Format-RuleOutput
}

#
# mDNS (Multicast Domain Name System)
# NOTE: this should be placed in Multicast.ps1 like it is for IPv6, but it's here because of
# specific address, which is part of "Local Network Control Block" (224.0.0.0 - 224.0.0.255)
# An mDNS message is a multicast UDP packet sent using the following addressing:
# IPv4 address 224.0.0.251 or IPv6 address ff02::fb
# UDP port 5353
# https://en.wikipedia.org/wiki/Multicast_DNS
#
if ($false)
{
	# NOTE: Not applied because now handled by IPv6 multicast rules
	New-NetFirewallRule -DisplayName "Multicast DNS" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile Private, Domain `
		-Service Any -Program Any -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
		-LocalAddress ff02::fb -RemoteAddress LocalSubnet6 `
		-LocalPort 5353 -RemotePort 5353 `
		-LocalUser Any -EdgeTraversalPolicy Block `
		-InterfaceType $DefaultInterface `
		-LocalOnlyMapping $false -LooseSourceMapping $false `
		-Description "In computer networking, the multicast DNS (mDNS) protocol resolves hostnames
to IP addresses within small networks that do not include a local name server.
It is a zero-configuration service, using essentially the same programming interfaces,
packet formats and operating semantics as the unicast Domain Name System (DNS)." |
	Format-RuleOutput

	New-NetFirewallRule -DisplayName "Multicast DNS" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile Public `
		-Service Any -Program Any -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
		-LocalAddress ff02::fb -RemoteAddress LocalSubnet6 `
		-LocalPort 5353 -RemotePort 5353 `
		-LocalUser Any -EdgeTraversalPolicy Block `
		-InterfaceType $DefaultInterface `
		-LocalOnlyMapping $false -LooseSourceMapping $false `
		-Description "In computer networking, the multicast DNS (mDNS) protocol resolves hostnames
to IP addresses within small networks that do not include a local name server.
It is a zero-configuration service, using essentially the same programming interfaces,
packet formats and operating semantics as the unicast Domain Name System (DNS)." |
	Format-RuleOutput
}

#
# DHCP (Dynamic Host Configuration Protocol)
# TODO: Need a rule for DHCP server
# https://tools.ietf.org/html/rfc8415
#

New-NetFirewallRule -DisplayName "DHCP Client" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Dhcp -Program $ServiceHost -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress DHCP6 `
	-LocalPort 546 -RemotePort 547 `
	-LocalUser Any -EdgeTraversalPolicy Block `
	-InterfaceType $DefaultInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Dynamic Host Configuration Protocol (DHCP) allows DHCPv6 messages for stateful
auto-configuration." |
Format-RuleOutput

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

New-NetFirewallRule -DisplayName "IPv4 over HTTPS" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Any `
	-LocalPort IPHTTPSIn -RemotePort Any `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-InterfaceType $DefaultInterface `
	-Description "Allow IPHTTPS tunneling technology to provide connectivity across HTTP
proxies and firewalls.
IP over HTTPS is a Microsoft network tunneling protocol.
The IP-HTTPS protocol transports IPv6 packets across non-IPv6 networks.
It does a similar job as the earlier 6to4 or Teredo tunneling mechanisms." |
Format-RuleOutput

#
# IPv6 Encapsulation
# https://en.wikipedia.org/wiki/6to4
# https://en.wikipedia.org/wiki/ISATAP
#

# TODO: edge traversal is missing
New-NetFirewallRule -DisplayName "IPv6 Encapsulation" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol 41 `
	-LocalAddress Any -RemoteAddress Any `
	-LocalPort Any -RemotePort Any `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-InterfaceType $DefaultInterface `
	-Description "Rule required to permit IPv6 traffic for
ISATAP (Intra-Site Automatic Tunnel Addressing Protocol) and 6to4 tunneling services.
ISATAP is an IPv6 transition mechanism meant to transmit IPv6 packets between dual-stack nodes on
top of an IPv4 network.
6to4 ia a system that allows IPv6 packets to be transmitted over an IPv4 network" |
Format-RuleOutput

#
# Teredo
# https://en.wikipedia.org/wiki/Teredo_tunneling
#

New-NetFirewallRule -DisplayName "Teredo" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service iphlpsvc -Program $ServiceHost -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress Any `
	-LocalPort Teredo -RemotePort Any `
	-LocalUser Any -EdgeTraversalPolicy Block `
	-InterfaceType $DefaultInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Allow Teredo edge traversal, a technology that provides address assignment and
automatic tunneling for unicast IPv6 traffic when an IPv6/IPv4 host is located behind an IPv4
network address translator.
Teredo is a transition technology that gives full IPv6 connectivity for IPv6-capable hosts that are
on the IPv4 Internet but have no native connection to an IPv6 network.
Unlike similar protocols such as 6to4, it can perform its function even from behind network address
translation (NAT) devices such as home routers." |
Format-RuleOutput

if ($UpdateGPO)
{
	Invoke-Process gpupdate.exe
	Disconnect-Computer -Domain $Domain
}

Update-Log
