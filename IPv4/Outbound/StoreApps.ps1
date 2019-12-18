
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
$Group = "Store Apps"
$Profile = "Private, Public"
$Direction = "Outbound"
# TODO: setting owner does not work
$OwnerSID = "Any" #Get-UserSID("$UserName")

#First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction SilentlyContinue

#
# Firewall predefined rules for Microsoft store Apps
#

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Store apps for Administrators" -Service Any -Program Any `
-PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile Any -InterfaceType $Interface `
-Direction $Direction -Protocol Any -LocalAddress Any -RemoteAddress Any -LocalPort Any -RemotePort Any `
-LocalUser Any -Owner (Get-UserSID("$AdminName")) -Package "S-1-15-2-1" `
-Description "Block admin activity for all apps.
Administrators should have limited or no connectivity at all for maximum security."

Get-AppxPackage -User $UserName -PackageTypeFilter Bundle | ForEach-Object {
    
    $PackageSID = Get-AppSID($_.InstallLocation)

    New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
    -DisplayName $_.Name -Service Any -Program Any `
    -PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
    -Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
    -LocalUser Any -Owner $OwnerSID -Package $PackageSID `
    -Description "Store apps generated rule."        
}
