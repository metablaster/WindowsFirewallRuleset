
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

#http://tools.ietf.org/html/rfc1918
#http://www.iana.org/assignments/icmp-parameters/icmp-parameters.xhtml

#setup variables:
$PolicyStore = "localhost" #local group policy
$Platform = "6.1+" #Windows 7 and above
$LocalUser = "D:(A;;CC;;;S-1-5-18)" #NT AUTHORITY\SYSTEM
$Group = "Core Networking - ICMPv4"
$Program = "System"
$Profile = "Any"
$Description = "Internet Control Message Protocol version 4"
$RemoteAddr = "Internet4"


#First remove all existing rules matching setup
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction Outbound -ErrorAction SilentlyContinue
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction Inbound -ErrorAction SilentlyContinue


#Destination filtering ( Outbound )
New-NetFirewallRule -ErrorAction Stop -Enabled True -Description $Description -Direction Outbound -Profile Private,Domain -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv4 -RemoteAddress LocalSubnet4 -DisplayName "Local Subnet"
#New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -LocalAddress $LocalAddr -Direction Outbound -Profile Private,Domain -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv4 -RemoteAddress 169.254.1.0-169.254.254.255 -DisplayName "Subnet APIPA"

#Type filtering ( Outbound )
#New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv4 -RemoteAddress $RemoteAddr  -IcmpType 0 -DisplayName "Echo Reply (0)"
#New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv4 -RemoteAddress $RemoteAddr  -IcmpType 3 -DisplayName "Destination Unreachable (3)"
#New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv4 -RemoteAddress $RemoteAddr  -IcmpType 5 -DisplayName "Redirect (5)"
New-NetFirewallRule -ErrorAction Stop -Enabled True -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv4 -RemoteAddress $RemoteAddr -IcmpType 8 -DisplayName "Echo Request (8)"
#New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv4 -RemoteAddress $RemoteAddr  -IcmpType 9 -DisplayName "Router Advertisement (9)"
#New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv4 -RemoteAddress $RemoteAddr  -IcmpType 10 -DisplayName "Router Selection (10)"
#New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv4 -RemoteAddress $RemoteAddr  -IcmpType 11 -DisplayName "Time Exceeded (11)"
#New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv4 -RemoteAddress $RemoteAddr  -IcmpType 12 -DisplayName "Parameter Problem (12)"
#New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv4 -RemoteAddress $RemoteAddr  -IcmpType 13 -DisplayName "Timestamp (13)"
#New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv4 -RemoteAddress $RemoteAddr  -IcmpType 14 -DisplayName "Timestamp Reply (14)"
#New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Direction Outbound -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv4 -RemoteAddress $RemoteAddr  -IcmpType 40 -DisplayName "Photuris (40)"


#Destination filtering ( Inboud )
New-NetFirewallRule -ErrorAction Stop -Enabled True -Description $Description -Profile Private,Domain -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv4 -RemoteAddress LocalSubnet4 -DisplayName "Local Subnet"
#New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile Private,Domain -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv4 -RemoteAddress 169.254.1.0-169.254.254.255 -DisplayName "Subnet APIPA"

#Type filtering ( Inbound )
New-NetFirewallRule -ErrorAction Stop -Enabled True -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv4 -RemoteAddress $RemoteAddr -IcmpType 0 -DisplayName "Echo Reply (0)"
New-NetFirewallRule -ErrorAction Stop -Enabled True -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv4 -RemoteAddress $RemoteAddr -IcmpType 3 -DisplayName "Destination Unreachable (3)"
New-NetFirewallRule -ErrorAction Stop -Enabled True -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv4 -RemoteAddress $RemoteAddr -IcmpType 5 -DisplayName "Redirect (5)"
#New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv4 -RemoteAddress $RemoteAddr -IcmpType 8 -DisplayName "Echo Request (8)"
#New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv4 -RemoteAddress $RemoteAddr -IcmpType 9 -DisplayName "Router Advertisement (9)"
#New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv4 -RemoteAddress $RemoteAddr -IcmpType 10 -DisplayName "Router Selection (10)"
New-NetFirewallRule -ErrorAction Stop -Enabled True -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv4 -RemoteAddress $RemoteAddr -IcmpType 11 -DisplayName "Time Exceeded (11)"
New-NetFirewallRule -ErrorAction Stop -Enabled True -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv4 -RemoteAddress $RemoteAddr -IcmpType 12 -DisplayName "Parameter Problem (12)"
#New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv4 -RemoteAddress $RemoteAddr -IcmpType 13 -DisplayName "Timestamp (13)"
New-NetFirewallRule -ErrorAction Stop -Enabled True -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv4 -RemoteAddress $RemoteAddr -IcmpType 14 -DisplayName "Timestamp Reply (14)"
#New-NetFirewallRule -ErrorAction Stop -Enabled False -Description $Description -Profile $Profile -Program $Program -Platform $Platform -PolicyStore $PolicyStore -Localuser $LocalUser -Group $Group -Protocol ICMPv4 -RemoteAddress $RemoteAddr -IcmpType 40 -DisplayName "Photuris (40)"