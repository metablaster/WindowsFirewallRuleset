
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

# Make sure to check for updated content!
#http://www.iana.org/assignments/icmpv6-parameters/icmpv6-parameters.xhtml


<#
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
#>

# TODO: edge traversal unknown for some ICMPv6 rules
# TODO: local and remote addresses need to be adjusted
# TODO: add block rules based on remote address
# TODO: add rule for ISATAP and 4to6

. $PSScriptRoot\..\..\..\Config\ProjectSettings.ps1

# Check requirements for this project
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.System
Test-SystemRequirements

# Includes
. $PSScriptRoot\DirectionSetup.ps1
. $PSScriptRoot\..\IPSetup.ps1
Import-Module -Name $ProjectRoot\Modules\Project.Windows.UserInfo
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Logging
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Utility

#
# Setup local variables:
#
$Group = "ICMPv6"
$Profile = "Any"
$RemoteAddr = @("Internet6", "LocalSubnet6")
$RouterSpace = @("LocalSubnet6", "ff02::2", "fe80::/64") # Messages to/from router
$Description = "https://www.iana.org/assignments/icmpv6-parameters/icmpv6-parameters.xhtml"
# NOTE: we need Any to include IPv6 loopback interface because IPv6 loopback rule does not work on boot, (neither ::1 address nor interface alias)
$ICMPInterface = "Any"

# Ask user if he wants to load these rules
Update-Context "IPv$IPVersion" $Direction $Group @Logs
if (!(Approve-Execute @Logs)) { exit }

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction SilentlyContinue

#
# ICMP Type filtering ( Error messages )
#

New-NetFirewallRule -Platform $Platform `
-DisplayName "Destination Unreachable (1)" -Service Any -Program System `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $ICMPInterface `
-Direction $Direction -Protocol ICMPv6 -IcmpType 1 -LocalAddress Any -RemoteAddress $RemoteAddr -LocalPort Any -RemotePort Any `
-EdgeTraversalPolicy Allow -Localuser $NT_AUTHORITY_System `
-Description $Description @Logs | Format-Output @Logs

New-NetFirewallRule -Platform $Platform `
-DisplayName "Packet Too Big (2)" -Service Any -Program System `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $ICMPInterface `
-Direction $Direction -Protocol ICMPv6 -IcmpType 2 -LocalAddress Any -RemoteAddress $RemoteAddr -LocalPort Any -RemotePort Any `
-EdgeTraversalPolicy Allow -Localuser $NT_AUTHORITY_System `
-Description $Description @Logs | Format-Output @Logs

New-NetFirewallRule -Platform $Platform `
-DisplayName "Time Exceeded (3)" -Service Any -Program System `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $ICMPInterface `
-Direction $Direction -Protocol ICMPv6 -IcmpType 3 -LocalAddress Any -RemoteAddress $RemoteAddr -LocalPort Any -RemotePort Any `
-EdgeTraversalPolicy Allow -Localuser $NT_AUTHORITY_System `
-Description $Description @Logs | Format-Output @Logs

New-NetFirewallRule -Platform $Platform `
-DisplayName "Parameter Problem (4)" -Service Any -Program System `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $ICMPInterface `
-Direction $Direction -Protocol ICMPv6 -IcmpType 4 -LocalAddress Any -RemoteAddress $RemoteAddr -LocalPort Any -RemotePort Any `
-EdgeTraversalPolicy Allow -Localuser $NT_AUTHORITY_System `
-Description $Description @Logs | Format-Output @Logs

#
# ICMP Type filtering ( Informational messages )
#

New-NetFirewallRule -Platform $Platform `
-DisplayName "Echo Request (128)" -Service Any -Program System `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $ICMPInterface `
-Direction $Direction -Protocol ICMPv6 -IcmpType 128 -LocalAddress Any -RemoteAddress $RemoteAddr -LocalPort Any -RemotePort Any `
-EdgeTraversalPolicy Allow -Localuser $NT_AUTHORITY_System `
-Description $Description @Logs | Format-Output @Logs

New-NetFirewallRule -Platform $Platform `
-DisplayName "Echo Reply (129)" -Service Any -Program System `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $ICMPInterface `
-Direction $Direction -Protocol ICMPv6 -IcmpType 129 -LocalAddress Any -RemoteAddress $RemoteAddr -LocalPort Any -RemotePort Any `
-EdgeTraversalPolicy Block -Localuser $NT_AUTHORITY_System `
-Description $Description @Logs | Format-Output @Logs

