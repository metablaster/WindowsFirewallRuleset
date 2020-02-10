
<#
MIT License

Copyright (c) 2019, 2020 metablaster zebal@protonmail.ch

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

# Check requirements for this project
Import-Module -Name $PSScriptRoot\..\..\..\Modules\System
Test-SystemRequirements

# Includes
. $PSScriptRoot\DirectionSetup.ps1
. $PSScriptRoot\..\IPSetup.ps1
Import-Module -Name $PSScriptRoot\..\..\..\Modules\UserInfo
Import-Module -Name $PSScriptRoot\..\..\..\Modules\ProgramInfo
Import-Module -Name $PSScriptRoot\..\..\..\Modules\FirewallModule

#
# Setup local variables:
#
$Group = "Internet Browser"
$Profile = "Private, Public"

# Chromecast IP
# Adjust to the Chromecast IP in your local network
$CHROMECAST_IP = 192.168.8.50

# Ask user if he wants to load these rules
Update-Context $IPVersion $Direction $Group
if (!(Approve-Execute)) { exit }

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction SilentlyContinue

#
# Browser installation directories
#
$ChromeRoot = "%SystemDrive%\Users\User\AppData\Local\Google"

#
# Internet browser rules
#

#
# Google Chrome
#

# Test if installation exists on system
if ((Test-Installation "Chrome" ([ref] $ChromeRoot)) -or $Force)
{
    $ChromeApp = "$ChromeRoot\Chrome\Application\chrome.exe"
    Test-File $ChromeApp

    New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
    -DisplayName "Google Chrome mDNS IPv4" -Service Any -Program $ChromeApp `
    -PolicyStore $PolicyStore -Enabled False -Action Block -Group $Group -Profile $Profile -InterfaceType $Interface `
    -Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress 224.0.0.251 -LocalPort 5353 -RemotePort 5353 `
    -EdgeTraversalPolicy Block -LocalUser $UserAccountsSDDL -LocalOnlyMapping $false -LooseSourceMapping $false `
    -Description "The multicast Domain Name System (mDNS) resolves host names to IP addresses within small networks that do not include a local name server." | Format-Output

    New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
    -DisplayName "Google Chrome mDNS IPv6" -Service Any -Program $ChromeApp `
    -PolicyStore $PolicyStore -Enabled False -Action Block -Group $Group -Profile $Profile -InterfaceType $Interface `
    -Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress ff02::fb -LocalPort 5353 -RemotePort 5353 `
    -EdgeTraversalPolicy Block -LocalUser $UserAccountsSDDL -LocalOnlyMapping $false -LooseSourceMapping $false `
    -Description "The multicast Domain Name System (mDNS) resolves host names to IP addresses within small networks that do not include a local name server." | Format-Output

    New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
    -DisplayName "Google Chrome Chromecast" -Service Any -Program $ChromeApp `
    -PolicyStore $PolicyStore -Enabled False -Action Block -Group $Group -Profile $Profile -InterfaceType $Interface `
    -Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress $CHROMECAST_IP -LocalPort 32768-61000 -RemotePort 32768-61000 `
    -EdgeTraversalPolicy Block -LocalUser $UserAccountsSDDL -LocalOnlyMapping $false -LooseSourceMapping $false `
    -Description "Allow Chromecast Inbound UDP data" | Format-Output

    New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
    -DisplayName "Chrome QUIC" -Service Any -Program $ChromeApp `
    -PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
    -Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress Internet4 -LocalPort 443 -RemotePort Any `
    -EdgeTraversalPolicy Block -LocalUser $UserAccountsSDDL -LocalOnlyMapping $false -LooseSourceMapping $false `
    -Description "Quick UDP Internet Connections,
    Experimental transport layer network protocol developed by Google and implemented in 2013." | Format-Output
}
