
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

<# http://en.wikipedia.org/wiki/Private_network
Address                          CIDR / Subnet Mask               Designation
-------------                    --------                         -----------
10.0.0.0 - 10.255.255.255        10.0.0.0/8 (255.0.0.0)           Class A
172.16.0.0 - 172.31.255.255      172.16.0.0/12 (255.240.0.0)      Class B
192.168.0.0 - 192.168.255.255    192.168.0.0/16 (255.255.0.0)     Class C
255.255.255.255                             ---                   Limited broadcast (Applies to All classes)
192.168.137.255                  192.168.137.0/24 (255.255.255.0) Microsoft Virtual Wifi (Part of Class C, if on C subnet)
169.254.0.0-169.254.255.255      169.254.0.0/16 (255.255.0.0)     Automatic Private IP Addressing APIPA
#>

# Test Powershell version required for this project
Import-Module -Name $PSScriptRoot\..\..\..\Modules\FirewallModule
Test-PowershellVersion $VersionCheck

# Includes
. $PSScriptRoot\DirectionSetup.ps1
. $PSScriptRoot\..\IPSetup.ps1
Import-Module -Name $PSScriptRoot\..\..\..\Modules\UserInfo

#
# Setup local variables:
#
$Profile = "Private, Domain"
$Group = "Broadcast"

# Ask user if he wants to load these rules
Update-Context $IPVersion $Direction $Group
if (!(Approve-Execute)) { exit }

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction SilentlyContinue

#
# TODO: curently handling only UDP, also broadcast falls into multicast space
#

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Limited Broadcast" -Service Any -Program System `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress 255.255.255.255 -LocalPort Any -RemotePort Any `
-LocalUser $NT_AUTHORITY_System -LocalOnlyMapping $false -LooseSourceMapping $false `
-Description "" | Format-Output

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "LAN Broadcast" -Service Any -Program System `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol UDP -LocalAddress $LocalHost -RemoteAddress $Broadcast -LocalPort Any -RemotePort Any `
-LocalUser $NT_AUTHORITY_System -LocalOnlyMapping $false -LooseSourceMapping $false `
-Description "" | Format-Output

# TODO: check if virtual adapter exists and apply rule

<# New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Microsoft Wireless WiFi adapter" -Service Any -Program System `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress 192.168.137.255 -LocalPort Any -RemotePort Any `
-LocalUser $NT_AUTHORITY_System -LocalOnlyMapping $false -LooseSourceMapping $false `
-Description ""
 #>
