
<#
MIT License

Project: "Windows Firewall Ruleset" serves to manage firewall on Windows systems
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019, 2020 metablaster zebal@protonmail.ch

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
$FirewallProfile = "Private,Domain"
$Description = "Broadcast"

#First remove all existing rules matching setup
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction Outbound -ErrorAction SilentlyContinue
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction Inbound -ErrorAction SilentlyContinue

#Destination address needs to be adjusted
New-NetFirewallRule -WhatIf -Description $Description -Direction Outbound -Profile $FirewallProfile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -ErrorAction Stop -RemoteAddress 255.255.255.255 -DisplayName "Limited Broadcast"
New-NetFirewallRule -WhatIf -Description $Description -Direction Outbound -Profile $FirewallProfile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -ErrorAction Stop -RemoteAddress 192.168.137.255 -InterfaceAlias "Local Area Connection* 4" -DisplayName "Microsoft Wireless WiFi adapter"
New-NetFirewallRule -WhatIf -Description $Description -Direction Outbound -Profile $FirewallProfile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -ErrorAction Stop -RemoteAddress 192.168.1.255 -DisplayName "Class C Broadcast"

#Inbound
New-NetFirewallRule -WhatIf -Description $Description -Profile $FirewallProfile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -ErrorAction Stop -LocalAddress 255.255.255.255 -DisplayName "Limited Broadcast"
New-NetFirewallRule -WhatIf -Description $Description -Profile $FirewallProfile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -ErrorAction Stop -LocalAddress 192.168.137.255 -InterfaceAlias "Local Area Connection* 4" -DisplayName "Microsoft Wireless WiFi adapter"
New-NetFirewallRule -WhatIf -Description $Description -Profile $FirewallProfile -Platform $Platform -PolicyStore $PolicyStore -Group $Group -Protocol $Protocol -ErrorAction Stop -LocalAddress 192.168.1.255 -DisplayName "Class C Broadcast"