<#
The purpose of Multicast Listener Discovery (MLD) is to enable each
IPv6 router to discover the presence of multicast listeners (that is,
nodes wishing to receive multicast packets) on its directly attached
links, and to discover specifically which multicast addresses are of
interest to those neighboring nodes.
#>

New-NetFirewallRule -Platform $Platform `
-DisplayName "Multicast Listener Query (130)" -Service Any -Program System `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $ICMPInterface `
-Direction $Direction -Protocol ICMPv6 -IcmpType 130 -LocalAddress Any -RemoteAddress LocalSubnet6 -LocalPort Any -RemotePort Any `
-EdgeTraversalPolicy Block -Localuser $NT_AUTHORITY_System `
-Description $Description @Logs | Format-Output @Logs

New-NetFirewallRule -Platform $Platform `
-DisplayName "Multicast Listener Report (131)" -Service Any -Program System `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $ICMPInterface `
-Direction $Direction -Protocol ICMPv6 -IcmpType 131 -LocalAddress Any -RemoteAddress LocalSubnet6 -LocalPort Any -RemotePort Any `
-EdgeTraversalPolicy Block -Localuser $NT_AUTHORITY_System `
-Description $Description @Logs | Format-Output @Logs

New-NetFirewallRule -Platform $Platform `
-DisplayName "Multicast Listener Done (132)" -Service Any -Program System `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $ICMPInterface `
-Direction $Direction -Protocol ICMPv6 -IcmpType 132 -LocalAddress Any -RemoteAddress LocalSubnet6 -LocalPort Any -RemotePort Any `
-EdgeTraversalPolicy Block -Localuser $NT_AUTHORITY_System `
-Description $Description @Logs | Format-Output @Logs

New-NetFirewallRule -Platform $Platform `
-DisplayName "Router Solicitation (133)" -Service Any -Program System `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $ICMPInterface `
-Direction $Direction -Protocol ICMPv6 -IcmpType 133 -LocalAddress Any -RemoteAddress $RouterSpace -LocalPort Any -RemotePort Any `
-EdgeTraversalPolicy Block -Localuser $NT_AUTHORITY_System `
-Description $Description @Logs | Format-Output @Logs

New-NetFirewallRule -Platform $Platform `
-DisplayName "Router Advertisement (134)" -Service Any -Program System `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $ICMPInterface `
-Direction $Direction -Protocol ICMPv6 -IcmpType 134 -LocalAddress Any -RemoteAddress $RouterSpace -LocalPort Any -RemotePort Any `
-EdgeTraversalPolicy Block -Localuser $NT_AUTHORITY_System `
-Description $Description @Logs | Format-Output @Logs

New-NetFirewallRule -Platform $Platform `
-DisplayName "Neighbor Solicitation (135)" -Service Any -Program System `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $ICMPInterface `
-Direction $Direction -Protocol ICMPv6 -IcmpType 135 -LocalAddress Any -RemoteAddress $RemoteAddr -LocalPort Any -RemotePort Any `
-EdgeTraversalPolicy Allow -Localuser $NT_AUTHORITY_System `
-Description $Description @Logs | Format-Output @Logs

New-NetFirewallRule -Platform $Platform `
-DisplayName "Neighbor Advertisement (136)" -Service Any -Program System `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $ICMPInterface `
-Direction $Direction -Protocol ICMPv6 -IcmpType 136 -LocalAddress Any -RemoteAddress $RemoteAddr -LocalPort Any -RemotePort Any `
-EdgeTraversalPolicy Allow -Localuser $NT_AUTHORITY_System `
-Description $Description @Logs | Format-Output @Logs

New-NetFirewallRule -Platform $Platform `
-DisplayName "Redirect Message (137)" -Service Any -Program System `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $ICMPInterface `
-Direction $Direction -Protocol ICMPv6 -IcmpType 137 -LocalAddress Any -RemoteAddress $RemoteAddr -LocalPort Any -RemotePort Any `
-EdgeTraversalPolicy Block -Localuser $NT_AUTHORITY_System `
-Description "Routers send Redirect packets to inform a host of a better first-hop
node on the path to a destination.  Hosts can be redirected to a
better first-hop router but can also be informed by a redirect that
the destination is in fact a neighbor." @Logs | Format-Output @Logs

