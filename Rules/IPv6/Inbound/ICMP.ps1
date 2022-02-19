
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
Inbound firewall rules for ICMPv6 traffic

.DESCRIPTION
Inbound firewall rules for ICMPv6 traffic

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\ICMP.ps1

.INPUTS
None. You cannot pipe objects to ICMP.ps1

.OUTPUTS
None. ICMP.ps1 does not generate any output

.NOTES
Make sure to check for updated content, see link in description

Type    Name
0   Reserved
1	Destination Unreachable
2	Packet Too Big
3	Time Exceeded
4	Parameter Problem
5-99	Unassigned
100	Private experimentation
101	Private experimentation
102-126	Unassigned
127	Reserved for expansion of ICMPv6 error messages
128	Echo Request
129	Echo Reply
130	Multicast Listener Query
131	Multicast Listener Report
132	Multicast Listener Done
133	Router Solicitation
134	Router Advertisement
135	Neighbor Solicitation
136	Neighbor Advertisement
137	Redirect Message
138	Router Renumbering
139	ICMP Node Information Query
140	ICMP Node Information Response
141	Inverse Neighbor Discovery Solicitation Message
142	Inverse Neighbor Discovery Advertisement Message
143	Version 2 Multicast Listener Report
144	Home Agent Address Discovery Request Message
145	Home Agent Address Discovery Reply Message
146	Mobile Prefix Solicitation
147	Mobile Prefix Advertisement
148	Certification Path Solicitation Message
149	Certification Path Advertisement Message
150	ICMP messages utilized by experimental mobility protocols such as Seamoby
151	Multicast Router Advertisement
152	Multicast Router Solicitation
153	Multicast Router Termination
154	FMIPv6 Messages
155	RPL Control Message
156	ILNPv6 Locator Update Message
157	Duplicate Address Request
158	Duplicate Address Confirmation
159	MPL Control Message
160	Extended Echo Request
161	Extended Echo Reply
162-199	Unassigned
200	Private experimentation
201	Private experimentation
255	Reserved for expansion of ICMPv6 informational messages

TODO: edge traversal unknown for some ICMPv6 rules
TODO: local and remote addresses need to be adjusted
TODO: add block rules based on remote address
TODO: add rule for ISATAP and 4to6

