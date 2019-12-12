#setup variables:
$PolicyStore = "localhost" #local group policy
$Platform = "6.1+" #Windows 7 and above
$Group = "Network Discovery - IPv4"
$Profile = "Private"
$NT_AUTHORITY_SYSTEM = "D:(A;;CC;;;S-1-5-18)"
$NT_AUTHORITY_LOCAL_SERVICE = "D:(A;;CC;;;S-1-5-19)"


#First remove all existing rules matching setup
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction Outbound -ErrorAction SilentlyContinue
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction Inbound -ErrorAction SilentlyContinue


#Network discovery
New-NetFirewallRule -ErrorAction Stop -Enabled True -PolicyStore $PolicyStore -Group $Group -Platform $Platform -Profile $Profile -Direction Outbound -Protocol TCP -RemoteAddress LocalSubnet4 -RemotePort 2869 -DisplayName "UPnP and UPnPHost IPv4" -Description "IPv4 Rule for Network Discovery to allow use of Universal Plug and Play."
New-NetFirewallRule -ErrorAction Stop -Enabled True -PolicyStore $PolicyStore -Group $Group -Platform $Platform -Profile $Profile -Direction Outbound -Protocol TCP -RemoteAddress LocalSubnet6 -RemotePort 2869 -DisplayName "UPnP and UPnPHost IPv6" -Description "IPv6 Rule for Network Discovery to allow use of Universal Plug and Play."

New-NetFirewallRule -ErrorAction Stop -Enabled True -PolicyStore $PolicyStore -Group $Group -Platform $Platform -Profile $Profile -Direction Outbound -Protocol UDP -RemoteAddress LocalSubnet4 -LocalPort 3702 -LocalUser $NT_AUTHORITY_LOCAL_SERVICE -DisplayName "Web Services for Devices (Pub WSD) IPv4" -Description "IPv4 Rule for Network Discovery to discover devices via Function Discovery."
New-NetFirewallRule -ErrorAction Stop -Enabled True -PolicyStore $PolicyStore -Group $Group -Platform $Platform -Profile $Profile -Direction Outbound -Protocol UDP -RemoteAddress LocalSubnet6 -LocalPort 3702 -LocalUser $NT_AUTHORITY_LOCAL_SERVICE -DisplayName "Web Services for Devices (Pub WSD) IPv6" -Description "IPv6 Rule for Network Discovery to discover devices via Function Discovery."

New-NetFirewallRule -ErrorAction Stop -Enabled True -PolicyStore $PolicyStore -Group $Group -Platform $Platform -Profile $Profile -Direction Outbound -Protocol UDP -RemoteAddress LocalSubnet4 -LocalPort 5355 -Service Dnscache -DisplayName "Link Local Multicast Name Resolution IPv4" -Description "IPv4 Rule for Network Discovery to allow Link Local Multicast Name Resolution."
New-NetFirewallRule -ErrorAction Stop -Enabled True -PolicyStore $PolicyStore -Group $Group -Platform $Platform -Profile $Profile -Direction Outbound -Protocol UDP -RemoteAddress LocalSubnet6 -LocalPort 5355 -Service Dnscache -DisplayName "Link Local Multicast Name Resolution IPv6" -Description "IPv6 Rule for Network Discovery to allow Link Local Multicast Name Resolution."

New-NetFirewallRule -ErrorAction Stop -Enabled True -PolicyStore $PolicyStore -Group $Group -Platform $Platform -Profile $Profile -Direction Outbound -Protocol UDP -RemoteAddress LocalSubnet6 -LocalPort 1900 -Service SSDPSRV -DisplayName "Simple Service Discovery Protocol IPv6" -Description "IPv6 Rule for Network Discovery to allow use of the Simple Service Discovery Protocol."



#File and printer sharing
New-NetFirewallRule -ErrorAction Stop -Enabled True -PolicyStore $PolicyStore -Group $Group -Platform $Platform -Profile $Profile -Direction Outbound -Protocol TCP -RemoteAddress LocalSubnet4 -RemotePort 5357 -LocalUser $NT_AUTHORITY_LOCAL_SERVICE -DisplayName "Web Services for Devices (WSD Events) IPv4" -Description "IPv4 rule for Network Discovery to allow WSDAPI Events via Function Discovery."
New-NetFirewallRule -ErrorAction Stop -Enabled True -PolicyStore $PolicyStore -Group $Group -Platform $Platform -Profile $Profile -Direction Outbound -Protocol TCP -RemoteAddress LocalSubnet6 -RemotePort 5357 -LocalUser $NT_AUTHORITY_LOCAL_SERVICE -DisplayName "Web Services for Devices (WSD Events) IPv6" -Description "IPv6 rule for Network Discovery to allow WSDAPI Events via Function Discovery."


