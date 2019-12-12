#setup variables:
$PolicyStore = "localhost" #local group policy
$Platform = "6.1+" #Windows 7 and above
$Group = "Core Networking - IPv6"
$NT_AUTHORITY_SYSTEM = "D:(A;;CC;;;S-1-5-18)"


#First remove all existing rules matching setup
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction Outbound -ErrorAction SilentlyContinue
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction Inbound -ErrorAction SilentlyContinue


#Loop back
#New-NetFirewallRule -ErrorAction Stop -Enabled True -PolicyStore $PolicyStore -Group $Group -Platform $Platform -Direction Outbound -LocalAddress ::1/128 -DisplayName "Loopback" -Description "Network software and utilities use loopback address to access a local computer's TCP/IP network resources."

#DNS
New-NetFirewallRule -ErrorAction Stop -Enabled True -PolicyStore $PolicyStore -Group $Group -Platform $Platform -Direction Outbound -Protocol UDP -RemoteAddress DNS6 -Service Dnscache -RemotePort 53 -DisplayName "Domain Name System" -Description "Rule to allow IPv6 DNS requests."
New-NetFirewallRule -ErrorAction Stop -Enabled True -PolicyStore $PolicyStore -Group $Group -Platform $Platform -Direction Outbound -Protocol UDP -RemoteAddress DefaultGateway6 -RemotePort 53 -Program System -LocalUser $NT_AUTHORITY_SYSTEM -DisplayName "Domain Name System" -Description "Rule to allow IPv6 DNS requests by System to default gateway."
#New-NetFirewallRule -ErrorAction Stop -Enabled True -PolicyStore $PolicyStore -Group $Group -Platform $Platform -Direction Outbound -Protocol UDP -RemoteAddress DefaultGateway6 -RemotePort 53 -DisplayName "Domain Name System" -Description "Rule to allow IPv6 DNS requests by System to default gateway."

#DHCP
New-NetFirewallRule -ErrorAction Stop -Enabled True -PolicyStore $PolicyStore -Group $Group -Platform $Platform -Direction Outbound -Protocol UDP -RemoteAddress DHCP6 -Service Dhcp -LocalPort 546 -RemotePort 547 -DisplayName "Domain Host Configuration Protocol" -Description "Allows DHCPv6 messages for stateful auto-configuration."

#IPHTTPS
New-NetFirewallRule -ErrorAction Stop -Enabled True -PolicyStore $PolicyStore -Group $Group -Platform $Platform -Direction Outbound -Protocol TCP -RemoteAddress Internet6 -Service iphlpsvc -RemotePort IPHTTPSout -DisplayName "IPv6 over HTTPS" -Description "Rule to allow IPHTTPS tunneling technology to provide connectivity across HTTP proxies and firewalls."

#IPv6 Encapsulation
New-NetFirewallRule -ErrorAction Stop -Enabled True -PolicyStore $PolicyStore -Group $Group -Platform $Platform -Direction Outbound -Protocol 41 -Program System -LocalUser $NT_AUTHORITY_SYSTEM -DisplayName "IPv6 Encapsulation" -Description "Rule required to permit IPv6 traffic for ISATAP (Intra-Site Automatic Tunnel Addressing Protocol) and 6to4 tunneling services."



#inbound
#Loop back
#New-NetFirewallRule -ErrorAction Stop -Enabled True -PolicyStore $PolicyStore -Group $Group -Platform $Platform -LocalAddress ::1/128 -DisplayName "Loopback" -Description "Network software and utilities use loopback address to access a local computer's TCP/IP network resources."

#DHCP
New-NetFirewallRule -ErrorAction Stop -Enabled True -PolicyStore $PolicyStore -Group $Group -Platform $Platform -Protocol UDP -RemoteAddress DHCP6 -Service Dhcp -LocalPort 546 -RemotePort 547 -DisplayName "Domain Host Configuration Protocol" -Description "Allows DHCPv6 messages for stateful auto-configuration."

#IPHTTPS
New-NetFirewallRule -ErrorAction Stop -Enabled True -PolicyStore $PolicyStore -Group $Group -Platform $Platform -Protocol TCP -RemoteAddress Internet6 -Service iphlpsvc -LocalPort IPHTTPSIn -DisplayName "IPv6 over HTTPS" -Description "Rule to allow IPHTTPS tunneling technology to provide connectivity across HTTP proxies and firewalls."

#IPv6 Encapsulation
New-NetFirewallRule -ErrorAction Stop -Enabled True -PolicyStore $PolicyStore -Group $Group -Platform $Platform -Protocol 41 -Program System -LocalUser $NT_AUTHORITY_SYSTEM -DisplayName "IPv6 Encapsulation" -Description "Rule required to permit IPv6 traffic for ISATAP (Intra-Site Automatic Tunnel Addressing Protocol) and 6to4 tunneling services."



