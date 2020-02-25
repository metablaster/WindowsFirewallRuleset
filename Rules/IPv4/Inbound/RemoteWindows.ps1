
<#
MIT License

Project: "Windows Firewall Ruleset" serves to manage firewall on Windows systems
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019, 2020 metablaster zebal@protonmail.ch

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

. $PSScriptRoot\..\..\..\Config\ProjectSettings.ps1

# Check requirements for this project
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.System
Test-SystemRequirements

# Includes
. $PSScriptRoot\DirectionSetup.ps1
. $PSScriptRoot\..\IPSetup.ps1
Import-Module -Name $ProjectRoot\Modules\Project.Windows.UserInfo
Import-Module -Name $ProjectRoot\Modules\Project.Windows.ProgramInfo
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Logging
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Utility

#
# Setup local variables:
#
$Group = "Remote Windows"
# $Profile = "Private, Public"

# Ask user if he wants to load these rules
Update-Context "IPv$IPVersion" $Direction $Group @Logs
if (!(Approve-Execute @Logs)) { exit }

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction SilentlyContinue

#
# Windows system rules
# Rules that apply to Windows programs and utilities, which are not handled by predefined rules
#

#
# Predefined rueles for remote desktop, here split for private and public profile
#

$Program = "%SystemRoot%\System32\RdpSa.exe"
Test-File $Program

New-NetFirewallRule -Platform $Platform `
-DisplayName "Remote desktop - Shadow" -Service Any -Program $Program `
-PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile Public -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Any -LocalPort Any -RemotePort Any `
-EdgeTraversalPolicy DeferToApp -LocalUser Any `
-Description "Inbound rule for the Remote Desktop service to allow shadowing of an existing Remote Desktop session. " | Format-Output

New-NetFirewallRule -Platform $Platform `
-DisplayName "Remote desktop - Shadow" -Service Any -Program $Program `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile Private, Domain -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress LocalSubnet4 -LocalPort Any -RemotePort Any `
-EdgeTraversalPolicy DeferToApp -LocalUser Any `
-Description "Inbound rule for the Remote Desktop service to allow shadowing of an existing Remote Desktop session. " | Format-Output

New-NetFirewallRule -Platform $Platform `
-DisplayName "Remote desktop - User Mode" -Service TermService -Program $ServiceHost `
-PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile Public -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Any -LocalPort 3389 -RemotePort Any `
-EdgeTraversalPolicy Block -LocalUser Any `
-Description "Allows users to connect interactively to a remote computer.
To prevent remote use of this computer, clear the checkboxes on the Remote tab of the System properties control panel item." | Format-Output

New-NetFirewallRule -Platform $Platform `
-DisplayName "Remote desktop - User Mode" -Service TermService -Program $ServiceHost `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile Private, Domain -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress LocalSubnet4 -LocalPort 3389 -RemotePort Any `
-EdgeTraversalPolicy Block -LocalUser Any `
-Description "Allows users to connect interactively to a remote computer.
To prevent remote use of this computer, clear the checkboxes on the Remote tab of the System properties control panel item." | Format-Output

New-NetFirewallRule -Platform $Platform `
-DisplayName "Remote desktop - User Mode" -Service TermService -Program $ServiceHost `
-PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile Public -InterfaceType $Interface `
-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress Any -LocalPort 3389 -RemotePort Any `
-EdgeTraversalPolicy Block -LocalUser Any -LocalOnlyMapping $false -LooseSourceMapping $false `
-Description "Allows users to connect interactively to a remote computer.
To prevent remote use of this computer, clear the checkboxes on the Remote tab of the System properties control panel item." | Format-Output

New-NetFirewallRule -Platform $Platform `
-DisplayName "Remote desktop - User Mode" -Service TermService -Program $ServiceHost `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile Private, Domain -InterfaceType $Interface `
-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress LocalSubnet4 -LocalPort 3389 -RemotePort Any `
-EdgeTraversalPolicy Block -LocalUser Any -LocalOnlyMapping $false -LooseSourceMapping $false `
-Description "Allows users to connect interactively to a remote computer.
To prevent remote use of this computer, clear the checkboxes on the Remote tab of the System properties control panel item." | Format-Output

New-NetFirewallRule -Platform $Platform `
-DisplayName "Remote desktop - WebSocket" -Service Any -Program System `
-PolicyStore $PolicyStore -Enabled False -Action Block -Group $Group -Profile Public -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Any -LocalPort 3387 -RemotePort Any `
-EdgeTraversalPolicy Block -LocalUser $NT_AUTHORITY_System `
-Description "rule for the Remote Desktop service to allow RDP over WebSocket traffic." | Format-Output

New-NetFirewallRule -Platform $Platform `
-DisplayName "Remote desktop - WebSocket" -Service Any -Program System `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile Private, Domain -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Any -LocalPort 3387 -RemotePort Any `
-EdgeTraversalPolicy Block -LocalUser $NT_AUTHORITY_System `
-Description "rule for the Remote Desktop service to allow RDP over WebSocket traffic." | Format-Output

New-NetFirewallRule -Platform $Platform `
-DisplayName "Remote desktop - WebSocket Secure" -Service Any -Program System `
-PolicyStore $PolicyStore -Enabled False -Action Block -Group $Group -Profile Public -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Any -LocalPort 3392 -RemotePort Any `
-EdgeTraversalPolicy Block -LocalUser $NT_AUTHORITY_System `
-Description "rule for the Remote Desktop service to allow RDP over WebSocket traffic." | Format-Output

New-NetFirewallRule -Platform $Platform `
-DisplayName "Remote desktop - WebSocket Secure" -Service Any -Program System `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile Private, Domain -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Any -LocalPort 3392 -RemotePort Any `
-EdgeTraversalPolicy Block -LocalUser $NT_AUTHORITY_System `
-Description "rule for the Remote Desktop service to allow RDP over WebSocket traffic." | Format-Output
