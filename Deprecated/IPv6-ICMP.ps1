
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

#http://www.iana.org/assignments/icmpv6-parameters/icmpv6-parameters.xhtml

#setup variables:
$PolicyStore = "localhost" #local group policy
$Platform = "6.1+" #Windows 7 and above
$LocalUser = "D:(A;;CC;;;S-1-5-18)" #NT AUTHORITY\SYSTEM
$Group = "Core Networking - ICMPv6"
$Program = "System"
$Profile = "Private,Domain"
$Description = "Internet Control Message Protocol version 6"
$RemoteAddr = "Internet6"

#First remove all existing rules matching setup
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction Outbound -ErrorAction SilentlyContinue
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction Inbound -ErrorAction SilentlyContinue


#Interface-Local Multicast filtering ( All destinations - Outbound )
New-NetFirewallRule -ErrorAction Stop -Enabled True -Description $Description -Direction Outbound -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress ff01::/16 -DisplayName "Interface-Local Multicast"

#Interface-Local Multicast filtering ( Individual destinations - Outbound )
<#
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress ff01::1 -DisplayName "Interface-Local Multicast - All Nodes"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress ff01::2 -DisplayName "Interface-Local Multicast - All Routers"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress ff01::fb -DisplayName "Interface-Local Multicast - mDNSv6"
#>

#Interface-Local Multicast filtering ( All destinations - Inbound )
New-NetFirewallRule -ErrorAction Stop -Enabled True -Description $Description -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -LocalAddress ff01::/16 -DisplayName "Interface-Local Multicast"

<#
#Interface-Local Multicast filtering ( Individual destinations - Inbound )
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -LocalAddress ff01::1 -DisplayName "Interface-Local Multicast - All Nodes"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -LocalAddress ff01::2 -DisplayName "Interface-Local Multicast - All Routers"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -LocalAddress ff01::fb -DisplayName "Interface-Local Multicast - mDNSv6"
#>






#Link-Local Multicast filtering ( All destinations - Outbound )
New-NetFirewallRule -ErrorAction Stop -Enabled True -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress ff02::/16 -DisplayName "Link-Local Multicast"

<#
#Link-Local Multicast filtering ( Individual destinations - Outbound )
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress ff02::1 -DisplayName "Link-Local Multicast - All Nodes"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress ff02::2 -DisplayName "Link-Local Multicast - All Routers"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress ff02::4 -DisplayName "Link-Local Multicast - DVMRP Routers"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress ff02::5 -DisplayName "Link-Local Multicast - OSPFIGP"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress ff02::6 -DisplayName "Link-Local Multicast - OSPFIGP Designated Routers"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress ff02::7 -DisplayName "Link-Local Multicast - ST Routers"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress ff02::8 -DisplayName "Link-Local Multicast - ST Hosts"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress ff02::9 -DisplayName "Link-Local Multicast - RIP Routers"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress ff02::a -DisplayName "Link-Local Multicast - EIGRP Routers"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress ff02::b -DisplayName "Link-Local Multicast - Mobile-Agents"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress ff02::c -DisplayName "Link-Local Multicast - SSDP"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress ff02::d -DisplayName "Link-Local Multicast - All PIM Routers"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress ff02::e -DisplayName "Link-Local Multicast - RSVP-ENCAPSULATION"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress ff02::f -DisplayName "Link-Local Multicast - UPnP"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress ff02::10 -DisplayName "Link-Local Multicast - All-BBF-Access-Nodes"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress ff02::12 -DisplayName "Link-Local Multicast - VRRP"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress ff02::16 -DisplayName "Link-Local Multicast - All MLDv2-capable routers"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress ff02::1a -DisplayName "Link-Local Multicast - all-RPL-nodes"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress ff02::6a -DisplayName "Link-Local Multicast - All-Snoopers"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress ff02::6b -DisplayName "Link-Local Multicast - PTP-pdelay"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress ff02::6c -DisplayName "Link-Local Multicast - Saratoga"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress ff02::6d -DisplayName "Link-Local Multicast - LL-MANET-Routers"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress ff02::6e -DisplayName "Link-Local Multicast - IGRS"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress ff02::6f -DisplayName "Link-Local Multicast - iADT Discovery"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress ff02::fb -DisplayName "Link-Local Multicast - mDNSv6"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress ff02::1:1 -DisplayName "Link-Local Multicast - Link Name"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress ff02::1:2 -DisplayName "Link-Local Multicast - All-dhcp-agents"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress ff02::1:3 -DisplayName "Link-Local Multicast - Link-local Multicast Name Resolution"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress ff02::1:4 -DisplayName "Link-Local Multicast - DTCP Announcement"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress ff02::1:5 -DisplayName "Link-Local Multicast - afore_vdp"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress ff02::1:6 -DisplayName "Link-Local Multicast - Babel"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress ff02::1:ff00:0000/104 -DisplayName "Link-Local Multicast - Solicited-Node Address"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress ff02:0:0:0:0:2:ff00::/104 -DisplayName "Link-Local Multicast - Node Information Queries"
#>

