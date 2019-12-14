
# Import global variables
. "$PSScriptRoot\..\..\Modules\GlobalVariables.ps1"

# Setup local variables:
$Group = "Basic Networking - IPv4"
$Interface = "Wired, Wireless"
$Profile = "Any"


#First remove all existing rules matching setup
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction Outbound -ErrorAction SilentlyContinue

#
# Loopback
#

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Loopback" -Service Any -Program Any `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType Any `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress 127.0.0.1 -LocalPort Any -RemotePort Any `
-LocalUser Any `
-Description "Network software and utilities use loopback address to access a local computer's TCP/IP network resources."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Loopback" -Service Any -Program Any `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType Any `
-Direction Outbound -Protocol TCP -LocalAddress 127.0.0.1 -RemoteAddress Any -LocalPort Any -RemotePort Any `
-LocalUser Any `
-Description "Network software and utilities use loopback address to access a local computer's TCP/IP network resources."

#
# DNS (Domain Name System)
#

# TODO: official rule uses loose source mapping
New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "Domain Name System" -Service Dnscache -Program "%SystemRoot%\System32\svchost.exe" `
-Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol UDP -LocalAddress Any -RemoteAddress DNS4 -LocalPort Any -RemotePort 53 `
-LocalUser Any `
-Description "Allow DNS requests."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "Domain Name System" -Service Any -Program System `
-Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol UDP -LocalAddress Any -RemoteAddress DefaultGateway4 -LocalPort Any -RemotePort 53 `
-LocalUser $NT_AUTHORITY_SYSTEM `
-Description "Allow DNS requests by System to default gateway."

#
# DHCP (Dynamic Host Configuration Protocol)
#

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "Dynamic Host Configuration Protocol" -Service Dhcp -Program "%SystemRoot%\System32\svchost.exe" `
-Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol UDP -LocalAddress Any -RemoteAddress DHCP4 -LocalPort 68 -RemotePort 67 `
-LocalUser Any `
-Description "Allow DHCPv4 messages for stateful auto-configuration."

#
# IGMP (Internet Group Management Protocol)
#

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "Internet Group Management Protocol" -Service Any -Program System `
-Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol 2 -LocalAddress Any -RemoteAddress LocalSubnet4 -LocalPort Any -RemotePort Any `
-LocalUser $NT_AUTHORITY_SYSTEM `
-Description "IGMP messages are sent and received by nodes to create, join and depart multicast groups."

#
# IPHTTPS (IPv4 over HTTPS)
#

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "IPv4 over HTTPS" -Service iphlpsvc -Program "%SystemRoot%\system32\svchost.exe" `
-Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort IPHTTPSout `
-LocalUser Any `
-Description "Allow IPv4 IPHTTPS tunneling technology to provide connectivity across HTTP proxies and firewalls."

#
# Teredo
#

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "Teredo" -Service iphlpsvc -Program "%SystemRoot%\system32\svchost.exe" `
-Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol UDP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 3544 `
-LocalUser Any `
-Description "Allow Teredo edge traversal, a technology that provides address assignment and automatic tunneling
for unicast IPv6 traffic when an IPv6/IPv4 host is located behind an IPv4 network address translator."
