
<#
MIT License

Copyright (c) 2019 metablaster zebal@protonmail.ch

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

#
# Import global variables
#
. "$PSScriptRoot\..\..\Modules\GlobalVariables.ps1"
if (!(RunThis)) { exit }

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

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Google Chrome mDNS IPv4" -Service Any -Program $ChromeApp `
-PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Inbound -Protocol UDP -LocalAddress Any -RemoteAddress 224.0.0.251 -LocalPort 5353 -RemotePort 5353 `
-EdgeTraversalPolicy Block -LocalUser $User `
-Description "The multicast Domain Name System (mDNS) resolves host names to IP addresses within small networks that do not include a local name server."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Google Chrome mDNS IPv6" -Service Any -Program $ChromeApp `
-PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Inbound -Protocol UDP -LocalAddress Any -RemoteAddress ff02::fb -LocalPort 5353 -RemotePort 5353 `
-EdgeTraversalPolicy Block -LocalUser $User `
-Description "The multicast Domain Name System (mDNS) resolves host names to IP addresses within small networks that do not include a local name server."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Google Chrome Chromecast" -Service Any -Program $ChromeApp `
-PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Inbound -Protocol UDP -LocalAddress Any -RemoteAddress 239.255.255.250 -LocalPort 1900 -RemotePort Any `
-EdgeTraversalPolicy Block -LocalUser $User `
-Description "Network Discovery to allow use of the Simple Service Discovery Protocol."