#Link-Local Multicast filtering ( All destinations - Inbound )
New-NetFirewallRule -ErrorAction Stop -Enabled True -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -LocalAddress ff02::/16 -DisplayName "Link-Local Multicast"

#Link-Local Multicast filtering ( Individual destinations - Inbound )
<#
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -LocalAddress ff02::1 -DisplayName "Link-Local Multicast - All Nodes"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -LocalAddress ff02::2 -DisplayName "Link-Local Multicast - All Routers"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -LocalAddress ff02::4 -DisplayName "Link-Local Multicast - DVMRP Routers"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -LocalAddress ff02::5 -DisplayName "Link-Local Multicast - OSPFIGP"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -LocalAddress ff02::6 -DisplayName "Link-Local Multicast - OSPFIGP Designated Routers"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -LocalAddress ff02::7 -DisplayName "Link-Local Multicast - ST Routers"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -LocalAddress ff02::8 -DisplayName "Link-Local Multicast - ST Hosts"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -LocalAddress ff02::9 -DisplayName "Link-Local Multicast - RIP Routers"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -LocalAddress ff02::a -DisplayName "Link-Local Multicast - EIGRP Routers"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -LocalAddress ff02::b -DisplayName "Link-Local Multicast - Mobile-Agents"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -LocalAddress ff02::c -DisplayName "Link-Local Multicast - SSDP"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -LocalAddress ff02::d -DisplayName "Link-Local Multicast - All PIM Routers"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -LocalAddress ff02::e -DisplayName "Link-Local Multicast - RSVP-ENCAPSULATION"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -LocalAddress ff02::f -DisplayName "Link-Local Multicast - UPnP"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -LocalAddress ff02::10 -DisplayName "Link-Local Multicast - All-BBF-Access-Nodes"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -LocalAddress ff02::12 -DisplayName "Link-Local Multicast - VRRP"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -LocalAddress ff02::16 -DisplayName "Link-Local Multicast - All MLDv2-capable routers"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -LocalAddress ff02::1a -DisplayName "Link-Local Multicast - all-RPL-nodes"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -LocalAddress ff02::6a -DisplayName "Link-Local Multicast - All-Snoopers"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -LocalAddress ff02::6b -DisplayName "Link-Local Multicast - PTP-pdelay"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -LocalAddress ff02::6c -DisplayName "Link-Local Multicast - Saratoga"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -LocalAddress ff02::6d -DisplayName "Link-Local Multicast - LL-MANET-Routers"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -LocalAddress ff02::6e -DisplayName "Link-Local Multicast - IGRS"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -LocalAddress ff02::6f -DisplayName "Link-Local Multicast - iADT Discovery"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -LocalAddress ff02::fb -DisplayName "Link-Local Multicast - mDNSv6"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -LocalAddress ff02::1:1 -DisplayName "Link-Local Multicast - Link Name"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -LocalAddress ff02::1:2 -DisplayName "Link-Local Multicast - All-dhcp-agents"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -LocalAddress ff02::1:3 -DisplayName "Link-Local Multicast - Link-local Multicast Name Resolution"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -LocalAddress ff02::1:4 -DisplayName "Link-Local Multicast - DTCP Announcement"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -LocalAddress ff02::1:5 -DisplayName "Link-Local Multicast - afore_vdp"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -LocalAddress ff02::1:6 -DisplayName "Link-Local Multicast - Babel"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -LocalAddress ff02::1:ff00:0000/104 -DisplayName "Link-Local Multicast - Solicited-Node Address"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -LocalAddress ff02:0:0:0:0:2:ff00::/104 -DisplayName "Link-Local Multicast - Node Information Queries"
#>


