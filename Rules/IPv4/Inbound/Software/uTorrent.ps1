
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

# Includes
. $PSScriptRoot\..\DirectionSetup.ps1
. $PSScriptRoot\..\..\IPSetup.ps1
Import-Module -Name $PSScriptRoot\..\..\..\..\Modules\UserInfo
Import-Module -Name $PSScriptRoot\..\..\..\..\Modules\ProgramInfo
Import-Module -Name $PSScriptRoot\..\..\..\..\Modules\FirewallModule

# Test Powershell version required for this project
Test-PowershellVersion $VersionCheck

#
# Setup local variables:
#
$Group = "Software - uTorrent"
$Profile = "Private, Public"

# Ask user if he wants to load these rules
Update-Context $IPVersion $Direction $Group
if (!(Approve-Execute)) { exit }

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction SilentlyContinue

#
# Steam installation directories
#
$uTorrentRoot = "%SystemDrive%\Users\User\AppData\Local\uTorrent"

#
# Rules for uTorrent client
#

# Test if installation exists on system
if ((Test-Installation "uTorrent" ([ref] $uTorrentRoot)) -or $Force)
{
    $Program = "$uTorrentRoot\uTorrent.exe"
    Test-File $Program
    New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
    -DisplayName "uTorrent - DHT" -Service Any -Program $Program `
    -PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
    -Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress Any -LocalPort 1161 -RemotePort 1024-65535 `
    -EdgeTraversalPolicy DeferToApp -LocalUser $UserAccountsSDDL -LocalOnlyMapping $false -LooseSourceMapping $false `
    -Description "BitTorrent UDP listener, usualy for DHT." | Format-Output

    New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
    -DisplayName "uTorrent - Listening port" -Service Any -Program $Program `
    -PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
    -Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Any -LocalPort 1161 -RemotePort 1024-65535 `
    -EdgeTraversalPolicy DeferToApp -LocalUser $UserAccountsSDDL `
    -Description "BitTorrent TCP listener." | Format-Output

    New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
    -DisplayName "uTorrent - Local Peer discovery" -Service Any -Program $Program `
    -PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
    -Direction $Direction -Protocol UDP -LocalAddress 224.0.0.0-239.255.255.255 -RemoteAddress LocalSubnet4 -LocalPort 6771 -RemotePort 6771 `
    -EdgeTraversalPolicy DeferToApp -LocalUser $UserAccountsSDDL -LocalOnlyMapping $false -LooseSourceMapping $false `
    -Description "UDP multicast search to identify other peers in your subnet that are also on torrents you are on." | Format-Output

    New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
    -DisplayName "uTorrent - Web UI" -Service Any -Program $Program `
    -PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
    -Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Any -LocalPort 8080, 10000 -RemotePort Any `
    -EdgeTraversalPolicy Allow -LocalUser $UserAccountsSDDL `
    -Description "BitTorrent Remote control from browser." | Format-Output
}
