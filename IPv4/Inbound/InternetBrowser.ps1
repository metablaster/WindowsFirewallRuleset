
#
# Import global variables
#
. "$PSScriptRoot\..\..\Modules\GlobalVariables.ps1"

#
# Setup local variables:
#
$Group = "Internet Browser"
$Profile = "Private, Public"
$Interface = "Wired, Wireless"

#
# Browser installation directories
#
$ChromeRoot = "%SystemDrive%\Users\User\AppData\Local\Google"
$ChromeApp = "$ChromeRoot\Chrome\Application\chrome.exe"

#
# First remove all existing rules matching group
#
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction Inbound -ErrorAction SilentlyContinue

#
# Internet browser rules
#

#
# Google Chrome
#

New-NetFirewallRule -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Google Chrome mDNS IPv4" -Service Any -Program $ChromeApp `
-PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Inbound -Protocol UDP -LocalAddress Any -RemoteAddress 224.0.0.251 -LocalPort 5353 -RemotePort 5353 `
-EdgeTraversalPolicy Block -LocalUser $User `
-Description "The multicast Domain Name System (mDNS) resolves host names to IP addresses within small networks that do not include a local name server."

New-NetFirewallRule -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Google Chrome mDNS IPv6" -Service Any -Program $ChromeApp `
-PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Inbound -Protocol UDP -LocalAddress Any -RemoteAddress ff02::fb -LocalPort 5353 -RemotePort 5353 `
-EdgeTraversalPolicy Block -LocalUser $User `
-Description "The multicast Domain Name System (mDNS) resolves host names to IP addresses within small networks that do not include a local name server."

New-NetFirewallRule -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Google Chrome Chromecast" -Service Any -Program $ChromeApp `
-PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Inbound -Protocol UDP -LocalAddress Any -RemoteAddress 239.255.255.250 -LocalPort 1900 -RemotePort Any `
-EdgeTraversalPolicy Block -LocalUser $User `
-Description "Network Discovery to allow use of the Simple Service Discovery Protocol."