<#
#Site-Local Multicast filtering ( All destinations - Outbound )
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress ff05::/16 -DisplayName "Site-Local Multicast"

#Site-Local Multicast filtering ( Individual destinations - Outbound )
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress ff05::2 -DisplayName "Site-Local Multicast - All Routers"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress ff05::fb -DisplayName "Site-Local Multicast - mDNSv6"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress ff05::1:3 -DisplayName "Site-Local Multicast - All-dhcp-servers"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress ff05::1:5 -DisplayName "Site-Local Multicast - SL-MANET-ROUTERS"

#Site-Local Multicast filtering ( All destinations - Inbound )
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -LocalAddress ff05::/16 -DisplayName "Site-Local Multicast"

#Site-Local Multicast filtering ( Individual destinations - Inbound )
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -LocalAddress ff05::2 -DisplayName "Site-Local Multicast - All Routers"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -LocalAddress ff05::fb -DisplayName "Site-Local Multicast - mDNSv6"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -LocalAddress ff05::1:3 -DisplayName "Site-Local Multicast - All-dhcp-servers"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -LocalAddress ff05::1:5 -DisplayName "Site-Local Multicast - SL-MANET-ROUTERS"
#>



#Link-Local Subnet filtering ( Outbound )
New-NetFirewallRule -ErrorAction Stop -Enabled True -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress LocalSubnet6 -DisplayName "Link-Local Subnet"

#Link-Local Subnet filtering ( Inbound )
New-NetFirewallRule -ErrorAction Stop -Enabled True -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress LocalSubnet6 -DisplayName "Link-Local Subnet"






$Profile = "Any"

<#
#ICMP Type filtering ( Error messages Outbound )
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 1 -DisplayName "Destination Unreachable (1)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 2 -DisplayName "Packet Too Big (2)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 3 -DisplayName "Time Exceeded (3)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 4 -DisplayName "Parameter Problem (4)"
#>

#ICMP Type filtering ( Informational messages Outbound )
New-NetFirewallRule -ErrorAction Stop -Enabled True -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 128 -DisplayName "Echo Request (128)"
<#
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 129 -DisplayName "Echo Reply (129)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 130 -DisplayName "Multicast Listener Query (130)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 131 -DisplayName "Multicast Listener Report (131)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 132 -DisplayName "Multicast Listener Done (132)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 133 -DisplayName "Router Solicitation (133)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 134 -DisplayName "Router Advertisement (134)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 135 -DisplayName "Neighbor Solicitation (135)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 136 -DisplayName "Neighbor Advertisement (136)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 137 -DisplayName "Redirect Message (137)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 138 -DisplayName "Router Renumbering (138)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 139 -DisplayName "ICMP Node Information Query (139)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 140 -DisplayName "ICMP Node Information Response (140)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 141 -DisplayName "Inverse Neighbor Discovery Solicitation Message (141)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 142 -DisplayName "Inverse Neighbor Discovery Advertisement Message (142)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 143 -DisplayName "Version 2 Multicast Listener Report (143)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 144 -DisplayName "Home Agent Address Discovery Request Message (144)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 145 -DisplayName "Home Agent Address Discovery Reply Message (145)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 146 -DisplayName "Mobile Prefix Solicitation (146)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 147 -DisplayName "Mobile Prefix Advertisement (147)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 148 -DisplayName "Certification Path Solicitation Message (148)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 149 -DisplayName "Certification Path Advertisement Message (149)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 150 -DisplayName "ICMP messages utilized by experimental mobility protocols such as Seamoby (150)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 151 -DisplayName "Multicast Router Advertisement (151)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 152 -DisplayName "Multicast Router Solicitation (152)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 153 -DisplayName "Multicast Router Termination (153)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 154 -DisplayName "FMIPv6 Messages (154)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 155 -DisplayName "RPL Control Message (155)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 156 -DisplayName "ILNPv6 Locator Update Message (156)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 157 -DisplayName "Duplicate Address Request (157)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 158 -DisplayName "Duplicate Address Confirmation (158)"
#>