New-NetFirewallRule -Platform $Platform `
-DisplayName "Router Renumbering (138)" -Service Any -Program System `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $ICMPInterface `
-Direction $Direction -Protocol ICMPv6 -IcmpType 138 -LocalAddress Any -RemoteAddress $RouterSpace -LocalPort Any -RemotePort Any `
-EdgeTraversalPolicy Block -Localuser $NT_AUTHORITY_System `
-Description $Description @Logs | Format-Output @Logs

New-NetFirewallRule -Platform $Platform `
-DisplayName "ICMP Node Information Query (139)" -Service Any -Program System `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $ICMPInterface `
-Direction $Direction -Protocol ICMPv6 -IcmpType 139 -LocalAddress Any -RemoteAddress $RemoteAddr -LocalPort Any -RemotePort Any `
-EdgeTraversalPolicy Block -Localuser $NT_AUTHORITY_System `
-Description "Used for IPv6 Node Information Queries.
a protocol for asking an IPv6 node to supply certain network information, such as its hostname or fully-qualified domain name." @Logs | Format-Output @Logs

New-NetFirewallRule -Platform $Platform `
-DisplayName "ICMP Node Information Response (140)" -Service Any -Program System `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $ICMPInterface `
-Direction $Direction -Protocol ICMPv6 -IcmpType 140 -LocalAddress Any -RemoteAddress $RemoteAddr -LocalPort Any -RemotePort Any `
-EdgeTraversalPolicy Block -Localuser $NT_AUTHORITY_System `
-Description "Used for IPv6 Node Information Queries.
a protocol for asking an IPv6 node to supply certain network information, such as its hostname or fully-qualified domain name." @Logs | Format-Output @Logs

New-NetFirewallRule -Platform $Platform `
-DisplayName "Inverse Neighbor Discovery Solicitation Message (141)" -Service Any -Program System `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $ICMPInterface `
-Direction $Direction -Protocol ICMPv6 -IcmpType 141 -LocalAddress Any -RemoteAddress $RemoteAddr -LocalPort Any -RemotePort Any `
-EdgeTraversalPolicy Allow -Localuser $NT_AUTHORITY_System `
-Description $Description @Logs | Format-Output @Logs

New-NetFirewallRule -Platform $Platform `
-DisplayName "Inverse Neighbor Discovery Advertisement Message (142)" -Service Any -Program System `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $ICMPInterface `
-Direction $Direction -Protocol ICMPv6 -IcmpType 142 -LocalAddress Any -RemoteAddress $RemoteAddr -LocalPort Any -RemotePort Any `
-EdgeTraversalPolicy Allow -Localuser $NT_AUTHORITY_System `
-Description $Description @Logs | Format-Output @Logs

New-NetFirewallRule -Platform $Platform `
-DisplayName "Multicast Listener Report Version 2 (143)" -Service Any -Program System `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $ICMPInterface `
-Direction $Direction -Protocol ICMPv6 -IcmpType 143 -LocalAddress Any -RemoteAddress LocalSubnet6 -LocalPort Any -RemotePort Any `
-EdgeTraversalPolicy Block -Localuser $NT_AUTHORITY_System `
-Description $Description @Logs | Format-Output @Logs

