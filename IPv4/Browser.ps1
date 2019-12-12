
#setup variables:
$Platform = "10.0+" #Windows 10 and above
$Group = "Browser"
$Profile = "Private, Public"
$Interface = "Wired, Wireless"
$PolicyStore = "localhost"
$Deubg = $false

#Valid users
#$USER
#$ADMIN
$NT_AUTHORITY_SYSTEM = "D:(A;;CC;;;S-1-5-18)"
$NT_AUTHORITY_LOCAL_SERVICE = "D:(A;;CC;;;S-1-5-19)"

#First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction Outbound -ErrorAction SilentlyContinue
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction Inbound -ErrorAction SilentlyContinue

#
# Internet browser rules
#

# Google Chrome
New-NetFirewallRule -Whatif:$Deubg -ErrorAction Continue -Platform $Platform `
-DisplayName "Google Chrome HTTP" -Program "%LocalAppData%\Google\Chrome\Application\chrome.exe" `
-PolicyStore $PolicyStore -Enabled True -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Any -LocalPort Any -RemotePort 80 `
-Description "HTTP access"