#ICMP Type filtering ( Error messages Inbound )
New-NetFirewallRule -ErrorAction Stop -Enabled True -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 1 -DisplayName "Destination Unreachable (1)"
New-NetFirewallRule -ErrorAction Stop -Enabled True -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 2 -DisplayName "Packet Too Big (2)"
New-NetFirewallRule -ErrorAction Stop -Enabled True -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 3 -DisplayName "Time Exceeded (3)"
New-NetFirewallRule -ErrorAction Stop -Enabled True -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 4 -DisplayName "Parameter Problem (4)"

#ICMP Type filtering ( Informational messages Inbound )
#New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 128 -DisplayName "Echo Request (128)"
New-NetFirewallRule -ErrorAction Stop -Enabled True -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 129 -DisplayName "Echo Reply (129)"

<#
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 130 -DisplayName "Multicast Listener Query (130)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 131 -DisplayName "Multicast Listener Report (131)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 132 -DisplayName "Multicast Listener Done (132)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 133 -DisplayName "Router Solicitation (133)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 134 -DisplayName "Router Advertisement (134)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 135 -DisplayName "Neighbor Solicitation (135)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 136 -DisplayName "Neighbor Advertisement (136)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 137 -DisplayName "Redirect Message (137)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 138 -DisplayName "Router Renumbering (138)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 139 -DisplayName "ICMP Node Information Query (139)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 140 -DisplayName "ICMP Node Information Response (140)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 141 -DisplayName "Inverse Neighbor Discovery Solicitation Message (141)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 142 -DisplayName "Inverse Neighbor Discovery Advertisement Message (142)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 143 -DisplayName "Version 2 Multicast Listener Report (143)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 144 -DisplayName "Home Agent Address Discovery Request Message (144)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 145 -DisplayName "Home Agent Address Discovery Reply Message (145)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 146 -DisplayName "Mobile Prefix Solicitation (146)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 147 -DisplayName "Mobile Prefix Advertisement (147)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 148 -DisplayName "Certification Path Solicitation Message (148)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 149 -DisplayName "Certification Path Advertisement Message (149)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 150 -DisplayName "ICMP messages utilized by experimental mobility protocols such as Seamoby (150)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 151 -DisplayName "Multicast Router Advertisement (151)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 152 -DisplayName "Multicast Router Solicitation (152)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 153 -DisplayName "Multicast Router Termination (153)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 154 -DisplayName "FMIPv6 Messages (154)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 155 -DisplayName "RPL Control Message (155)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 156 -DisplayName "ILNPv6 Locator Update Message (156)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 157 -DisplayName "Duplicate Address Request (157)"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv6 -RemoteAddress $RemoteAddr -IcmpType 158 -DisplayName "Duplicate Address Confirmation (158)"
#>

#Teredo Filtering
New-NetFirewallRule -ErrorAction Stop -Enabled True -Description $Description -LocalAddress 2001::/32 -RemoteAddress 2001::/32 -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -InterfaceAlias "Teredo Tunneling Pseudo-Interface" -Direction Outbound -Protocol ICMPv6 -IcmpType 135 -DisplayName "Teredo - Neighbor Solicitation (135)"


New-NetFirewallRule -ErrorAction Stop -Enabled True -Description $Description -LocalAddress 2001::/32 -RemoteAddress 2001::/32 -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -InterfaceAlias "Teredo Tunneling Pseudo-Interface" -EdgeTraversalPolicy Allow -Protocol ICMPv6 -IcmpType 135 -DisplayName "Teredo - Neighbor Solicitation (135)"
New-NetFirewallRule -ErrorAction Stop -Enabled True -Description $Description -LocalAddress 2001::/32 -RemoteAddress 2001::/32 -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -InterfaceAlias "Teredo Tunneling Pseudo-Interface" -EdgeTraversalPolicy Allow -Protocol ICMPv6 -IcmpType 136 -DisplayName "Teredo - Neighbor Advertisement (136)"
