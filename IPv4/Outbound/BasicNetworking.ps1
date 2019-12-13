
#setup variables:
$PolicyStore = "localhost" #local group policy
$Platform = "10.0+" #Windows 10 and above
$Group = "Basic Networking - IPv4"
$NT_AUTHORITY_SYSTEM = "D:(A;;CC;;;S-1-5-18)"
$Interface = "Wired, Wireless"
$Profile = "Any"
$OnError = "Stop"
$Deubg = $false


#First remove all existing rules matching setup
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction Outbound -ErrorAction SilentlyContinue

#
# Loopback
#

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Loopback" -Service Any -Program Any `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress 127.0.0.1 -LocalPort Any -RemotePort Any `
-Description "Network software and utilities use loopback address to access a local computer's TCP/IP network resources."

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Loopback" -Service Any -Program Any `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress 127.0.0.1 -RemoteAddress Any -LocalPort Any -RemotePort Any `
-Description "Network software and utilities use loopback address to access a local computer's TCP/IP network resources."

#
# DNS (Domain Name System)
#

# TODO: official rule uses loose source mapping
New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "Domain Name System" -Service Dnscache -Program "%SystemRoot%\System32\svchost.exe" `
-Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol UDP -LocalAddress Any -RemoteAddress DNS4 -LocalPort Any -RemotePort 53 `
-Description "Outbound rule to allow DNS requests."

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "Domain Name System" -Service Any -Program System `
-Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol UDP -LocalAddress Any -RemoteAddress DefaultGateway4 -LocalPort Any -RemotePort 53 `
-LocalUser $NT_AUTHORITY_SYSTEM -Description "Rule to allow DNS requests by System to default gateway."

#
# DHCP (Domain Host Configuration Protocol)
#

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "Domain Host Configuration Protocol" -Service Dhcp -Program "%SystemRoot%\System32\svchost.exe" `
-Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol UDP -LocalAddress Any -RemoteAddress DHCP4 -LocalPort 68 -RemotePort 67 `
-Description "Allows DHCPv4 messages for stateful auto-configuration."

#
# IGMP (Internet Group Management Protocol)
#

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "Internet Group Management Protocol" -Service Any -Program System `
-Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol 2 -LocalAddress Any -RemoteAddress LocalSubnet4 -LocalPort Any -RemotePort Any `
-LocalUser $NT_AUTHORITY_SYSTEM -Description "IGMP messages are sent and received by nodes to create, join and depart multicast groups."

#
# IPHTTPS (IPv4 over HTTPS)
#

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "IPv4 over HTTPS" -Service iphlpsvc -Program "%SystemRoot%\system32\svchost.exe" `
-Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort IPHTTPSout `
-Description "Rule to allow IPv4 IPHTTPS tunneling technology to provide connectivity across HTTP proxies and firewalls."

#
# Teredo
#

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform -PolicyStore $PolicyStore `
-DisplayName "Teredo" -Service iphlpsvc -Program "%SystemRoot%\system32\svchost.exe" `
-Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol UDP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 3544 `
-Description "Rule to allow Teredo edge traversal, a technology that provides address assignment and automatic tunneling
for unicast IPv6 traffic when an IPv6/IPv4 host is located behind an IPv4 network address translator."
