
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

#
# Setup local variables:
#
$Group = "Software - DnsCrypt"
$Profile = "Private, Public"

# Ask user if he wants to load these rules
Update-Context $IPVersion $Direction $Group
if (!(Approve-Execute)) { exit }

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction SilentlyContinue

#
# DnsCrypt installation directories
#
$DnsCryptRoot = "%ProgramFiles%\Simple DNSCrypt x64"

#
# DnsCrypt rules
# TODO: remote servers from file, explicit TCP or UDP
#

# Test if installation exists on system
if ((Test-Installation "DnsCrypt" ([ref] $DnsCryptRoot)) -or $Force)
{
    $Program = "$DnsCryptRoot\dnscrypt-proxy\dnscrypt-proxy.exe"
    Test-File $Program
    New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
    -DisplayName "DnsCrypt" -Service Any -Program $Program `
    -PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
    -Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 53, 443 `
    -LocalUser $NT_AUTHORITY_System `
    -Description "DNSCrypt is a protocol that authenticates communications between a DNS client and a DNS resolver.
    It prevents DNS spoofing. It uses cryptographic signatures to verify that responses originate from the chosen DNS resolver and haven’t been tampered with.
    This rule applies to Simple DnsCrypt which uses dnscrypt-proxy."

    New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
    -DisplayName "DnsCrypt" -Service Any -Program $Program `
    -PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
    -Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 53, 443 `
    -LocalUser $NT_AUTHORITY_System `
    -Description "DNSCrypt is a protocol that authenticates communications between a DNS client and a DNS resolver.
    It prevents DNS spoofing. It uses cryptographic signatures to verify that responses originate from the chosen DNS resolver and haven’t been tampered with.
    This rule applies to Simple DnsCrypt which uses dnscrypt-proxy."
}
