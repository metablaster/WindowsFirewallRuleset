
# Import global variables
Import-Module "$PSScriptRoot\..\..\Modules\GlobalVariables.psm1"

# Setup local variables:
$Group = "Basic Networking - IPv4"
$Interface = "Wired, Wireless"
$Profile = "Any"


#First remove all existing rules matching setup
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction Inbound -ErrorAction SilentlyContinue

#
# Loopback
#

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Loopback" -Service Any -Program Any `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType Any `
-Direction Inbound -Protocol TCP -LocalAddress Any -RemoteAddress 127.0.0.1 -LocalPort Any -RemotePort Any `
-LocalUser Any `
-Description "Network software and utilities use loopback address to access a local computer's TCP/IP network resources."

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Loopback" -Service Any -Program Any `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType Any `
-Direction Inbound -Protocol TCP -LocalAddress 127.0.0.1 -RemoteAddress Any -LocalPort Any -RemotePort Any `
-LocalUser Any `
-Description "Network software and utilities use loopback address to access a local computer's TCP/IP network resources."

#
# DHCP (Dynamic Host Configuration Protocol)
#

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "Dynamic Host Configuration Protocol" -Service Dhcp -Program "%SystemRoot%\System32\svchost.exe" `
-Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Inbound -Protocol UDP -LocalAddress Any -RemoteAddress DHCP4 -LocalPort 68 -RemotePort 67 `
-EdgeTraversalPolicy Block -LocalUser Any `
-Description "Allow DHCPv4 messages for stateful auto-configuration."

#
# IGMP (Internet Group Management Protocol)
#

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "Internet Group Management Protocol" -Service Any -Program System `
-Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Inbound -Protocol 2 -LocalAddress Any -RemoteAddress LocalSubnet4 -LocalPort Any -RemotePort Any `
-EdgeTraversalPolicy Block -LocalUser $NT_AUTHORITY_SYSTEM `
-Description "IGMP messages are sent and received by nodes to create, join and depart multicast groups."

#
# IPHTTPS (IPv4 over HTTPS)
#

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "IPv4 over HTTPS" -Service iphlpsvc -Program "%SystemRoot%\system32\svchost.exe" `
-Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Inbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort IPHTTPSIn -RemotePort Any `
-EdgeTraversalPolicy Block -LocalUser Any `
-Description "Allow IPv4 IPHTTPS tunneling technology to provide connectivity across HTTP proxies and firewalls."

#
# Teredo
#

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "Teredo" -Service iphlpsvc -Program "%SystemRoot%\system32\svchost.exe" `
-Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Inbound -Protocol UDP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Teredo -RemotePort Any `
-EdgeTraversalPolicy Block -LocalUser Any `
-Description "Allow Teredo edge traversal, a technology that provides address assignment and automatic tunneling
for unicast IPv6 traffic when an IPv6/IPv4 host is located behind an IPv4 network address translator."
