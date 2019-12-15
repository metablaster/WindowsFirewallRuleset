
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
$Group = "Basic Networking - IPv4"
$Interface = "Wired, Wireless"
$Profile = "Any"


#First remove all existing rules matching setup
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction Inbound -ErrorAction SilentlyContinue

#
# Predefined rules from Core Networking are here
#

#
# Loopback
#

# TODO: should we use -InterfaceAlias set to Loopback pseudo interface?
New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Loopback" -Service Any -Program Any `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType Any `
-Direction Inbound -Protocol TCP -LocalAddress Any -RemoteAddress 127.0.0.1 -LocalPort Any -RemotePort Any `
-EdgeTraversalPolicy Block -LocalUser Any `
-Description "Network software and utilities use loopback address to access a local computer's TCP/IP network resources."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Loopback" -Service Any -Program Any `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType Any `
-Direction Inbound -Protocol TCP -LocalAddress 127.0.0.1 -RemoteAddress Any -LocalPort Any -RemotePort Any `
-EdgeTraversalPolicy Block -LocalUser Any `
-Description "Network software and utilities use loopback address to access a local computer's TCP/IP network resources."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Loopback" -Service Any -Program Any `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType Any `
-Direction Inbound -Protocol UDP -LocalAddress Any -RemoteAddress 127.0.0.1 -LocalPort Any -RemotePort Any `
-EdgeTraversalPolicy Block -LocalUser Any `
-Description "Network software and utilities use loopback address to access a local computer's TCP/IP network resources."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Loopback" -Service Any -Program Any `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType Any `
-Direction Inbound -Protocol UDP -LocalAddress 127.0.0.1 -RemoteAddress Any -LocalPort Any -RemotePort Any `
-EdgeTraversalPolicy Block -LocalUser Any `
-Description "Network software and utilities use loopback address to access a local computer's TCP/IP network resources."

#
# mDNS (Multicast Domain Name System)
#

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "Multicast Domain Name System" -Service Dnscache -Program "%SystemRoot%\System32\svchost.exe" `
-Enabled True -Action Allow -Group $Group -Profile Private, Domain -InterfaceType $Interface `
-Direction Inbound -Protocol UDP -LocalAddress Any -RemoteAddress LocalSubnet4 -LocalPort 5353 -RemotePort Any `
-EdgeTraversalPolicy Block -LocalUser Any `
-Description "In computer networking, the multicast DNS (mDNS) protocol resolves hostnames to IP addresses
within small networks that do not include a local name server.
It is a zero-configuration service, using essentially the same programming interfaces,
packet formats and operating semantics as the unicast Domain Name System (DNS)."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "Multicast Domain Name System" -Service Dnscache -Program "%SystemRoot%\System32\svchost.exe" `
-Enabled True -Action Block -Group $Group -Profile Public -InterfaceType $Interface `
-Direction Inbound -Protocol UDP -LocalAddress Any -RemoteAddress LocalSubnet4 -LocalPort 5353 -RemotePort Any `
-EdgeTraversalPolicy Block -LocalUser Any `
-Description "In computer networking, the multicast DNS (mDNS) protocol resolves hostnames to IP addresses
within small networks that do not include a local name server.
It is a zero-configuration service, using essentially the same programming interfaces,
packet formats and operating semantics as the unicast Domain Name System (DNS)."

#
# DHCP (Dynamic Host Configuration Protocol)
#

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "Dynamic Host Configuration Protocol" -Service Dhcp -Program "%SystemRoot%\System32\svchost.exe" `
-Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Inbound -Protocol UDP -LocalAddress Any -RemoteAddress DHCP4 -LocalPort 68 -RemotePort 67 `
-EdgeTraversalPolicy Block -LocalUser Any `
-Description "Allow DHCPv4 messages for stateful auto-configuration."

#
# IGMP (Internet Group Management Protocol)
#

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "Internet Group Management Protocol" -Service Any -Program System `
-Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Inbound -Protocol 2 -LocalAddress Any -RemoteAddress LocalSubnet4 -LocalPort Any -RemotePort Any `
-EdgeTraversalPolicy Block -LocalUser $NT_AUTHORITY_System `
-Description "IGMP messages are sent and received by nodes to create, join and depart multicast groups."

#
# IPHTTPS (IPv4 over HTTPS)
#

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "IPv4 over HTTPS" -Service iphlpsvc -Program "%SystemRoot%\system32\svchost.exe" `
-Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Inbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort IPHTTPSIn -RemotePort Any `
-EdgeTraversalPolicy Block -LocalUser Any `
-Description "Allow IPv4 IPHTTPS tunneling technology to provide connectivity across HTTP proxies and firewalls."

#
# Teredo
#

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "Teredo" -Service iphlpsvc -Program "%SystemRoot%\system32\svchost.exe" `
-Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Inbound -Protocol UDP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Teredo -RemotePort Any `
-EdgeTraversalPolicy Block -LocalUser Any `
-Description "Allow Teredo edge traversal, a technology that provides address assignment and automatic tunneling
for unicast IPv6 traffic when an IPv6/IPv4 host is located behind an IPv4 network address translator."
