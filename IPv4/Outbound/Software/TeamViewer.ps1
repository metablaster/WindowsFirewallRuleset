
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

# Includes
Import-Module -Name $PSScriptRoot\..\..\..\FirewallModule

# Ask user if he wants to load these rules
if (!(Approve-Execute)) { exit }

#
# Setup local variables:
#
$Group = "Software - TeamViewer"
$Profile = "Any"
$Direction = "Outbound"

#
# TeamViewer installation directories
#
$TeamViewerRoot = "%ProgramFiles(x86)%\TeamViewer"


# Test if installation exists on system
$status = Test-InstallRoot "TeamViewer" ([ref]$TeamViewerRoot)

# if (!(Test-InstallRoot "TeamViewer" ([ref]$TeamViewerRoot)))
# {
#     $script = Split-Path -Leaf $MyInvocation.ScriptName
#     if (Approve-Execute "Installation path is incorrect or program not installed,
#     if you installed program elsewhere please adjust the path in $script and re-run this script later again"
#     "Do you want to skip loading these rules?") { exit }
# }

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction SilentlyContinue

#
# Rules for TeamViewer remote control
#

if ($status) { Test-File "$TeamViewerRoot\TeamViewer.exe" }
New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Teamviewer Remote Control Application" -Service Any -Program "$TeamViewerRoot\TeamViewer.exe" `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Any -LocalPort Any -RemotePort 80, 443, 5938 `
-LocalUser $UserAccountsSDDL `
-Description ""

if ($status) { Test-File "$TeamViewerRoot\TeamViewer_Service.exe" }
New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Teamviewer Remote Control Service" -Service Any -Program "$TeamViewerRoot\TeamViewer_Service.exe" `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Any -LocalPort Any -RemotePort 80, 443, 5938 `
-LocalUser $UserAccountsSDDL `
-Description ""
