
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2021 metablaster zebal@protonmail.ch

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

.PARAMETER Force
If specified, no prompt to run script is shown.

.PARAMETER Trusted
If specified, rules will be loaded for executables with missing or invalid digital signature.
By default an error is generated and rule isn't loaded.

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

# Check requirements
Initialize-Project -Strict

# Imports
. $PSScriptRoot\DirectionSetup.ps1
Import-Module -Name Ruleset.UserInfo

# Setup local variables
$Group = "Core Networking - IPv4"
$LocalProfile = "Any"
$Accept = "Inbound rules for core networking will be loaded, required for proper network funcioning"
$Deny = "Skip operation, inbound core networking rules will not be loaded into firewall"

# User prompt
Update-Context "IPv$IPVersion" $Direction $Group
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
$PSDefaultParameterValues["Test-ExecutableFile:Force"] = $Trusted -or $SkipSignatureCheck
#endregion

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore

#
# Loopback
# Used on TCP, UDP, IGMP
#

# TODO: is there a need or valid reason to make rules for "this machine"? (0.0.0.0)
# TODO: should we use -InterfaceAlias set to Loopback pseudo interface?
New-NetFirewallRule -DisplayName "Loopback" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol Any `
	-LocalAddress Any -RemoteAddress 127.0.0.1 `
	-LocalPort Any -RemotePort Any `
	-LocalUser Any -EdgeTraversalPolicy Block `
	-InterfaceType Any `
	-Description "Network software and utilities use loopback address to access a local computer's
TCP/IP network resources." | Format-Output

New-NetFirewallRule -DisplayName "Loopback" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol Any `
	-LocalAddress 127.0.0.1 -RemoteAddress Any `
	-LocalPort Any -RemotePort Any `
	-LocalUser Any -EdgeTraversalPolicy Block `
	-InterfaceType Any `
	-Description "Network software and utilities use loopback address to access a local computer's
TCP/IP network resources." | Format-Output

#
# mDNS (Multicast Domain Name System)
# NOTE: this should be placed in Multicast.ps1 like it is for IPv6, but it's here because of specific address,
# which is part of "Local Network Control Block" (224.0.0.0 - 224.0.0.255)
# An mDNS message is a multicast UDP packet sent using the following addressing:
# IPv4 address 224.0.0.251 or IPv6 address ff02::fb
# UDP port 5353
# https://en.wikipedia.org/wiki/Multicast_DNS
#
if ($false)
{
	# NOTE: Not applied because now handled by IPv4 multicast rules
	New-NetFirewallRule -DisplayName "Multicast DNS" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile Private, Domain `
		-Service Any -Program Any -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
		-LocalAddress 224.0.0.251 -RemoteAddress LocalSubnet4 `
		-LocalPort 5353 -RemotePort 5353 `
		-LocalUser Any -EdgeTraversalPolicy Block `
		-InterfaceType $DefaultInterface `
		-LocalOnlyMapping $false -LooseSourceMapping $false `
		-Description "In computer networking, the multicast DNS (mDNS) protocol resolves hostnames
to IP addresses within small networks that do not include a local name server.
It is a zero-configuration service, using essentially the same programming interfaces,
packet formats and operating semantics as the unicast Domain Name System (DNS)." | Format-Output

	New-NetFirewallRule -DisplayName "Multicast DNS" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile Public `
		-Service Any -Program Any -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
		-LocalAddress 224.0.0.251 -RemoteAddress LocalSubnet4 `
		-LocalPort 5353 -RemotePort 5353 `
		-LocalUser Any -EdgeTraversalPolicy Block `
		-InterfaceType $DefaultInterface `
		-LocalOnlyMapping $false -LooseSourceMapping $false `
		-Description "In computer networking, the multicast DNS (mDNS) protocol resolves hostnames
to IP addresses within small networks that do not include a local name server.
It is a zero-configuration service, using essentially the same programming interfaces,
packet formats and operating semantics as the unicast Domain Name System (DNS)." | Format-Output
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
	-InterfaceType $DefaultInterface -EdgeTraversalPolicy Block `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Allow DHCPv4 messages for stateful auto-configuration.
UDP port number 67 is the destination port of a server, and UDP port number 68 is used by the client." |
Format-Output

New-NetFirewallRule -DisplayName "DHCP Client (Discovery)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Any `
	-Service Dhcp -Program $ServiceHost -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress 255.255.255.255 -RemoteAddress Any `
	-LocalPort 68 -RemotePort 67 `
	-LocalUser Any `
	-InterfaceType $DefaultInterface -EdgeTraversalPolicy Block `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "The DHCP client broadcasts a DHCPDISCOVER message on the network subnet using
the destination address 255.255.255.255 (limited broadcast) or
the specific subnet broadcast address (directed broadcast).
In response to the DHCP offer, the client replies with a DHCPREQUEST message,
broadcast to the server, requesting the offered address." |
Format-Output

New-NetFirewallRule -DisplayName "DHCP Server" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Any `
	-Service Dhcp -Program $ServiceHost -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress 255.255.255.255 -RemoteAddress Any `
	-LocalPort 67 -RemotePort 68 `
	-LocalUser Any `
	-InterfaceType $DefaultInterface -EdgeTraversalPolicy Block `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "The DHCP client broadcasts a DHCPDISCOVER message on the network subnet using
the destination address 255.255.255.255 (limited broadcast) or
the specific subnet broadcast address (directed broadcast).
In response to the DHCP offer, the client replies with a DHCPREQUEST message,
broadcast to the server, requesting the offered address." |
Format-Output

#
# IGMP (Internet Group Management Protocol)
#

New-NetFirewallRule -DisplayName "Internet Group Management Protocol" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program System -Group $Group `
	-Enabled True -Action Allow `
	-Direction $Direction -Protocol 2 -LocalAddress Any -RemoteAddress LocalSubnet4 `
	-LocalPort Any -RemotePort Any `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-InterfaceType $DefaultInterface `
	-Description "IGMP messages are sent and received by nodes to create,
join and depart multicast groups." | Format-Output

Update-Log