.LINK
https://www.iana.org/assignments/icmpv6-parameters/icmpv6-parameters.xhtml
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding()]
param (
	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\..\..\Config\ProjectSettings.ps1 $PSCmdlet
. $PSScriptRoot\DirectionSetup.ps1

Initialize-Project -Strict
Import-Module -Name Ruleset.UserInfo

# Setup local variables
$Group = "ICMPv6"
$LocalProfile = "Any"
# NOTE: Set to "Any" because combination of internet + localsubnet excludes non local private addresses
$RemoteAddr = "Any" # @("Internet6", "LocalSubnet6")
$RouterSpace = @("LocalSubnet6", "ff02::2", "fe80::/64") # Messages to/from router
$Description = "https://www.iana.org/assignments/icmpv6-parameters/icmpv6-parameters.xhtml"
# NOTE: we need Any to include IPv6 loopback interface because IPv6 loopback rule does not work on
# boot, (neither ::1 address nor interface alias)
$LocalInterface = "Any"
$Accept = "Inbound rules for ICMPv6 will be loaded, recommended for proper network functioning"
$Deny = "Skip operation, inbound ICMPv6 rules will not be loaded into firewall"

if (!(Approve-Execute -Accept $Accept -Deny $Deny -ContextLeaf $Group -Force:$Force)) { exit }
#endregion

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore

#
# ICMP Type filtering ( Error messages )
#

New-NetFirewallRule -DisplayName "Destination Unreachable (1)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program System -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol ICMPv6 -IcmpType 1 `
	-LocalAddress Any -RemoteAddress $RemoteAddr `
	-LocalPort Any -RemotePort Any `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Allow `
	-InterfaceType $LocalInterface `
	-Description "Destination Unreachable error messages are sent from any node that a packet
traverses which is unable to forward the packet for any reason except congestion. $Description" |
Format-RuleOutput

New-NetFirewallRule -DisplayName "Packet Too Big (2)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program System -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol ICMPv6 -IcmpType 2 `
	-LocalAddress Any -RemoteAddress $RemoteAddr `
	-LocalPort Any -RemotePort Any `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Allow `
	-InterfaceType $LocalInterface `
	-Description "Packet Too Big error messages are sent from any node that a packet traverses which
is unable to forward the packet because the packet is too large for the next link. $Description" |
Format-RuleOutput

New-NetFirewallRule -DisplayName "Time Exceeded (3)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program System -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol ICMPv6 -IcmpType 3 `
	-LocalAddress Any -RemoteAddress $RemoteAddr `
	-LocalPort Any -RemotePort Any `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Allow `
	-InterfaceType $LocalInterface `
	-Description "Time Exceeded error messages are generated from any node that a packet traverses
if the Hop Limit value is decremented to zero at any point on the path. $Description" |
Format-RuleOutput

New-NetFirewallRule -DisplayName "Parameter Problem (4)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program System -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol ICMPv6 -IcmpType 4 `
	-LocalAddress Any -RemoteAddress $RemoteAddr `
	-LocalPort Any -RemotePort Any `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Allow `
	-InterfaceType $LocalInterface `
	-Description "Parameter Problem error messages are sent by nodes as a result of incorrectly
generated packets. $Description" |
Format-RuleOutput

#
# ICMP Type filtering ( Informational messages )
#

New-NetFirewallRule -DisplayName "Echo Request (128)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program System -Group $Group `
	-Enabled True -Action Block -Direction $Direction -Protocol ICMPv6 -IcmpType 128 `
	-LocalAddress Any -RemoteAddress $RemoteAddr `
	-LocalPort Any -RemotePort Any `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Allow `
	-InterfaceType $LocalInterface `
	-Description "Echo Request messages are sent as ping requests to other nodes. $Description" |
Format-RuleOutput

New-NetFirewallRule -DisplayName "Echo Reply (129)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program System -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol ICMPv6 -IcmpType 129 `
	-LocalAddress Any -RemoteAddress $RemoteAddr `
	-LocalPort Any -RemotePort Any `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-InterfaceType $LocalInterface `
	-Description "Echo Reply messages are sent as a response to Echo Request pings. $Description" |
Format-RuleOutput

<#
The purpose of Multicast Listener Discovery (MLD) is to enable each
IPv6 router to discover the presence of multicast listeners (that is,
nodes wishing to receive multicast packets) on its directly attached
links, and to discover specifically which multicast addresses are of
interest to those neighboring nodes.
#>

New-NetFirewallRule -DisplayName "Multicast Listener Query (130)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program System -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol ICMPv6 -IcmpType 130 `
	-LocalAddress Any -RemoteAddress LocalSubnet6 `
	-LocalPort Any -RemotePort Any `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-InterfaceType $LocalInterface `
	-Description "An IPv6 multicast-capable router uses the Multicast Listener Query message to
query a link for multicast group membership. $Description" |
Format-RuleOutput

New-NetFirewallRule -DisplayName "Multicast Listener Report (131)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program System -Group $Group `
	-Enabled True -Action Block -Direction $Direction -Protocol ICMPv6 -IcmpType 131 `
	-LocalAddress Any -RemoteAddress LocalSubnet6 `
	-LocalPort Any -RemotePort Any `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-InterfaceType $LocalInterface `
	-Description "The Multicast Listener Report message is used by a listening node to either
immediately report its interest in receiving multicast traffic at a specific multicast address or
in response to a Multicast Listener Query. $Description" |
Format-RuleOutput

New-NetFirewallRule -DisplayName "Multicast Listener Done (132)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program System -Group $Group `
	-Enabled True -Action Block -Direction $Direction -Protocol ICMPv6 -IcmpType 132 `
	-LocalAddress Any -RemoteAddress LocalSubnet6 `
	-LocalPort Any -RemotePort Any `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-InterfaceType $LocalInterface `
	-Description "Multicast Listener Done messages inform local routers that there are no longer
any members remaining for a specific multicast address on the subnet. $Description" |
Format-RuleOutput

New-NetFirewallRule -DisplayName "Router Solicitation (133)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program System -Group $Group `
	-Enabled True -Action Block -Direction $Direction -Protocol ICMPv6 -IcmpType 133 `
	-LocalAddress Any -RemoteAddress $RouterSpace `
	-LocalPort Any -RemotePort Any `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-InterfaceType $LocalInterface `
	-Description "Router Solicitation messages are sent by nodes seeking routers to provide
stateless auto-configuration. $Description" |
Format-RuleOutput

New-NetFirewallRule -DisplayName "Router Advertisement (134)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program System -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol ICMPv6 -IcmpType 134 `
	-LocalAddress Any -RemoteAddress $RouterSpace `
	-LocalPort Any -RemotePort Any `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-InterfaceType $LocalInterface `
	-Description "Router Advertisement messages are sent by routers to other nodes for stateless
auto-configuration. $Description" |
Format-RuleOutput

New-NetFirewallRule -DisplayName "Neighbor Solicitation (135)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program System -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol ICMPv6 -IcmpType 135 `
	-LocalAddress Any -RemoteAddress $RemoteAddr `
	-LocalPort Any -RemotePort Any `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Allow `
	-InterfaceType $LocalInterface `
	-Description "Neighbor Discovery Solicitations are sent by nodes to discover the link-layer
address of another on-link IPv6 node. $Description" |
Format-RuleOutput

New-NetFirewallRule -DisplayName "Neighbor Advertisement (136)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program System -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol ICMPv6 -IcmpType 136 `
	-LocalAddress Any -RemoteAddress $RemoteAddr `
	-LocalPort Any -RemotePort Any `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Allow `
	-InterfaceType $LocalInterface `
	-Description "Neighbor Discovery Advertisement messages are sent by nodes to notify other nodes
of link-layer address changes or in response to a Neighbor Discovery Solicitation request. $Description" |
Format-RuleOutput

New-NetFirewallRule -DisplayName "Redirect Message (137)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol ICMPv6 -IcmpType 137 `
	-LocalAddress Any -RemoteAddress $RemoteAddr `
	-LocalPort Any -RemotePort Any `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-InterfaceType $LocalInterface `
	-Description "Routers send Redirect packets to inform a host of a better first-hop
node on the path to a destination. Hosts can be redirected to a
better first-hop router but can also be informed by a redirect that
the destination is in fact a neighbor." |
Format-RuleOutput

New-NetFirewallRule -DisplayName "Router Renumbering (138)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol ICMPv6 -IcmpType 138 `
	-LocalAddress Any -RemoteAddress $RouterSpace `
	-LocalPort Any -RemotePort Any `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-InterfaceType $LocalInterface `
	-Description $Description |
Format-RuleOutput

New-NetFirewallRule -DisplayName "ICMP Node Information Query (139)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol ICMPv6 -IcmpType 139 `
	-LocalAddress Any -RemoteAddress $RemoteAddr `
	-LocalPort Any -RemotePort Any `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-InterfaceType $LocalInterface `
	-Description "Used for IPv6 Node Information Queries.
a protocol for asking an IPv6 node to supply certain network information, such as its hostname or
fully-qualified domain name." |
Format-RuleOutput

New-NetFirewallRule -DisplayName "ICMP Node Information Response (140)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol ICMPv6 -IcmpType 140 `
	-LocalAddress Any -RemoteAddress $RemoteAddr `
	-LocalPort Any -RemotePort Any `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-InterfaceType $LocalInterface `
	-Description "Used for IPv6 Node Information Queries.
a protocol for asking an IPv6 node to supply certain network information, such as its hostname or
fully-qualified domain name." |
Format-RuleOutput

New-NetFirewallRule -DisplayName "Inverse Neighbor Discovery Solicitation Message (141)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol ICMPv6 -IcmpType 141 `
	-LocalAddress Any -RemoteAddress $RemoteAddr `
	-LocalPort Any -RemotePort Any `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Allow `
	-InterfaceType $LocalInterface `
	-Description $Description |
Format-RuleOutput

New-NetFirewallRule -DisplayName "Inverse Neighbor Discovery Advertisement Message (142)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol ICMPv6 -IcmpType 142 `
	-LocalAddress Any -RemoteAddress $RemoteAddr `
	-LocalPort Any -RemotePort Any `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Allow `
	-InterfaceType $LocalInterface `
	-Description $Description |
Format-RuleOutput

New-NetFirewallRule -DisplayName "Multicast Listener Report Version 2 (143)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program System -Group $Group `
	-Enabled True -Action Block -Direction $Direction -Protocol ICMPv6 -IcmpType 143 `
	-LocalAddress Any -RemoteAddress LocalSubnet6 `
	-LocalPort Any -RemotePort Any `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-InterfaceType $LocalInterface `
	-Description "Multicast Listener Report v2 message is used by a listening node to either
immediately report its interest in receiving multicast traffic at a specific multicast address or
in response to a Multicast Listener Query. $Description" |
Format-RuleOutput

# TODO: unknown if edge traversal is needed
New-NetFirewallRule -DisplayName "Home Agent Address Discovery Request Message (144)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol ICMPv6 -IcmpType 144 `
	-LocalAddress Any -RemoteAddress $RemoteAddr `
	-LocalPort Any -RemotePort Any `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-InterfaceType $LocalInterface `
	-Description "Used in Mobile IPv6, each mobile node is always identified by its home address,
regardless of its current point of attachment to the Internet.
The mobile node and the home agent SHOULD use an IPsec security association to protect the integrity
and authenticity of the Mobile Prefix Solicitations and Advertisements." |
Format-RuleOutput

New-NetFirewallRule -DisplayName "Home Agent Address Discovery Reply Message (145)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol ICMPv6 -IcmpType 145 `
	-LocalAddress Any -RemoteAddress $RemoteAddr `
	-LocalPort Any -RemotePort Any `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-InterfaceType $LocalInterface `
	-Description "Used in Mobile IPv6, each mobile node is always identified by its home address,
regardless of its current point of attachment to the Internet.
The mobile node and the home agent SHOULD use an IPsec security association to protect the integrity
and authenticity of the Mobile Prefix Solicitations and Advertisements." |
Format-RuleOutput

New-NetFirewallRule -DisplayName "Mobile Prefix Solicitation (146)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol ICMPv6 -IcmpType 146 `
	-LocalAddress Any -RemoteAddress $RemoteAddr `
	-LocalPort Any -RemotePort Any `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-InterfaceType $LocalInterface `
	-Description $Description |
Format-RuleOutput

New-NetFirewallRule -DisplayName "Mobile Prefix Advertisement (147)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol ICMPv6 -IcmpType 147 `
	-LocalAddress Any -RemoteAddress $RemoteAddr `
	-LocalPort Any -RemotePort Any `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-InterfaceType $LocalInterface `
	-Description $Description |
Format-RuleOutput

New-NetFirewallRule -DisplayName "Certification Path Solicitation Message (148)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol ICMPv6 -IcmpType 148 `
	-LocalAddress Any -RemoteAddress LocalSubnet6 `
	-LocalPort Any -RemotePort Any `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-InterfaceType $LocalInterface `
	-Description "Hosts send Certification Path Solicitations in order to prompt
routers to generate Certification Path Advertisements.

Source Address:
A link-local unicast address assigned to the sending interface,
or to the unspecified address if no address is assigned to the
sending interface.

Destination Address:
Typically the All-Routers multicast address, the Solicited-Node
multicast address, or the address of the host's default router." |
Format-RuleOutput

New-NetFirewallRule -DisplayName "Certification Path Advertisement Message (149)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol ICMPv6 -IcmpType 149 `
	-LocalAddress Any -RemoteAddress LocalSubnet6 `
	-LocalPort Any -RemotePort Any `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-InterfaceType $LocalInterface `
	-Description "Routers send out Certification Path Advertisement messages in
response to a Certification Path Solicitation.

Source Address:
A link-local unicast address assigned to the interface from
which this message is sent. Note that routers may use multiple
addresses, and therefore this address is not sufficient for the
unique identification of routers.

Destination Address:
Either the Solicited-Node multicast address of the receiver or
the link-scoped All-Nodes multicast address." |
Format-RuleOutput

New-NetFirewallRule -DisplayName "ICMP messages utilized by experimental mobility protocols such as Seamoby (150)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol ICMPv6 -IcmpType 150 `
	-LocalAddress Any -RemoteAddress $RemoteAddr `
	-LocalPort Any -RemotePort Any `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-InterfaceType $LocalInterface `
	-Description $Description |
Format-RuleOutput

New-NetFirewallRule -DisplayName "Multicast Router Advertisement (151)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol ICMPv6 -IcmpType 151 `
	-LocalAddress Any -RemoteAddress $RouterSpace `
	-LocalPort Any -RemotePort Any `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-InterfaceType $LocalInterface `
	-Description $Description |
Format-RuleOutput

New-NetFirewallRule -DisplayName "Multicast Router Solicitation (152)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol ICMPv6 -IcmpType 152 `
	-LocalAddress Any -RemoteAddress $RouterSpace `
	-LocalPort Any -RemotePort Any `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-InterfaceType $LocalInterface `
	-Description $Description |
Format-RuleOutput

New-NetFirewallRule -DisplayName "Multicast Router Termination (153)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol ICMPv6 -IcmpType 153 `
	-LocalAddress Any -RemoteAddress $RouterSpace `
	-LocalPort Any -RemotePort Any `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-InterfaceType $LocalInterface `
	-Description $Description |
Format-RuleOutput

# TODO: go figure out if edge traversal is needed.
New-NetFirewallRule -DisplayName "FMIPv6 Messages (154)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol ICMPv6 -IcmpType 154 `
	-LocalAddress Any -RemoteAddress $RemoteAddr `
	-LocalPort Any -RemotePort Any `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-InterfaceType $LocalInterface `
	-Description "Fast Mobile IPv6,
Mobile IPv6 enables a mobile node (MN) to maintain its connectivity
to the Internet when moving from one Access Router to another, a process referred to as handover." |
Format-RuleOutput

New-NetFirewallRule -DisplayName "RPL Control Message (155)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol ICMPv6 -IcmpType 155 `
	-LocalAddress Any -RemoteAddress $RemoteAddr `
	-LocalPort Any -RemotePort Any `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-InterfaceType $LocalInterface `
	-Description "RPL: IPv6 Routing Protocol for Low-Power and Lossy Networks
Most RPL control messages have the scope of a link.
The only exception is for the DAO / DAO-ACK messages in Non-Storing mode,
which are exchanged using a unicast address over multiple hops and thus uses global or unique-local
addresses for both the source and destination addresses.

For all other RPL control messages, the source address is a link-local address,
and the destination address is either the all-RPL-nodes multicast address or a link-local unicast
address of the destination.
The all-RPL-nodes multicast address is a new address with a value of ff02::1a." |
Format-RuleOutput

New-NetFirewallRule -DisplayName "ILNPv6 Locator Update Message (156)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol ICMPv6 -IcmpType 156 `
	-LocalAddress Any -RemoteAddress $RemoteAddr `
	-LocalPort Any -RemotePort Any `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-InterfaceType $LocalInterface `
	-Description "The Identifier-Locator Network Protocol (ILNP) is an experimental, evolutionary
enhancement to IP.
This message is used to dynamically update Identifier/Locator bindings for an existing ILNP
session." |
Format-RuleOutput

<#
A personal area network (PAN) is a computer network for interconnecting devices centered on an
individual person's workspace.
A PAN provides data transmission among devices such as computers, smartphones, tablets and personal
digital assistants.
PANs can be used for communication among the personal devices themselves,
or for connecting to a higher level network and the Internet where one master device takes up the
role as gateway.

PAN may be wireless or carried over wired interfaces such as USB.
A wireless personal area network (WPAN) is a PAN carried over a low-powered,
short-distance wireless network technology such as IrDA, Wireless USB, Bluetooth or ZigBee.
The reach of a WPAN varies from a few centimeters to a few meters.
#>

New-NetFirewallRule -DisplayName "Duplicate Address Request (157)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol ICMPv6 -IcmpType 157 `
	-LocalAddress Any -RemoteAddress LocalSubnet6 `
	-LocalPort Any -RemotePort Any `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-InterfaceType $LocalInterface `
	-Description "Used in IPv6 over Low-Power Wireless Personal Area Networks (6LoWPANs)
IPv6 Source:
A non-link-local address of the sending router.

IPv6 Destination:
In a Duplicate Address Request (DAR), a non-link-local address of a 6LBR.
In a Duplicate Address Confirmation (DAC), this is just the source from the DAR." |
Format-RuleOutput

New-NetFirewallRule -DisplayName "Duplicate Address Confirmation (158)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol ICMPv6 -IcmpType 158 `
	-LocalAddress Any -RemoteAddress LocalSubnet6 `
	-LocalPort Any -RemotePort Any `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-InterfaceType $LocalInterface `
	-Description "Used in IPv6 over Low-Power Wireless Personal Area Networks (6LoWPANs)
IPv6 Source:
A non-link-local address of the sending router.

IPv6 Destination:
In a Duplicate Address Request (DAR), a non-link-local address of a 6LBR.
In a Duplicate Address Confirmation (DAC), this is just the source from the DAR." |
Format-RuleOutput

New-NetFirewallRule -DisplayName "MPL Control Message (159)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Domain `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol ICMPv6 -IcmpType 159 `
	-LocalAddress Any -RemoteAddress Intranet `
	-LocalPort Any -RemotePort Any `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-InterfaceType $LocalInterface `
	-Description "Multicast Protocol for Low-Power and Lossy Networks (MPL).
MPL makes use of MPL Domain Addresses to identify MPL Interfaces of an MPL Domain.
By default, MPL Forwarders subscribe to the ALL_MPL_FORWARDERS multicast address with Realm-Local
scope (scopvalue 3).

For each MPL Domain Address that an MPL Interface subscribes to, the MPL Interface MUST also
subscribe to the MPL Domain Address with Link-Local scope (scop value 2) when reactive forwarding is
in use." |
Format-RuleOutput

New-NetFirewallRule -DisplayName "Extended Echo Request (160)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Block -Direction $Direction -Protocol ICMPv6 -IcmpType 160 `
	-LocalAddress Any -RemoteAddress $RemoteAddr `
	-LocalPort Any -RemotePort Any `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-InterfaceType $LocalInterface `
	-Description $Description |
Format-RuleOutput

New-NetFirewallRule -DisplayName "Extended Echo Reply (161)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol ICMPv6 -IcmpType 161 `
	-LocalAddress Any -RemoteAddress $RemoteAddr `
	-LocalPort Any -RemotePort Any `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Allow `
	-InterfaceType $LocalInterface `
	-Description $Description |
Format-RuleOutput

if ($UpdateGPO)
{
	Invoke-Process gpupdate.exe -NoNewWindow -ArgumentList "/target:computer"
}

Update-Log
