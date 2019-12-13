#http://tools.ietf.org/html/rfc1918
#http://www.iana.org/assignments/icmp-parameters/icmp-parameters.xhtml

#setup variables:
$PolicyStore = "localhost" #local group policy
$Platform = "10.0+" #Windows 10 and above
$NT_AUTHORITY_SYSTEM = "D:(A;;CC;;;S-1-5-18)"
$Group = "ICMPv4"
$Program = "System"
$Profile = "Public"
$Interface = "Wired, Wireless"
$Description = "Internet Control Message Protocol version 4"
$RemoteAddr = "Internet4"
$OnError = "Stop"
$Deubg = $false


#First remove all existing rules matching setup
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction Inbound -ErrorAction SilentlyContinue

#
# Destination filtering
#
New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "ICMP Local Subnet" -Program $Program `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile Private, Domain -InterfaceType $Interface `
-Direction Inbound -Protocol ICMPv4 -IcmpType 0 -LocalAddress Any -RemoteAddress LocalSubnet4 `
-Localuser $NT_AUTHORITY_SYSTEM -Description $Description

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "ICMP Subnet APIPA" -Program $Program `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile Private, Domain -InterfaceType $Interface `
-Direction Inbound -Protocol ICMPv4 -IcmpType 0 -LocalAddress Any -RemoteAddress 169.254.1.0-169.254.254.255 `
-Localuser $NT_AUTHORITY_SYSTEM -Description $Description

#
# Type filtering
#
New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Echo Reply" -Program $Program `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Inbound -Protocol ICMPv4 -IcmpType 0 -LocalAddress Any -RemoteAddress $RemoteAddr `
-Localuser $NT_AUTHORITY_SYSTEM -Description $Description

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Destination Unreachable" -Program $Program `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Inbound -Protocol ICMPv4 -IcmpType 3 -LocalAddress Any -RemoteAddress $RemoteAddr `
-Localuser $NT_AUTHORITY_SYSTEM -Description $Description

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Redirect" -Program $Program `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Inbound -Protocol ICMPv4 -IcmpType 5 -LocalAddress Any -RemoteAddress $RemoteAddr `
-Localuser $NT_AUTHORITY_SYSTEM -Description $Description

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Echo Request" -Program $Program `
-PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Inbound -Protocol ICMPv4 -IcmpType 8 -LocalAddress Any -RemoteAddress $RemoteAddr `
-Localuser $NT_AUTHORITY_SYSTEM -Description $Description

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Router Advertisement" -Program $Program `
-PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Inbound -Protocol ICMPv4 -IcmpType 9 -LocalAddress Any -RemoteAddress $RemoteAddr `
-Localuser $NT_AUTHORITY_SYSTEM -Description $Description

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Router Selection" -Program $Program `
-PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Inbound -Protocol ICMPv4 -IcmpType 10 -LocalAddress Any -RemoteAddress $RemoteAddr `
-Localuser $NT_AUTHORITY_SYSTEM -Description $Description

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Time Exceeded" -Program $Program `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Inbound -Protocol ICMPv4 -IcmpType 11 -LocalAddress Any -RemoteAddress $RemoteAddr `
-Localuser $NT_AUTHORITY_SYSTEM -Description $Description

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Parameter Problem" -Program $Program `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Inbound -Protocol ICMPv4 -IcmpType 12 -LocalAddress Any -RemoteAddress $RemoteAddr `
-Localuser $NT_AUTHORITY_SYSTEM -Description $Description

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Timestamp" -Program $Program `
-PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Inbound -Protocol ICMPv4 -IcmpType 13 -LocalAddress Any -RemoteAddress $RemoteAddr `
-Localuser $NT_AUTHORITY_SYSTEM -Description $Description

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Timestamp Reply" -Program $Program `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Inbound -Protocol ICMPv4 -IcmpType 14 -LocalAddress Any -RemoteAddress $RemoteAddr `
-Localuser $NT_AUTHORITY_SYSTEM -Description $Description

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Photuris" -Program $Program `
-PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Inbound -Protocol ICMPv4 -IcmpType 40 -LocalAddress Any -RemoteAddress $RemoteAddr `
-Localuser $NT_AUTHORITY_SYSTEM -Description $Description
