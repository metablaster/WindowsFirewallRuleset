
<#
MIT License

Project: "Windows Firewall Ruleset" serves to manage firewall on Windows systems,
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

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

<#http://www.iana.org/assignments/ipv6-multicast-addresses/ipv6-multicast-addresses.xhtml
ff00/16 	Reserved
ff01/16	    Interface-Local scope
ff02/16	    Link-Local scope
ff03/16	    Realm-Local scope
ff04/16	    Admin-Local scope
ff05/16	    Site-Local scope
ff06/16	    Unassigned
ff07/16	    Unassigned
ff08/16	    Organization-Local scope
ff09/16 - ff0D/16	Unassigned
ff0e/16	    Global scope
ff0f/16  	Reserved
#>

#setup variables:
$PolicyStore = "localhost" #local group policy
$Platform = "6.1+" #Windows 7 and above
$Protocol = "UDP"
$Group = "Core Networking - Multicast IPv6"
$Profile = "Private, Domain" #Boot time multicast dropped due to WFP Operation (The transition from boot-time to persistent filters could be several seconds, or even longer on a slow machine.)
$Description = "Multicast IPv6"


#First remove all existing rules matching setup
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction "Outbound" -ErrorAction SilentlyContinue
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction "Inbound" -ErrorAction SilentlyContinue


#Interface-Local Multicast filtering ( All destinations - Outbound )
New-NetFirewallRule -ErrorAction Stop -Enabled True -Description $Description -Direction Outbound -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -RemoteAddress ff01::/16 -DisplayName "Interface-Local Multicast"

#Interface-Local Multicast filtering ( Individual destinations Outbound )
<#
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -RemoteAddress ff01::1 -DisplayName "Interface-Local Multicast - All Nodes"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -RemoteAddress ff01::2 -DisplayName "Interface-Local Multicast - All Routers"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -RemoteAddress ff01::fb -DisplayName "Interface-Local Multicast - mDNSv6"
#>

#Interface-Local Multicast filtering ( All  destinations Inbound )
New-NetFirewallRule -ErrorAction Stop -Enabled True -Description $Description -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -LocalAddress ff01::/16 -DisplayName "Interface-Local - Multicast"

#Interface-Local Multicast filtering ( Individual  destinations Inbound )
<#
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -LocalAddress ff01::1 -DisplayName "Interface-Local - Multicast - All Nodes"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -LocalAddress ff01::2 -DisplayName "Interface-Local - All Routers"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -LocalAddress ff01::fb -DisplayName "Interface-Local - mDNSv6"
#>


#Link-Local Multicast filtering ( All destinations - Outbound )
New-NetFirewallRule -ErrorAction Stop -Enabled True -Description $Description -Direction Outbound -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -RemoteAddress ff02::/16 -DisplayName "Link-Local Multicast"

#Link-Local Multicast filtering ( Individual destinations - Outbound )
<#
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -RemoteAddress ff02::1 -DisplayName "Link-Local Multicast - All Nodes"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -RemoteAddress ff02::2 -DisplayName "Link-Local Multicast - All Routers"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -RemoteAddress ff02::4 -DisplayName "Link-Local Multicast - DVMRP Routers"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -RemoteAddress ff02::5 -DisplayName "Link-Local Multicast - OSPFIGP"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -RemoteAddress ff02::6 -DisplayName "Link-Local Multicast - OSPFIGP Designated Routers"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -RemoteAddress ff02::7 -DisplayName "Link-Local Multicast - ST Routers"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -RemoteAddress ff02::8 -DisplayName "Link-Local Multicast - ST Hosts"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -RemoteAddress ff02::9 -DisplayName "Link-Local Multicast - RIP Routers"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -RemoteAddress ff02::a -DisplayName "Link-Local Multicast - EIGRP Routers"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -RemoteAddress ff02::b -DisplayName "Link-Local Multicast - Mobile-Agents"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -RemoteAddress ff02::c -DisplayName "Link-Local Multicast - SSDP"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -RemoteAddress ff02::d -DisplayName "Link-Local Multicast - All PIM Routers"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -RemoteAddress ff02::e -DisplayName "Link-Local Multicast - RSVP-ENCAPSULATION"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -RemoteAddress ff02::f -DisplayName "Link-Local Multicast - UPnP"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -RemoteAddress ff02::10 -DisplayName "Link-Local Multicast - All-BBF-Access-Nodes"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -RemoteAddress ff02::12 -DisplayName "Link-Local Multicast - VRRP"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -RemoteAddress ff02::16 -DisplayName "Link-Local Multicast - All MLDv2-capable routers"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -RemoteAddress ff02::1a -DisplayName "Link-Local Multicast - all-RPL-nodes"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -RemoteAddress ff02::6a -DisplayName "Link-Local Multicast - All-Snoopers"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -RemoteAddress ff02::6b -DisplayName "Link-Local Multicast - PTP-pdelay"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -RemoteAddress ff02::6c -DisplayName "Link-Local Multicast - Saratoga"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -RemoteAddress ff02::6d -DisplayName "Link-Local Multicast - LL-MANET-Routers"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -RemoteAddress ff02::6e -DisplayName "Link-Local Multicast - IGRS"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -RemoteAddress ff02::6f -DisplayName "Link-Local Multicast - iADT Discovery"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -RemoteAddress ff02::fb -DisplayName "Link-Local Multicast - mDNSv6"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -RemoteAddress ff02::1:1 -DisplayName "Link-Local Multicast - Link Name"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -RemoteAddress ff02::1:2 -DisplayName "Link-Local Multicast - All-dhcp-agents"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -RemoteAddress ff02::1:3 -DisplayName "Link-Local Multicast - Link-local Multicast Name Resolution"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -RemoteAddress ff02::1:4 -DisplayName "Link-Local Multicast - DTCP Announcement"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -RemoteAddress ff02::1:5 -DisplayName "Link-Local Multicast - afore_vdp"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -RemoteAddress ff02::1:6 -DisplayName "Link-Local Multicast - Babel"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -RemoteAddress ff02::1:ff00:0000/104 -DisplayName "Link-Local Multicast - Solicited-Node Address"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -RemoteAddress FF02:0:0:0:0:2:FF00::/104 -DisplayName "Link-Local Multicast - Node Information Queries"
#>





