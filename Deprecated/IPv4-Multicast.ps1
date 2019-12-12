<# http://www.iana.org/assignments/multicast-addresses/multicast-addresses.xhtml
Address Range                 Size       Designation
-------------                 ----       -----------
224.0.0.0 - 224.0.0.255       (/24)      Local Network Control Block
224.0.1.0 - 224.0.1.255       (/24)      Internetwork Control Block
224.0.2.0 - 224.0.255.255     (65024)    AD-HOC Block I
224.1.0.0 - 224.1.255.255     (/16)      RESERVED
224.2.0.0 - 224.2.255.255     (/16)      SDP/SAP Block
224.3.0.0 - 224.4.255.255     (2 /16s)   AD-HOC Block II
224.5.0.0 - 224.255.255.255   (251 /16s) RESERVED
225.0.0.0 - 231.255.255.255   (7 /8s)    RESERVED
232.0.0.0 - 232.255.255.255   (/8)       Source-Specific Multicast Block
233.0.0.0 - 233.251.255.255   (16515072) GLOP Block
233.252.0.0 - 233.255.255.255 (/14)      AD-HOC Block III
234.0.0.0 - 238.255.255.255   (5 /8s)    RESERVED
239.0.0.0 - 239.255.255.255   (/8)       Administratively Scoped Block

224.252.0.0/14 "DIS Transient Groups
#>

#setup variables:
$PolicyStore = "localhost" #local group policy
$Platform = "6.1+" #Windows 7 and above
$Protocol = "UDP"
$Group = "Core Networking - Multicast IPv4"
$Profile = "Private, Domain" #Boot time multicast dropped due to WFP Operation (The transition from boot-time to persistent filters could be several seconds, or even longer on a slow machine.)
$Description = "Multicast IPv4"


#First remove all existing rules matching setup
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction "Outbound" -ErrorAction SilentlyContinue
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction "Inbound" -ErrorAction SilentlyContinue

#Outbound
New-NetFirewallRule -ErrorAction Stop -Enabled True -Description $Description -Direction Outbound -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -RemoteAddress 224.0.0.0/24 -DisplayName "Local Network Control Block"
<#
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -RemoteAddress 224.0.1.0/24 -DisplayName "Internetwork Control Block"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -RemoteAddress 224.0.2.0-224.0.255.255 -DisplayName "AD-HOC Block I"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -RemoteAddress 224.2.0.0/16 -DisplayName "SDP/SAP Block"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -RemoteAddress 224.4.0.0/16 -DisplayName "AD-HOC Block II"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -RemoteAddress 224.252.0.0/14 -DisplayName "DIS Transient Groups"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -RemoteAddress 232.0.0.0/8 -DisplayName "Source-Specific Multicast Block"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -RemoteAddress 233.252.0.0/14 -DisplayName "AD-HOC Block III"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -RemoteAddress 234.0.0.0-234.255.255.255 -DisplayName "Unicast-Prefix-based IPv4 Multicast Addresses"
#>
New-NetFirewallRule -ErrorAction Stop -Enabled True -Description $Description -Direction Outbound -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -RemoteAddress 239.0.0.0-239.255.255.255	 -DisplayName "Organization-Local Scope Multicast"


#Inbound
New-NetFirewallRule -ErrorAction Stop -Enabled True -Description $Description -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -LocalAddress 224.0.0.0/24 -DisplayName "Local Network Control Block"
<#
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -LocalAddress 224.0.1.0/24 -DisplayName "Internetwork Control Block"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -LocalAddress 224.0.2.0-224.0.255.255 -DisplayName "AD-HOC Block I"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -LocalAddress 224.2.0.0/16 -DisplayName "SDP/SAP Block"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -LocalAddress 224.4.0.0/16 -DisplayName "AD-HOC Block II"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -LocalAddress 224.252.0.0/14 -DisplayName "DIS Transient Groups"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -LocalAddress 232.0.0.0/8 -DisplayName "Source-Specific Multicast Block"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -LocalAddress 233.252.0.0/14 -DisplayName "AD-HOC Block III"
New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -LocalAddress 234.0.0.0-234.255.255.255 -DisplayName "Unicast-Prefix-based IPv4 Multicast Addresses"
#>
New-NetFirewallRule -ErrorAction Stop -Enabled True -Description $Description -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -LocalAddress 239.0.0.0-239.255.255.255	 -DisplayName "Organization-Local Scope Multicast"

#Sepcialized
New-NetFirewallRule -ErrorAction Stop -Enabled True -Description $Description -Direction Outbound -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol 2 -RemoteAddress 224.0.0.22 -DisplayName "Local Network Control Block IGMP"
