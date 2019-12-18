
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

#First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group "Store Apps" -Direction Outbound -ErrorAction SilentlyContinue

#
# Firewall predefined rules for Microsoft store Apps
#

# New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
# -DisplayName "Store apps for Administrators" -Service Any -Program Any `
# -PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile Any -InterfaceType $Interface `
# -Direction $Direction -Protocol Any -LocalAddress Any -RemoteAddress Any -LocalPort Any -RemotePort Any `
# -EdgeTraversalPolicy Block -LocalUser Any -Owner $User -Package "Microsoft.SkypeApp_14.54.91.0_x64__kzf8qxf38zg5c" `
# -Description "Block admin activity for all apps.
# Administrators should have limited or no connectivity at all for maximum security."

Set-PackageOutboundRules