#Link-Local Multicast filtering ( All destinations - Inbound )
New-NetFirewallRule -ErrorAction Stop -Enabled True -Description $Description -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -LocalAddress ff02::/16 -DisplayName "Link-Local Multicast"


#Link-Local Multicast filtering ( Individual destinations - Inbound )
<#
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -LocalAddress ff02::1 -DisplayName "Link-Local Multicast - All Nodes"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -LocalAddress ff02::2 -DisplayName "Link-Local Multicast - All Routers"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -LocalAddress ff02::4 -DisplayName "Link-Local Multicast - DVMRP Routers"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -LocalAddress ff02::5 -DisplayName "Link-Local Multicast - OSPFIGP"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -LocalAddress ff02::6 -DisplayName "Link-Local Multicast - OSPFIGP Designated Routers"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -LocalAddress ff02::7 -DisplayName "Link-Local Multicast - ST Routers"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -LocalAddress ff02::8 -DisplayName "Link-Local Multicast - ST Hosts"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -LocalAddress ff02::9 -DisplayName "Link-Local Multicast - RIP Routers"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -LocalAddress ff02::a -DisplayName "Link-Local Multicast - EIGRP Routers"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -LocalAddress ff02::b -DisplayName "Link-Local Multicast - Mobile-Agents"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -LocalAddress ff02::c -DisplayName "Link-Local Multicast - SSDP"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -LocalAddress ff02::d -DisplayName "Link-Local Multicast - All PIM Routers"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -LocalAddress ff02::e -DisplayName "Link-Local Multicast - RSVP-ENCAPSULATION"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -LocalAddress ff02::f -DisplayName "Link-Local Multicast - UPnP"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -LocalAddress ff02::10 -DisplayName "Link-Local Multicast - All-BBF-Access-Nodes"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -LocalAddress ff02::12 -DisplayName "Link-Local Multicast - VRRP"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -LocalAddress ff02::16 -DisplayName "Link-Local Multicast - All MLDv2-capable routers"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -LocalAddress ff02::1a -DisplayName "Link-Local Multicast - all-RPL-nodes"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -LocalAddress ff02::6a -DisplayName "Link-Local Multicast - All-Snoopers"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -LocalAddress ff02::6b -DisplayName "Link-Local Multicast - PTP-pdelay"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -LocalAddress ff02::6c -DisplayName "Link-Local Multicast - Saratoga"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -LocalAddress ff02::6d -DisplayName "Link-Local Multicast - LL-MANET-Routers"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -LocalAddress ff02::6e -DisplayName "Link-Local Multicast - IGRS"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -LocalAddress ff02::6f -DisplayName "Link-Local Multicast - iADT Discovery"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -LocalAddress ff02::fb -DisplayName "Link-Local Multicast - mDNSv6"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -LocalAddress ff02::1:1 -DisplayName "Link-Local Multicast - Link Name"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -LocalAddress ff02::1:2 -DisplayName "Link-Local Multicast - All-dhcp-agents"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -LocalAddress ff02::1:3 -DisplayName "Link-Local Multicast - Link-local Multicast Name Resolution"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -LocalAddress ff02::1:4 -DisplayName "Link-Local Multicast - DTCP Announcement"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -LocalAddress ff02::1:5 -DisplayName "Link-Local Multicast - afore_vdp"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -LocalAddress ff02::1:6 -DisplayName "Link-Local Multicast - Babel"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -LocalAddress ff02::1:ff00:0000/104 -DisplayName "Link-Local Multicast - Solicited-Node Address"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -LocalAddress FF02:0:0:0:0:2:FF00::/104 -DisplayName "Link-Local Multicast - Node Information Queries"
#>

<#
#Site-Local Multicast filtering ( All destinations - Outbound )
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -RemoteAddress ff05::/16 -DisplayName "Link-Local Multicast - All Routers"

#Site-Local Multicast filtering ( Individual destinations - Outbound )

New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -RemoteAddress ff05::2 -DisplayName "Link-Local Multicast - All Routers"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -RemoteAddress ff05::fb -DisplayName "Link-Local Multicast - mDNSv6"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -RemoteAddress ff05::1:3 -DisplayName "Link-Local Multicast - All-dhcp-servers"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -RemoteAddress ff05::1:5 -DisplayName "Link-Local Multicast - SL-MANET-ROUTERS"


#Site-Local Multicast filtering ( All destinations - Inbound )
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -LocalAddress ff05::/16 -DisplayName "Link-Local Multicast - All Routers"

#Site-Local Multicast filtering ( Individual destinations - Inbound )
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -LocalAddress ff05::2 -DisplayName "Link-Local Multicast - All Routers"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -LocalAddress ff05::fb -DisplayName "Link-Local Multicast - mDNSv6"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -LocalAddress ff05::1:3 -DisplayName "Link-Local Multicast - All-dhcp-servers"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -LocalAddress ff05::1:5 -DisplayName "Link-Local Multicast - SL-MANET-ROUTERS"
#>