# TODO: unknown if edge traversal is needed
New-NetFirewallRule -Platform $Platform `
-DisplayName "Home Agent Address Discovery Request Message (144)" -Service Any -Program System `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $ICMPInterface `
-Direction $Direction -Protocol ICMPv6 -IcmpType 144 -LocalAddress Any -RemoteAddress $RemoteAddr -LocalPort Any -RemotePort Any `
-EdgeTraversalPolicy Block -Localuser $NT_AUTHORITY_System `
-Description "Used in Mobile IPv6, each mobile node is always identified by its home address,
regardless of its current point of attachment to the Internet.
The mobile node and the home agent SHOULD use an IPsec security association to protect the integrity and authenticity
of the Mobile Prefix Solicitations and Advertisements." @Logs | Format-Output @Logs

New-NetFirewallRule -Platform $Platform `
-DisplayName "Home Agent Address Discovery Reply Message (145)" -Service Any -Program System `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $ICMPInterface `
-Direction $Direction -Protocol ICMPv6 -IcmpType 145 -LocalAddress Any -RemoteAddress $RemoteAddr -LocalPort Any -RemotePort Any `
-EdgeTraversalPolicy Block -Localuser $NT_AUTHORITY_System `
-Description "Used in Mobile IPv6, each mobile node is always identified by its home address,
regardless of its current point of attachment to the Internet.
The mobile node and the home agent SHOULD use an IPsec security association to protect the integrity and authenticity
of the Mobile Prefix Solicitations and Advertisements." @Logs | Format-Output @Logs

New-NetFirewallRule -Platform $Platform `
-DisplayName "Mobile Prefix Solicitation (146)" -Service Any -Program System `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $ICMPInterface `
-Direction $Direction -Protocol ICMPv6 -IcmpType 146 -LocalAddress Any -RemoteAddress $RemoteAddr -LocalPort Any -RemotePort Any `
-EdgeTraversalPolicy Block -Localuser $NT_AUTHORITY_System `
-Description $Description @Logs | Format-Output @Logs

New-NetFirewallRule -Platform $Platform `
-DisplayName "Mobile Prefix Advertisement (147)" -Service Any -Program System `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $ICMPInterface `
-Direction $Direction -Protocol ICMPv6 -IcmpType 147 -LocalAddress Any -RemoteAddress $RemoteAddr -LocalPort Any -RemotePort Any `
-EdgeTraversalPolicy Block -Localuser $NT_AUTHORITY_System `
-Description $Description @Logs | Format-Output @Logs

New-NetFirewallRule -Platform $Platform `
-DisplayName "Certification Path Solicitation Message (148)" -Service Any -Program System `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $ICMPInterface `
-Direction $Direction -Protocol ICMPv6 -IcmpType 148 -LocalAddress Any -RemoteAddress LocalSubnet6 -LocalPort Any -RemotePort Any `
-EdgeTraversalPolicy Block -Localuser $NT_AUTHORITY_System `
-Description "Hosts send Certification Path Solicitations in order to prompt
routers to generate Certification Path Advertisements.

Source Address:
A link-local unicast address assigned to the sending interface,
or to the unspecified address if no address is assigned to the
sending interface.

Destination Address:
Typically the All-Routers multicast address, the Solicited-Node
multicast address, or the address of the host's default router." @Logs | Format-Output @Logs

New-NetFirewallRule -Platform $Platform `
-DisplayName "Certification Path Advertisement Message (149)" -Service Any -Program System `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $ICMPInterface `
-Direction $Direction -Protocol ICMPv6 -IcmpType 149 -LocalAddress Any -RemoteAddress LocalSubnet6 -LocalPort Any -RemotePort Any `
-EdgeTraversalPolicy Block -Localuser $NT_AUTHORITY_System `
-Description "Routers send out Certification Path Advertisement messages in
response to a Certification Path Solicitation.

Source Address:
A link-local unicast address assigned to the interface from
which this message is sent.  Note that routers may use multiple
addresses, and therefore this address is not sufficient for the
unique identification of routers.

Destination Address:
Either the Solicited-Node multicast address of the receiver or
the link-scoped All-Nodes multicast address." @Logs | Format-Output @Logs

