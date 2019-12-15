
<#
MIT License

Copyright (c) 2019 metablaster zebal@protonmail.ch

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

#
# Import global variables
#
. "$PSScriptRoot\..\..\Modules\GlobalVariables.ps1"

# Ask user if he wants to load these rules
if (!(RunThis)) { exit }

#
# Setup local variables:
#
$Group = "ICMPv6"
$Interface = "Wired, Wireless"
$Profile = "Any"
$RemoteAddr = @("Internet6", "LocalSubnet6")
$RouterSpace = @("LocalSubnet6", "ff02::2", "fe80::/64") # Messages to/from router
$Description = "https://www.iana.org/assignments/icmpv6-parameters/icmpv6-parameters.xhtml"

#First remove all existing rules matching setup
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction Outbound -ErrorAction SilentlyContinue

#
# ICMP Type filtering ( Error messages )
#

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "Destination Unreachable (1)" -Service Any -Program System `
-Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol ICMPv6 -IcmpType 1 -LocalAddress Any -RemoteAddress $RemoteAddr -LocalPort Any -RemotePort Any `
-Localuser $NT_AUTHORITY_System `
-Description $Description

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "Packet Too Big (2)" -Service Any -Program System `
-Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol ICMPv6 -IcmpType 2 -LocalAddress Any -RemoteAddress $RemoteAddr -LocalPort Any -RemotePort Any `
-Localuser $NT_AUTHORITY_System `
-Description $Description

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "Time Exceeded (3)" -Service Any -Program System `
-Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol ICMPv6 -IcmpType 3 -LocalAddress Any -RemoteAddress $RemoteAddr -LocalPort Any -RemotePort Any `
-Localuser $NT_AUTHORITY_System `
-Description $Description

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "Parameter Problem (4)" -Service Any -Program System `
-Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol ICMPv6 -IcmpType 4 -LocalAddress Any -RemoteAddress $RemoteAddr -LocalPort Any -RemotePort Any `
-Localuser $NT_AUTHORITY_System `
-Description $Description

