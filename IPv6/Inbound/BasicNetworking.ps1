
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

#
# Import global variables
#
. "$PSScriptRoot\..\..\Modules\GlobalVariables.ps1"

# Ask user if he wants to load these rules
if (!(RunThis)) { exit }

#
# Setup local variables:
#
$Group = "Basic Networking - IPv6"
$Interface = "Wired, Wireless"
$Profile = "Any"
$ISATAP_Remotes = @("Internet6", "LocalSubnet6")

#First remove all existing rules matching setup
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction Inbound -ErrorAction SilentlyContinue

#
# Predefined rules from Core Networking are here
#

#
# Loop back
#

# TODO: why does not this work?

<#
New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "Loopback" -Service Any -Program Any `
-Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Inbound -Protocol TCP -LocalAddress ::1/128 -RemoteAddress Any -LocalPort Any -RemotePort Any`
-EdgeTraversalPolicy Block -LocalUser Any `
-Description "Network software and utilities use loopback address to access a local computer's TCP/IP network resources."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "Loopback" -Service Any -Program Any `
-Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Inbound -Protocol UDP -LocalAddress ::1/128 -RemoteAddress Any -LocalPort Any -RemotePort Any`
-EdgeTraversalPolicy Block -LocalUser Any `
-Description "Network software and utilities use loopback address to access a local computer's TCP/IP network resources."
#>

#
# mDNS (Multicast Domain Name System)
# NOTE: this should be placed in Multicast.ps1 like it is for IPv6, but it's here because of specific address,
# which is part of "Local Network Control Block" (224.0.0.0 - 224.0.0.255)
# An mDNS message is a multicast UDP packet sent using the following addressing:
# IPv4 address 224.0.0.251 or IPv6 address ff02::fb
# UDP port 5353
# https://en.wikipedia.org/wiki/Multicast_DNS
#

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "Multicast Domain Name System" -Service Dnscache -Program $ServiceHost `
-Enabled True -Action Allow -Group $Group -Profile Private, Domain -InterfaceType $Interface `
-Direction Outbound -Protocol UDP -LocalAddress ff05::fb -RemoteAddress LocalSubnet6 -LocalPort 5353 -RemotePort 5353 `
-EdgeTraversalPolicy Block -LocalUser Any `
-Description "In computer networking, the multicast DNS (mDNS) protocol resolves hostnames to IP addresses
within small networks that do not include a local name server.
It is a zero-configuration service, using essentially the same programming interfaces,
packet formats and operating semantics as the unicast Domain Name System (DNS)."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "Multicast Domain Name System" -Service Dnscache -Program $ServiceHost `
-Enabled True -Action Block -Group $Group -Profile Public -InterfaceType $Interface `
-Direction Outbound -Protocol UDP -LocalAddress ff05::fb -RemoteAddress LocalSubnet6 -LocalPort 5353 -RemotePort 5353 `
-EdgeTraversalPolicy Block -LocalUser Any `
-Description "In computer networking, the multicast DNS (mDNS) protocol resolves hostnames to IP addresses
within small networks that do not include a local name server.
It is a zero-configuration service, using essentially the same programming interfaces,
packet formats and operating semantics as the unicast Domain Name System (DNS)."

#
# DHCP (Dynamic Host Configuration Protocol)
#

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "Dynamic Host Configuration Protocol" -Service Dhcp -Program $ServiceHost `
-Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Inbound -Protocol UDP -LocalAddress Any -RemoteAddress DHCP6 -LocalPort 546 -RemotePort 547 `
-EdgeTraversalPolicy Block -LocalUser Any `
-Description "Allows DHCPv6 messages for stateful auto-configuration."

#
# IGMP (Internet Group Management Protocol)
#

# Multicast Listener Discovery (MLD) is a component of the Internet Protocol Version 6 (IPv6) suite.
# MLD is used by IPv6 routers for discovering multicast listeners on a directly attached link,
# much like Internet Group Management Protocol (IGMP) is used in IPv4. 

#
# IPHTTPS (IPv6 over HTTPS)
#

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "IPv6 over HTTPS" -Service Any -Program System `
-Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Inbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet6 -LocalPort IPHTTPSIn -RemotePort Any `
-EdgeTraversalPolicy Block -LocalUser $NT_AUTHORITY_System `
-Description "Allow IPv6 IPHTTPS tunneling technology to provide connectivity across HTTP proxies and firewalls."

#
# IPv6 Encapsulation
#

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "IPv6 Encapsulation" -Service Any -Program System `
-Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Inbound -Protocol 41 -LocalAddress Any -RemoteAddress $ISATAP_Remotes -LocalPort Any -RemotePort Any `
-LocalUser $NT_AUTHORITY_System `
-Description "Rule required to permit IPv6 traffic for ISATAP (Intra-Site Automatic Tunnel Addressing Protocol) and 6to4 tunneling services."