New-NetFirewallRule -Platform $Platform `
-DisplayName "ICMP messages utilized by experimental mobility protocols such as Seamoby (150)" -Service Any -Program System `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $ICMPInterface `
-Direction $Direction -Protocol ICMPv6 -IcmpType 150 -LocalAddress Any -RemoteAddress $RemoteAddr -LocalPort Any -RemotePort Any `
-EdgeTraversalPolicy Block -Localuser $NT_AUTHORITY_System `
-Description $Description @Logs | Format-Output @Logs

New-NetFirewallRule -Platform $Platform `
-DisplayName "Multicast Router Advertisement (151)" -Service Any -Program System `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $ICMPInterface `
-Direction $Direction -Protocol ICMPv6 -IcmpType 151 -LocalAddress Any -RemoteAddress $RouterSpace -LocalPort Any -RemotePort Any `
-EdgeTraversalPolicy Block -Localuser $NT_AUTHORITY_System `
-Description $Description @Logs | Format-Output @Logs

New-NetFirewallRule -Platform $Platform `
-DisplayName "Multicast Router Solicitation (152)" -Service Any -Program System `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $ICMPInterface `
-Direction $Direction -Protocol ICMPv6 -IcmpType 152 -LocalAddress Any -RemoteAddress $RouterSpace -LocalPort Any -RemotePort Any `
-EdgeTraversalPolicy Block -Localuser $NT_AUTHORITY_System `
-Description $Description @Logs | Format-Output @Logs

New-NetFirewallRule -Platform $Platform `
-DisplayName "Multicast Router Termination (153)" -Service Any -Program System `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $ICMPInterface `
-Direction $Direction -Protocol ICMPv6 -IcmpType 153 -LocalAddress Any -RemoteAddress $RouterSpace -LocalPort Any -RemotePort Any `
-EdgeTraversalPolicy Block -Localuser $NT_AUTHORITY_System `
-Description $Description @Logs | Format-Output @Logs

# TODO: go figure out if edge traversal is needed.
New-NetFirewallRule -Platform $Platform `
-DisplayName "FMIPv6 Messages (154)" -Service Any -Program System `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $ICMPInterface `
-Direction $Direction -Protocol ICMPv6 -IcmpType 154 -LocalAddress Any -RemoteAddress $RemoteAddr -LocalPort Any -RemotePort Any `
-EdgeTraversalPolicy Block -Localuser $NT_AUTHORITY_System `
-Description "Fast Mobile IPv6,
Mobile IPv6 enables a mobile node (MN) to maintain its connectivity
to the Internet when moving from one Access Router to another, a process referred to as handover." @Logs | Format-Output @Logs

New-NetFirewallRule -Platform $Platform `
-DisplayName "RPL Control Message (155)" -Service Any -Program System `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $ICMPInterface `
-Direction $Direction -Protocol ICMPv6 -IcmpType 155 -LocalAddress Any -RemoteAddress $RemoteAddr -LocalPort Any -RemotePort Any `
-EdgeTraversalPolicy Block -Localuser $NT_AUTHORITY_System `
-Description "RPL: IPv6 Routing Protocol for Low-Power and Lossy Networks
Most RPL control messages have the scope of a link.
The only exception is for the DAO / DAO-ACK messages in Non-Storing mode,
which are exchanged using a unicast address over multiple hops and thus uses global or unique-local addresses
for both the source and destination addresses.

For all other RPL control messages, the source address is a link-local address,
and the destination address is either the all-RPL-nodes multicast address or a link-local unicast address of the destination.
The all-RPL-nodes multicast address is a new address with a value of ff02::1a." @Logs | Format-Output @Logs