#
# ICMP Type filtering ( Informational messages )
#

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "Echo Request (128)" -Service Any -Program System `
-Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol ICMPv6 -IcmpType 128 -LocalAddress Any -RemoteAddress $RemoteAddr -LocalPort Any -RemotePort Any `
-Localuser $NT_AUTHORITY_System `
-Description $Description

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "Echo Reply (129)" -Service Any -Program System `
-Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol ICMPv6 -IcmpType 129 -LocalAddress Any -RemoteAddress $RemoteAddr -LocalPort Any -RemotePort Any `
-Localuser $NT_AUTHORITY_System `
-Description $Description

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "Multicast Listener Query (130)" -Service Any -Program System `
-Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol ICMPv6 -IcmpType 130 -LocalAddress Any -RemoteAddress LocalSubnet6 -LocalPort Any -RemotePort Any `
-Localuser $NT_AUTHORITY_System `
-Description $Description

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "Multicast Listener Report (131)" -Service Any -Program System `
-Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol ICMPv6 -IcmpType 131 -LocalAddress Any -RemoteAddress LocalSubnet6 -LocalPort Any -RemotePort Any `
-Localuser $NT_AUTHORITY_System `
-Description $Description

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "Multicast Listener Done (132)" -Service Any -Program System `
-Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol ICMPv6 -IcmpType 132 -LocalAddress Any -RemoteAddress LocalSubnet6 -LocalPort Any -RemotePort Any `
-Localuser $NT_AUTHORITY_System `
-Description $Description

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "Router Solicitation (133)" -Service Any -Program System `
-Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol ICMPv6 -IcmpType 133 -LocalAddress Any -RemoteAddress $RouterSpace -LocalPort Any -RemotePort Any `
-Localuser $NT_AUTHORITY_System `
-Description $Description

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "Router Advertisement (134)" -Service Any -Program System `
-Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol ICMPv6 -IcmpType 134 -LocalAddress fe80::/64 -RemoteAddress $RouterSpace -LocalPort Any -RemotePort Any `
-Localuser $NT_AUTHORITY_System `
-Description $Description

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "Neighbor Solicitation (135)" -Service Any -Program System `
-Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol ICMPv6 -IcmpType 135 -LocalAddress Any -RemoteAddress $RemoteAddr -LocalPort Any -RemotePort Any `
-Localuser $NT_AUTHORITY_System `
-Description $Description

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "Neighbor Advertisement (136)" -Service Any -Program System `
-Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol ICMPv6 -IcmpType 136 -LocalAddress Any -RemoteAddress $RemoteAddr -LocalPort Any -RemotePort Any `
-Localuser $NT_AUTHORITY_System `
-Description $Description

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "Redirect Message (137)" -Service Any -Program System `
-Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol ICMPv6 -IcmpType 137 -LocalAddress Any -RemoteAddress $RemoteAddr -LocalPort Any -RemotePort Any `
-Localuser $NT_AUTHORITY_System `
-Description $Description

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "Router Renumbering (138)" -Service Any -Program System `
-Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol ICMPv6 -IcmpType 138 -LocalAddress Any -RemoteAddress $RouterSpace -LocalPort Any -RemotePort Any `
-Localuser $NT_AUTHORITY_System `
-Description $Description

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "ICMP Node Information Query (139)" -Service Any -Program System `
-Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol ICMPv6 -IcmpType 139 -LocalAddress Any -RemoteAddress $RemoteAddr -LocalPort Any -RemotePort Any `
-Localuser $NT_AUTHORITY_System `
-Description $Description

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "ICMP Node Information Response (140)" -Service Any -Program System `
-Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol ICMPv6 -IcmpType 140 -LocalAddress Any -RemoteAddress $RemoteAddr -LocalPort Any -RemotePort Any `
-Localuser $NT_AUTHORITY_System `
-Description $Description

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "Inverse Neighbor Discovery Solicitation Message (141)" -Service Any -Program System `
-Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol ICMPv6 -IcmpType 141 -LocalAddress Any -RemoteAddress $RemoteAddr -LocalPort Any -RemotePort Any `
-Localuser $NT_AUTHORITY_System `
-Description $Description

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "Inverse Neighbor Discovery Advertisement Message (142)" -Service Any -Program System `
-Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol ICMPv6 -IcmpType 142 -LocalAddress Any -RemoteAddress $RemoteAddr -LocalPort Any -RemotePort Any `
-Localuser $NT_AUTHORITY_System `
-Description $Description

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "Version 2 Multicast Listener Report (143)" -Service Any -Program System `
-Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol ICMPv6 -IcmpType 143 -LocalAddress Any -RemoteAddress LocalSubnet6 -LocalPort Any -RemotePort Any `
-Localuser $NT_AUTHORITY_System `
-Description $Description

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "Home Agent Address Discovery Request Message (144)" -Service Any -Program System `
-Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol ICMPv6 -IcmpType 144 -LocalAddress Any -RemoteAddress $RemoteAddr -LocalPort Any -RemotePort Any `
-Localuser $NT_AUTHORITY_System `
-Description $Description

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "Home Agent Address Discovery Reply Message (145)" -Service Any -Program System `
-Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol ICMPv6 -IcmpType 145 -LocalAddress Any -RemoteAddress $RemoteAddr -LocalPort Any -RemotePort Any `
-Localuser $NT_AUTHORITY_System `
-Description $Description

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "Mobile Prefix Solicitation (146)" -Service Any -Program System `
-Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol ICMPv6 -IcmpType 146 -LocalAddress Any -RemoteAddress $RemoteAddr -LocalPort Any -RemotePort Any `
-Localuser $NT_AUTHORITY_System `
-Description $Description

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "Mobile Prefix Advertisement (147)" -Service Any -Program System `
-Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol ICMPv6 -IcmpType 147 -LocalAddress Any -RemoteAddress $RemoteAddr -LocalPort Any -RemotePort Any `
-Localuser $NT_AUTHORITY_System `
-Description $Description

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "Certification Path Solicitation Message (148)" -Service Any -Program System `
-Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol ICMPv6 -IcmpType 148 -LocalAddress Any -RemoteAddress $RemoteAddr -LocalPort Any -RemotePort Any `
-Localuser $NT_AUTHORITY_System `
-Description $Description

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "Certification Path Advertisement Message (149)" -Service Any -Program System `
-Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol ICMPv6 -IcmpType 149 -LocalAddress Any -RemoteAddress $RemoteAddr -LocalPort Any -RemotePort Any `
-Localuser $NT_AUTHORITY_System `
-Description $Description

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "ICMP messages utilized by experimental mobility protocols such as Seamoby (150)" -Service Any -Program System `
-Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol ICMPv6 -IcmpType 150 -LocalAddress Any -RemoteAddress $RemoteAddr -LocalPort Any -RemotePort Any `
-Localuser $NT_AUTHORITY_System `
-Description $Description

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "Multicast Router Advertisement (151)" -Service Any -Program System `
-Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol ICMPv6 -IcmpType 151 -LocalAddress Any -RemoteAddress $RouterSpace -LocalPort Any -RemotePort Any `
-Localuser $NT_AUTHORITY_System `
-Description $Description

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "Multicast Router Solicitation (152)" -Service Any -Program System `
-Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol ICMPv6 -IcmpType 152 -LocalAddress Any -RemoteAddress $RouterSpace -LocalPort Any -RemotePort Any `
-Localuser $NT_AUTHORITY_System `
-Description $Description

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "Multicast Router Termination (153)" -Service Any -Program System `
-Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol ICMPv6 -IcmpType 153 -LocalAddress Any -RemoteAddress $RouterSpace -LocalPort Any -RemotePort Any `
-Localuser $NT_AUTHORITY_System `
-Description $Description

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "FMIPv6 Messages (154)" -Service Any -Program System `
-Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol ICMPv6 -IcmpType 154 -LocalAddress Any -RemoteAddress $RemoteAddr -LocalPort Any -RemotePort Any `
-Localuser $NT_AUTHORITY_System `
-Description $Description

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "RPL Control Message (155)" -Service Any -Program System `
-Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol ICMPv6 -IcmpType 155 -LocalAddress Any -RemoteAddress $RemoteAddr -LocalPort Any -RemotePort Any `
-Localuser $NT_AUTHORITY_System `
-Description $Description

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "ILNPv6 Locator Update Message (156)" -Service Any -Program System `
-Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol ICMPv6 -IcmpType 156 -LocalAddress Any -RemoteAddress $RemoteAddr -LocalPort Any -RemotePort Any `
-Localuser $NT_AUTHORITY_System `
-Description $Description

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "Duplicate Address Request (157)" -Service Any -Program System `
-Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol ICMPv6 -IcmpType 157 -LocalAddress Any -RemoteAddress $RemoteAddr -LocalPort Any -RemotePort Any `
-Localuser $NT_AUTHORITY_System `
-Description $Description

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "Duplicate Address Confirmation (158)" -Service Any -Program System `
-Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol ICMPv6 -IcmpType 158 -LocalAddress Any -RemoteAddress $RemoteAddr -LocalPort Any -RemotePort Any `
-Localuser $NT_AUTHORITY_System `
-Description $Description

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "MPL Control Message (159)" -Service Any -Program System `
-Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol ICMPv6 -IcmpType 159 -LocalAddress Any -RemoteAddress $RemoteAddr -LocalPort Any -RemotePort Any `
-Localuser $NT_AUTHORITY_System `
-Description $Description

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "Extended Echo Request (160)" -Service Any -Program System `
-Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol ICMPv6 -IcmpType 160 -LocalAddress Any -RemoteAddress $RemoteAddr -LocalPort Any -RemotePort Any `
-Localuser $NT_AUTHORITY_System `
-Description $Description

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "Extended Echo Reply (161)" -Service Any -Program System `
-Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol ICMPv6 -IcmpType 161 -LocalAddress Any -RemoteAddress $RemoteAddr -LocalPort Any -RemotePort Any `
-Localuser $NT_AUTHORITY_System `
-Description $Description
