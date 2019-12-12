<# http://en.wikipedia.org/wiki/Private_network
Address                          CIDR / Subnet Mask               Designation
-------------                    --------                         -----------
10.0.0.0 - 10.255.255.255        10.0.0.0/8 (255.0.0.0)           Class A
172.16.0.0 - 172.31.255.255      172.16.0.0/12 (255.240.0.0)      Class B
192.168.0.0 - 192.168.255.255    192.168.0.0/16 (255.255.0.0)     Class C
255.255.255.255                             ---                   Limited broadcast (Applies to All classes)
192.168.137.255                  192.168.137.0/24 (255.255.255.0) Microsoft Virtual Wifi (Part of Class C)
169.254.0.0-169.254.255.255      169.254.0.0/16 (255.255.0.0)     Automatic Private IP Addressing APIPA
#>


#setup variables:
$PolicyStore = "localhost" #local group policy
$Platform = "6.1+" #Windows 7 and above
$Protocol = "UDP"
$Group = "Core Networking - Broadcast TEST"
$Profile = "Private,Domain"
$Description = "Broadcast"

#First remove all existing rules matching setup
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction Outbound -ErrorAction SilentlyContinue
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction Inbound -ErrorAction SilentlyContinue

#Destination address needs to be adjusted
New-NetFirewallRule -Whatif -Description $Description -Direction Outbound -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -ErrorAction Stop -RemoteAddress 255.255.255.255 -DisplayName "Limited Broadcast"
New-NetFirewallRule -Whatif -Description $Description -Direction Outbound -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -ErrorAction Stop -RemoteAddress 192.168.137.255 -InterfaceAlias "Local Area Connection* 4" -DisplayName "Microsoft Wireless WiFi adapter"
New-NetFirewallRule -Whatif -Description $Description -Direction Outbound -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -ErrorAction Stop -RemoteAddress 192.168.1.255 -DisplayName "Class C Broadcast"

#Inbound
New-NetFirewallRule -Whatif -Description $Description -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -ErrorAction Stop -LocalAddress 255.255.255.255 -DisplayName "Limited Broadcast"
New-NetFirewallRule -Whatif -Description $Description -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -ErrorAction Stop -LocalAddress 192.168.137.255 -InterfaceAlias "Local Area Connection* 4" -DisplayName "Microsoft Wireless WiFi adapter"
New-NetFirewallRule -Whatif -Description $Description -Profile $Profile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -ErrorAction Stop -LocalAddress 192.168.1.255 -DisplayName "Class C Broadcast"