
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2022 metablaster zebal@protonmail.ch

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
Outbound firewall rules for core networking

.DESCRIPTION
Predefined rules from Core Networking are here excluding ICMP

.PARAMETER Trusted
If specified, rules will be loaded for executables with missing or invalid digital signature.
By default an error is generated and rule isn't loaded.

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\CoreNetworking.ps1

.INPUTS
None. You cannot pipe objects to CoreNetworking.ps1

.OUTPUTS
None. CoreNetworking.ps1 does not generate any output

.NOTES
TODO: specifying -InterfaceAlias $Loopback does not work, dropped packets
NOTE: even though we specify "IPv4 the loopback interface alias is the same for IPv4 and IPv6,
meaning there is only one loopback interface!"
$Loopback = Get-NetIPInterface | Where-Object {
	$_.InterfaceAlias -like "*Loopback*" -and $_.AddressFamily -eq "IPv4"
} | Select-Object -ExpandProperty InterfaceAlias
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding()]
param (
	[Parameter()]
	[switch] $Trusted,

	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\..\..\Config\ProjectSettings.ps1 $PSCmdlet
. $PSScriptRoot\DirectionSetup.ps1

Initialize-Project -Strict
Import-Module -Name Ruleset.UserInfo
#
# Setup local variables
$Group = "Core Networking - IPv4"
$LocalProfile = "Any"
$Accept = "Outbound rules for core networking will be loaded, required for proper network funcioning"
$Deny = "Skip operation, outbound core networking rules will not be loaded into firewall"

if (!(Approve-Execute -Accept $Accept -Deny $Deny -ContextLeaf $Group -Force:$Force)) { exit }
$PSDefaultParameterValues["Test-ExecutableFile:Force"] = $Trusted -or $SkipSignatureCheck
#endregion

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore

#
# Loopback
# Used on TCP, UDP, IGMP
#

New-NetFirewallRule -DisplayName "Loopback" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol Any `
	-LocalAddress Any -RemoteAddress 127.0.0.1 `
	-LocalPort Any -RemotePort Any `
	-LocalUser Any `
	-InterfaceType Any `
	-Description "Network software and utilities use loopback address to access a local computer's
TCP/IP network resources." |
Format-RuleOutput

New-NetFirewallRule -DisplayName "Loopback" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol Any `
	-LocalAddress 127.0.0.1 -RemoteAddress Any `
	-LocalPort Any -RemotePort Any `
	-LocalUser Any `
	-InterfaceType Any `
	-Description "Network software and utilities use loopback address to access a local computer's
TCP/IP network resources." |
Format-RuleOutput

#
# DNS (Domain Name System)
#

# TODO: official rule uses loose source mapping
New-NetFirewallRule -DisplayName "DNS Client" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Dnscache -Program $ServiceHost -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress DNS4 `
	-LocalPort Any -RemotePort 53 `
	-LocalUser Any `
	-InterfaceType $DefaultInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $true `
	-Description "Allow DNS (Domain Name System) requests.
DNS responses based on requests that matched this rule will be permitted regardless of source
address.
This behavior is classified as loose source mapping." |
Format-RuleOutput

New-NetFirewallRule -DisplayName "DNS Client" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Dnscache -Program $ServiceHost -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress DNS4 `
	-LocalPort Any -RemotePort 53 `
	-LocalUser Any `
	-InterfaceType $DefaultInterface `
	-Description "Allow DNS (Domain Name System) requests over TCP.
DNS responses based on requests that matched this rule will be permitted regardless of source
address.
This behavior is classified as loose source mapping." |
Format-RuleOutput

New-NetFirewallRule -DisplayName "Domain Name System" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program System -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress DefaultGateway4 `
	-LocalPort Any -RemotePort 53 `
	-LocalUser $LocalSystem `
	-InterfaceType $DefaultInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Allow DNS (Domain Name System) requests by System to default gateway." |
Format-RuleOutput

#
# mDNS (Multicast Domain Name System)
# NOTE: this should be placed in Multicast.ps1 like it is for IPv6, but it's here because of
# specific address, which is part of "Local Network Control Block" (224.0.0.0 - 224.0.0.255)
# mDNS message is a multicast UDP packet sent using the following addressing:
# IPv4 address 224.0.0.251 or IPv6 address ff02::fb
# UDP port 5353
# https://en.wikipedia.org/wiki/Multicast_DNS
# TODO: both IPv4 and IPv6 have some dropped packets, need to test if LooseSourceMapping
# would make any difference with LocalOnlyMapping
# NOTE: Multiple programs may require mDNS, not just dnscache
#
if ($false)
{
	# NOTE: Not applied because now handled by IPv4 multicast rules
	New-NetFirewallRule -DisplayName "Multicast DNS" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile Private, Domain `
		-Service Any -Program Any -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
		-LocalAddress Any -RemoteAddress 224.0.0.251 `
		-LocalPort 5353 -RemotePort 5353 `
		-LocalUser Any `
		-InterfaceType $DefaultInterface `
		-LocalOnlyMapping $false -LooseSourceMapping $false `
		-Description "In computer networking, the multicast DNS (mDNS) protocol resolves hostnames
to IP addresses within small networks that do not include a local name server.
It is a zero-configuration service, using essentially the same programming interfaces,
packet formats and operating semantics as the unicast Domain Name System (DNS)." |
	Format-RuleOutput

	# TODO: $PhysicalAdapters = Get-InterfaceAlias IPv4 -InterfaceAlias $PhysicalAdapters
	# NOTE: Specifying interface or local port might not work for public profile
	New-NetFirewallRule -DisplayName "Multicast DNS" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile Public `
		-Service Any -Program Any -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
		-LocalAddress Any -RemoteAddress 224.0.0.251 `
		-LocalPort Any -RemotePort 5353 `
		-LocalUser Any `
		-InterfaceType Any `
		-LocalOnlyMapping $false -LooseSourceMapping $false `
		-Description "In computer networking, the multicast DNS (mDNS) protocol resolves hostnames
to IP addresses within small networks that do not include a local name server.
It is a zero-configuration service, using essentially the same programming interfaces,
packet formats and operating semantics as the unicast Domain Name System (DNS)." |
	Format-RuleOutput
}

#
# DHCP (Dynamic Host Configuration Protocol)
# https://tools.ietf.org/html/rfc2131
#

New-NetFirewallRule -DisplayName "DHCP Client" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Dhcp -Program $ServiceHost -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress DHCP4 `
	-LocalPort 68 -RemotePort 67 `
	-LocalUser Any `
	-InterfaceType $DefaultInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Allow DHCPv4 messages for stateful auto-configuration.
UDP port number 67 is the destination port of a server, and UDP port number 68 is used by the client." |
Format-RuleOutput

New-NetFirewallRule -DisplayName "DHCP Client (Discovery)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Any `
	-Service Dhcp -Program $ServiceHost -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress 255.255.255.255 `
	-LocalPort 68 -RemotePort 67 `
	-LocalUser Any `
	-InterfaceType $DefaultInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "The DHCP client broadcasts a DHCPDISCOVER message on the network subnet using
the destination address 255.255.255.255 (limited broadcast) or
the specific subnet broadcast address (directed broadcast).
In response to the DHCP offer, the client replies with a DHCPREQUEST message, broadcast to the server,
requesting the offered address." |
Format-RuleOutput

New-NetFirewallRule -DisplayName "DHCP Server" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Any `
	-Service Dhcp -Program $ServiceHost -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress 255.255.255.255 `
	-LocalPort 67 -RemotePort 68 `
	-LocalUser Any `
	-InterfaceType $DefaultInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "When a DHCP server receives a DHCPDISCOVER message from a client, which is an IP
address lease request, the DHCP server reserves an IP address for the client and makes a lease offer
by sending a DHCPOFFER message to the client" |
Format-RuleOutput

#
# IGMP (Internet Group Management Protocol)
# NOTE: Address 224.0.0.0/24 removed because now handled by IPv4 multicast rules
#

New-NetFirewallRule -DisplayName "Internet Group Management Protocol" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program System -Group $Group `
	-Enabled True -Action Allow `
	-Direction $Direction -Protocol 2 -LocalAddress Any -RemoteAddress LocalSubnet4 `
	-LocalPort Any -RemotePort Any `
	-LocalUser $LocalSystem `
	-InterfaceType $DefaultInterface `
	-Description "IGMP messages are sent and received by nodes to create,
join and depart multicast groups." |
Format-RuleOutput

if ($UpdateGPO)
{
	Invoke-Process gpupdate.exe -NoNewWindow -ArgumentList "/target:computer"
}

Update-Log