New-NetFirewallRule -Platform $Platform `
-DisplayName "ILNPv6 Locator Update Message (156)" -Service Any -Program System `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $ICMPInterface `
-Direction $Direction -Protocol ICMPv6 -IcmpType 156 -LocalAddress Any -RemoteAddress $RemoteAddr -LocalPort Any -RemotePort Any `
-EdgeTraversalPolicy Block -Localuser $NT_AUTHORITY_System `
-Description "The Identifier-Locator Network Protocol (ILNP) is an experimental, evolutionary enhancement to IP.
This message is used to dynamically update Identifier/Locator bindings for an existing ILNP session." @Logs | Format-Output @Logs

<#
A personal area network (PAN) is a computer network for interconnecting devices centered on an individual person's workspace.
A PAN provides data transmission among devices such as computers, smartphones, tablets and personal digital assistants.
PANs can be used for communication among the personal devices themselves,
or for connecting to a higher level network and the Internet where one master device takes up the role as gateway.

PAN may be wireless or carried over wired interfaces such as USB.
A wireless personal area network (WPAN) is a PAN carried over a low-powered,
short-distance wireless network technology such as IrDA, Wireless USB, Bluetooth or ZigBee.
The reach of a WPAN varies from a few centimeters to a few meters.
#>

New-NetFirewallRule -Platform $Platform `
-DisplayName "Duplicate Address Request (157)" -Service Any -Program System `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $ICMPInterface `
-Direction $Direction -Protocol ICMPv6 -IcmpType 157 -LocalAddress Any -RemoteAddress LocalSubnet6 -LocalPort Any -RemotePort Any `
-EdgeTraversalPolicy Block -Localuser $NT_AUTHORITY_System `
-Description "Used in IPv6 over Low-Power Wireless Personal Area Networks (6LoWPANs)
IPv6 Source:
A non-link-local address of the sending router.

IPv6 Destination:
In a Duplicate Address Request (DAR), a non-link-local address of a 6LBR.
In a Duplicate Address Confirmation (DAC), this is just the source from the DAR." @Logs | Format-Output @Logs

New-NetFirewallRule -Platform $Platform `
-DisplayName "Duplicate Address Confirmation (158)" -Service Any -Program System `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $ICMPInterface `
-Direction $Direction -Protocol ICMPv6 -IcmpType 158 -LocalAddress Any -RemoteAddress LocalSubnet6 -LocalPort Any -RemotePort Any `
-EdgeTraversalPolicy Block -Localuser $NT_AUTHORITY_System `
-Description "Used in IPv6 over Low-Power Wireless Personal Area Networks (6LoWPANs)
IPv6 Source:
A non-link-local address of the sending router.

IPv6 Destination:
In a Duplicate Address Request (DAR), a non-link-local address of a 6LBR.
In a Duplicate Address Confirmation (DAC), this is just the source from the DAR." @Logs | Format-Output @Logs

New-NetFirewallRule -Platform $Platform `
-DisplayName "MPL Control Message (159)" -Service Any -Program System `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile Domain -InterfaceType $ICMPInterface `
-Direction $Direction -Protocol ICMPv6 -IcmpType 159 -LocalAddress Any -RemoteAddress Intranet -LocalPort Any -RemotePort Any `
-EdgeTraversalPolicy Block -Localuser $NT_AUTHORITY_System `
-Description "Multicast Protocol for Low-Power and Lossy Networks (MPL).
MPL makes use of MPL Domain Addresses to identify MPL Interfaces of an MPL Domain.
By default, MPL Forwarders subscribe to the ALL_MPL_FORWARDERS multicast address with Realm-Local scope (scopvalue 3).

For each MPL Domain Address that an MPL Interface subscribes to, the MPL Interface MUST also subscribe to the MPL Domain Address with
Link-Local scope (scop value 2) when reactive forwarding is in use." @Logs | Format-Output @Logs

New-NetFirewallRule -Platform $Platform `
-DisplayName "Extended Echo Request (160)" -Service Any -Program System `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $ICMPInterface `
-Direction $Direction -Protocol ICMPv6 -IcmpType 160 -LocalAddress Any -RemoteAddress $RemoteAddr -LocalPort Any -RemotePort Any `
-EdgeTraversalPolicy Block -Localuser $NT_AUTHORITY_System `
-Description $Description @Logs | Format-Output @Logs

New-NetFirewallRule -Platform $Platform `
-DisplayName "Extended Echo Reply (161)" -Service Any -Program System `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $ICMPInterface `
-Direction $Direction -Protocol ICMPv6 -IcmpType 161 -LocalAddress Any -RemoteAddress $RemoteAddr -LocalPort Any -RemotePort Any `
-EdgeTraversalPolicy Allow -Localuser $NT_AUTHORITY_System `
-Description $Description @Logs | Format-Output @Logs

Update-Logs