#HomeGroup
New-NetFirewallRule -ErrorAction Stop -Enabled True -PolicyStore $PolicyStore -Group $Group -Platform $Platform -Profile $Profile -Direction Outbound -Protocol TCP -RemoteAddress LocalSubnet6 -RemotePort 3587 -DisplayName "HomeGroup (Peer Networking Grouping) IPv6" -Description "Separate rule to allow IPv6 Link local communication"
New-NetFirewallRule -ErrorAction Stop -Enabled True -PolicyStore $PolicyStore -Group $Group -Platform $Platform -Profile $Profile -Direction Outbound -Protocol UDP -RemoteAddress LocalSubnet6 -RemotePort 3540 -DisplayName "HomeGroup (PNRP) IPv6" -Description "Separate rule to allow IPv6 Link local communication"

New-NetFirewallRule -ErrorAction Stop -Enabled True -PolicyStore $PolicyStore -Group $Group -Platform $Platform -Profile $Profile -Direction Outbound -Protocol TCP -RemoteAddress LocalSubnet4 -RemotePort 3587 -Service p2psvc -DisplayName "HomeGroup (Peer Networking Grouping) IPv4" -Description "HomeGroup Peer Networking Grouping"
New-NetFirewallRule -ErrorAction Stop -Enabled True -PolicyStore $PolicyStore -Group $Group -Platform $Platform -Profile $Profile -Direction Outbound -Protocol UDP -RemoteAddress LocalSubnet4 -RemotePort 3540 -Service PNRPsvc -DisplayName "HomeGroup (PNRP) IPv4" -Description "HomeGroup (Pear Name Resolution Protocol)"


#Inbound
#Network Discovery
New-NetFirewallRule -ErrorAction Stop -Enabled True -PolicyStore $PolicyStore -Group $Group -Platform $Platform -Profile $Profile -Protocol UDP -RemoteAddress LocalSubnet4 -RemotePort 1900 -Service SSDPSRV -DisplayName "IPv4 Simple Service Discovery Protocol" -Description "IPv4 Rule for Network Discovery to allow use of the Simple Service Discovery Protocol."
New-NetFirewallRule -ErrorAction Stop -Enabled True -PolicyStore $PolicyStore -Group $Group -Platform $Platform -Profile $Profile -Protocol UDP -RemoteAddress LocalSubnet6 -LocalPort 1900 -Service SSDPSRV -DisplayName "IPv6 Simple Service Discovery Protocol" -Description "IPv6 Rule for Network Discovery to allow use of the Simple Service Discovery Protocol."

New-NetFirewallRule -ErrorAction Stop -Enabled True -PolicyStore $PolicyStore -Group $Group -Platform $Platform -Profile $Profile -Protocol TCP -RemoteAddress LocalSubnet6 -LocalPort 2869 -Program System -LocalUser $NT_AUTHORITY_SYSTEM -DisplayName "IPv6 Universal Plug and Play" -Description "IPv6 Rule for Network Discovery to allow use of Universal Plug and Play"
New-NetFirewallRule -ErrorAction Stop -Enabled True -PolicyStore $PolicyStore -Group $Group -Platform $Platform -Profile $Profile -Protocol TCP -RemoteAddress LocalSubnet6 -LocalPort 5357 -Program System -LocalUser $NT_AUTHORITY_SYSTEM -DisplayName "IPv6 Web Services for Devices (WSD Events)" -Description "IPv6 Rule for Network Discovery to discover devices via Function Discovery."

#HomeGroup
New-NetFirewallRule -ErrorAction Stop -Enabled True -PolicyStore $PolicyStore -Group $Group -Platform $Platform -Profile $Profile -Protocol TCP -RemoteAddress LocalSubnet6 -LocalPort 3587 -DisplayName "HomeGroup (Peer Networking Grouping) IPv6" -Description "Separate rule to allow IPv6 Link local communication"
New-NetFirewallRule -ErrorAction Stop -Enabled True -PolicyStore $PolicyStore -Group $Group -Platform $Platform -Profile $Profile -Protocol UDP -RemoteAddress LocalSubnet6 -LocalPort 3540 -RemotePort 3540 -DisplayName "HomeGroup (PNRP) IPv6" -Description "Separate rule to allow IPv6 Link local communication"

New-NetFirewallRule -ErrorAction Stop -Enabled True -PolicyStore $PolicyStore -Group $Group -Platform $Platform -Profile $Profile -Protocol TCP -RemoteAddress LocalSubnet4 -LocalPort 3587 -Service p2psvc -DisplayName "HomeGroup (Peer Networking Grouping) IPv4" -Description "HomeGroup Peer Networking Grouping"
New-NetFirewallRule -ErrorAction Stop -Enabled True -PolicyStore $PolicyStore -Group $Group -Platform $Platform -Profile $Profile -Protocol UDP -RemoteAddress LocalSubnet4 -LocalPort 3540 -Service PNRPsvc -DisplayName "HomeGroup (PNRP) IPv4" -Description "HomeGroup (Pear Name Resolution Protocol)"
