
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

# Ask user if he wants to load these rules
if (!(RunThis)) { exit }

#
# Setup local variables:
#
$Group = "Additional Networking"
$Interface = "Wired, Wireless"

#First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction Outbound -ErrorAction SilentlyContinue

#
# Firewall predefined rules related to networking not handled by other more strict scripts
#

#
# Cast to device
#

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Cast to Device functionality (qWave)" -Service QWAVE -Program "%SystemRoot%\System32\svchost.exe" `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile Private, Public -InterfaceType $Interface `
-Direction Outbound -Protocol TCP -LocalAddress Any -RemoteAddress PlayToDevice4 -LocalPort Any -RemotePort 2177 `
-LocalUser Any `
-Description "Outbound rule for the Cast to Device functionality to allow use of the Quality Windows Audio Video Experience Service.
Quality Windows Audio Video Experience (qWave) is a networking platform for Audio Video (AV) streaming applications on IP home networks.
qWave enhances AV streaming performance and reliability by ensuring network quality-of-service (QoS) for AV applications.
It provides mechanisms for admission control, run time monitoring and enforcement, application feedback, and traffic prioritization."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Cast to Device functionality (qWave)" -Service QWAVE -Program "%SystemRoot%\System32\svchost.exe" `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile Private, Public -InterfaceType $Interface `
-Direction Outbound -Protocol UDP -LocalAddress Any -RemoteAddress PlayToDevice4 -LocalPort Any -RemotePort 2177 `
-LocalUser Any `
-Description "Outbound rule for the Cast to Device functionality to allow use of the Quality Windows Audio Video Experience Service.
Quality Windows Audio Video Experience (qWave) is a networking platform for Audio Video (AV) streaming applications on IP home networks.
qWave enhances AV streaming performance and reliability by ensuring network quality-of-service (QoS) for AV applications.
It provides mechanisms for admission control, run time monitoring and enforcement, application feedback, and traffic prioritization."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Cast to Device streaming server (RTP)" -Service Any -Program "%SystemRoot%\System32\mdeserver.exe\" `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile Public -InterfaceType $Interface `
-Direction Outbound -Protocol UDP -LocalAddress Any -RemoteAddress PlayToDevice4 -LocalPort Any -RemotePort Any `
-LocalUser Any `
-Description "Rule for the Cast to Device server to allow streaming using RTSP and RTP."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Cast to Device streaming server (RTP)" -Service Any -Program "%SystemRoot%\System32\mdeserver.exe\" `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile Private -InterfaceType $Interface `
-Direction Outbound -Protocol UDP -LocalAddress Any -RemoteAddress LocalSubnet4 -LocalPort Any -RemotePort Any `
-LocalUser Any `
-Description "Rule for the Cast to Device server to allow streaming using RTSP and RTP."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Cast to Device streaming server (RTP)" -Service Any -Program "%SystemRoot%\System32\mdeserver.exe\" `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile Domain -InterfaceType $Interface `
-Direction Outbound -Protocol UDP -LocalAddress Any -RemoteAddress Any -LocalPort Any -RemotePort Any `
-LocalUser Any `
-Description "Rule for the Cast to Device server to allow streaming using RTSP and RTP."
