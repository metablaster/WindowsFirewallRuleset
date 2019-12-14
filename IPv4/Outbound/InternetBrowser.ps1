
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
$ChromeRoot = "%LocalAppData%\Google"
$ChromeApp = "$ChromeRoot\Chrome\Application\chrome.exe"
$ChromeUpdate = "$ChromeRoot\Update\GoogleUpdate.exe"
#First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction Outbound -ErrorAction SilentlyContinue

#
# Internet browser rules
#

#
# Google Chrome
#

New-NetFirewallRule -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Google Chrome HTTP" -Service Any -Program $ChromeApp `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80 `
-LocalUser $User `
-Description "Hyper text transfer protocol."

New-NetFirewallRule -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Google Chrome HTTPS" -Service Any -Program $ChromeApp `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
-LocalUser $User `
-Description "Hyper text transfer protocol over SSL."

New-NetFirewallRule -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Google Chrome FTP" -Service Any -Program $ChromeApp `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 21 `
-LocalUser $User `
-Description "File transfer protocol."

New-NetFirewallRule -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Google Chrome GCM" -Service Any -Program $ChromeApp `
-PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 5228 `
-LocalUser $User `
-Description "Google cloud messaging, google services use 5228, hangouts, google play, GCP.. etc use 5228."

New-NetFirewallRule -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Google Chrome QUIC" -Service Any -Program $ChromeApp `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol UDP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
-LocalUser $User `
-Description "Quick UDP Internet Connections,
Experimental transport layer network protocol developed by Google and implemented in 2013."

New-NetFirewallRule -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Google Chrome XMPP" -Service Any -Program $ChromeApp `
-PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 5222 `
-LocalUser $User `
-Description "Extensible Messaging and Presence Protocol.
Google Drive (Talk), Cloud printing, Chrome Remote Desktop, Chrome Sync (with fallback to 443 if 5222 is blocked)."

New-NetFirewallRule -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Google Chrome mDNS IPv4" -Service Any -Program $ChromeApp `
-PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol UDP -LocalAddress Any -RemoteAddress 224.0.0.251 -LocalPort 5353 -RemotePort 5353 `
-LocalUser $User `
-Description "The multicast Domain Name System (mDNS) resolves host names to IP addresses within small networks that do not include a local name server."

New-NetFirewallRule -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Google Chrome mDNS IPv6" -Service Any -Program $ChromeApp `
-PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol UDP -LocalAddress Any -RemoteAddress ff02::fb -LocalPort 5353 -RemotePort 5353 `
-LocalUser $User `
-Description "The multicast Domain Name System (mDNS) resolves host names to IP addresses within small networks that do not include a local name server."

New-NetFirewallRule -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Google Chrome Chromecast" -Service Any -Program $ChromeApp `
-PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol UDP -LocalAddress Any -RemoteAddress 239.255.255.250 -LocalPort Any -RemotePort 1900 `
-LocalUser $User `
-Description "Network Discovery to allow use of the Simple Service Discovery Protocol. "

New-NetFirewallRule -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Google Chrome Update" -Service Any -Program $ChromeUpdate `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
-LocalUser $User `
-Description "Update google products"
