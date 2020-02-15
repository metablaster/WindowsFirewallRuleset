
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

#setup variables:
$PolicyStore = "localhost" #local group policy
$Platform = "6.1+" #Windows 7 and above
$Group = "Core Networking - IPv4"
$NT_AUTHORITY_SYSTEM = "D:(A;;CC;;;S-1-5-18)"


#First remove all existing rules matching setup
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction Outbound -ErrorAction SilentlyContinue
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction Inbound -ErrorAction SilentlyContinue


#Loop back
New-NetFirewallRule -ErrorAction Stop -Enabled True -PolicyStore $PolicyStore -Group $Group -Platform $Platform -Direction Outbound -LocalAddress 127.0.0.1 -DisplayName "Loopback" -Description "Network software and utilities use loopback address to access a local computer's TCP/IP network resources."
New-NetFirewallRule -ErrorAction Stop -Enabled True -PolicyStore $PolicyStore -Group $Group -Platform $Platform -Direction Outbound -RemoteAddress 127.0.0.1 -DisplayName "Loopback" -Description "Network software and utilities use loopback address to access a local computer's TCP/IP network resources."

#DNS
New-NetFirewallRule -ErrorAction Stop -Enabled True -PolicyStore $PolicyStore -Group $Group -Platform $Platform -Direction Outbound -Protocol UDP -RemoteAddress DNS4 -Service Dnscache -RemotePort 53 -DisplayName "Domain Name System" -Description "Rule to allow IPv4 DNS requests over."
New-NetFirewallRule -ErrorAction Stop -Enabled True -PolicyStore $PolicyStore -Group $Group -Platform $Platform -Direction Outbound -Protocol UDP -RemoteAddress DefaultGateway4 -RemotePort 53 -Program System -LocalUser $NT_AUTHORITY_SYSTEM -DisplayName "Domain Name System" -Description "Rule to allow IPv6 DNS requests by System to default gateway."

#DHCP
New-NetFirewallRule -ErrorAction Stop -Enabled True -PolicyStore $PolicyStore -Group $Group -Platform $Platform -Direction Outbound -Protocol UDP -RemoteAddress DHCP4 -Service Dhcp -LocalPort 68 -RemotePort 67 -DisplayName "Domain Host Configuration Protocol" -Description "Allows DHCPv4 messages for stateful auto-configuration."

#IGMP
New-NetFirewallRule -ErrorAction Stop -Enabled True -PolicyStore $PolicyStore -Group $Group -Platform $Platform -Direction Outbound -Protocol 2 -RemoteAddress LocalSubnet4 -Profile Private,Domain -Program System -LocalUser $NT_AUTHORITY_SYSTEM -DisplayName "Internet Group Management Protocol" -Description "IGMP messages are sent and received by nodes to create, join and depart multicast groups."

#IPHTTPS
New-NetFirewallRule -ErrorAction Stop -Enabled True -PolicyStore $PolicyStore -Group $Group -Platform $Platform -Direction Outbound -Protocol TCP -RemoteAddress Internet4 -Service iphlpsvc -RemotePort IPHTTPSout -DisplayName "IPv4 over HTTPS" -Description "Rule to allow IPv4 IPHTTPS tunneling technology to provide connectivity across HTTP proxies and firewalls."

#Teredo
New-NetFirewallRule -ErrorAction Stop -Enabled True -PolicyStore $PolicyStore -Group $Group -Platform $Platform -Direction Outbound -Protocol UDP -RemoteAddress Internet4 -RemotePort 3544 -Service iphlpsvc -DisplayName "Teredo" -Description "Rule to allow Teredo edge traversal, a technology that provides address assignment and automatic tunneling for unicast IPv6 traffic when an IPv6/IPv4 host is located behind an IPv4 network address translator."



#inbound
#DHCP
New-NetFirewallRule -ErrorAction Stop -Enabled True -PolicyStore $PolicyStore -Group $Group -Platform $Platform -Protocol UDP -RemoteAddress DHCP4 -Service Dhcp -LocalPort 68 -RemotePort 67 -DisplayName "Domain Host Configuration Protocol" -Description "Allows DHCPv4 messages for stateful auto-configuration."

#IPHTTPS
New-NetFirewallRule -ErrorAction Stop -Enabled True -PolicyStore $PolicyStore -Group $Group -Platform $Platform -Protocol TCP -RemoteAddress Internet4 -Service iphlpsvc -LocalPort IPHTTPSIn -DisplayName "IPv4 over HTTPS" -Description "Rule to allow IPv4 IPHTTPS tunneling technology to provide connectivity across HTTP proxies and firewalls."

#Teredo
New-NetFirewallRule -ErrorAction Stop -Enabled True -PolicyStore $PolicyStore -Group $Group -Platform $Platform -Protocol UDP -Service iphlpsvc -LocalPort 3544 -RemoteAddress Internet4 -EdgeTraversalPolicy Allow -DisplayName "Teredo" -Description "Rule to allow Teredo edge traversal, a technology that provides address assignment and automatic tunneling for unicast IPv6 traffic when an IPv6/IPv4 host is located behind an IPv4 network address translator."

#IGMP
New-NetFirewallRule -ErrorAction Stop -Enabled False -PolicyStore $PolicyStore -Group $Group -Platform $Platform -Protocol 2 -RemoteAddress LocalSubnet4 -Profile Private,Domain -Program System -LocalUser $NT_AUTHORITY_SYSTEM -DisplayName "Internet Group Management Protocol" -Description "IGMP messages are sent and received by nodes to create, join and depart multicast groups."
