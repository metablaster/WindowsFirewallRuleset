
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
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

<#
.SYNOPSIS
Inbound firewall rules for Windows remoting programs and services

.DESCRIPTION
Rules which apply to Windows remoting programs and services,
which are not handled by predefined rules

.EXAMPLE
PS> .\RemoteWindows.ps1

.INPUTS
None. You cannot pipe objects to RemoteWindows.ps1

.OUTPUTS
None. RemoteWindows.ps1 does not generate any output

.NOTES
NOTE: Following rules from predefined groups are used:
1. Remote Desktop
2. Remote Desktop (WebSocket)
#>

#region Initialization
#Requires -RunAsAdministrator
. $PSScriptRoot\..\..\..\Config\ProjectSettings.ps1

# Check requirements
Initialize-Project -Abort

# Imports
. $PSScriptRoot\DirectionSetup.ps1
Import-Module -Name Ruleset.UserInfo

# Setup local variables
$Group = "Remote Windows"
$Accept = "Inbound rules for remote Windows will be loaded, required for services such as remote desktop or remote registry"
$Deny = "Skip operation, inbound rules for remote Windows will not be loaded into firewall"

# User prompt
Update-Context "IPv$IPVersion" $Direction $Group
if (!(Approve-Execute -Accept $Accept -Deny $Deny)) { exit }
#endregion

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore

#
# Predefined rules for remote desktop, here split for private and public profile
#

$Program = "%SystemRoot%\System32\RdpSa.exe"
Test-File $Program

New-NetFirewallRule -DisplayName "Remote desktop - Shadow" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Public `
	-Service Any -Program $Program -Group $Group `
	-Enabled True -Action Block -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Any `
	-LocalPort Any -RemotePort Any `
	-LocalUser Any -EdgeTraversalPolicy DeferToApp `
	-InterfaceType $DefaultInterface `
	-Description "Inbound rule for the Remote Desktop service to allow shadowing of an existing
Remote Desktop session. " | Format-Output

New-NetFirewallRule -DisplayName "Remote desktop - Shadow" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private, Domain `
	-Service Any -Program $Program -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress LocalSubnet4 `
	-LocalPort Any -RemotePort Any `
	-LocalUser Any -EdgeTraversalPolicy DeferToApp `
	-InterfaceType $DefaultInterface `
	-Description "Inbound rule for the Remote Desktop service to allow shadowing of an existing
Remote Desktop session. " | Format-Output

New-NetFirewallRule -DisplayName "Remote desktop - User Mode" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Public `
	-Service TermService -Program $ServiceHost -Group $Group `
	-Enabled True -Action Block -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Any `
	-LocalPort 3389 -RemotePort Any `
	-LocalUser Any -EdgeTraversalPolicy Block `
	-InterfaceType $DefaultInterface `
	-Description "Allows users to connect interactively to a remote computer.
To prevent remote use of this computer, clear the checkboxes on the Remote tab of the System
properties control panel item." | Format-Output

New-NetFirewallRule -DisplayName "Remote desktop - User Mode" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private, Domain `
	-Service TermService -Program $ServiceHost -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress LocalSubnet4 `
	-LocalPort 3389 -RemotePort Any `
	-LocalUser Any -EdgeTraversalPolicy Block `
	-InterfaceType $DefaultInterface `
	-Description "Allows users to connect interactively to a remote computer.
To prevent remote use of this computer, clear the checkboxes on the Remote tab of the System
properties control panel item." | Format-Output

New-NetFirewallRule -DisplayName "Remote desktop - User Mode" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Public `
	-Service TermService -Program $ServiceHost -Group $Group `
	-Enabled True -Action Block -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress Any `
	-LocalPort 3389 -RemotePort Any `
	-LocalUser Any -EdgeTraversalPolicy Block `
	-InterfaceType $DefaultInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Allows users to connect interactively to a remote computer.
To prevent remote use of this computer, clear the checkboxes on the Remote tab of the System
properties control panel item." | Format-Output

New-NetFirewallRule -DisplayName "Remote desktop - User Mode" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private, Domain `
	-Service TermService -Program $ServiceHost -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress LocalSubnet4 `
	-LocalPort 3389 -RemotePort Any `
	-LocalUser Any -EdgeTraversalPolicy Block `
	-InterfaceType $DefaultInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Allows users to connect interactively to a remote computer.
To prevent remote use of this computer, clear the checkboxes on the Remote tab of the System
properties control panel item." | Format-Output

New-NetFirewallRule -DisplayName "Remote desktop - WebSocket" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Public `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Block -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Any `
	-LocalPort 3387 -RemotePort Any `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-InterfaceType $DefaultInterface `
	-Description "rule for the Remote Desktop service to allow RDP over WebSocket traffic." |
Format-Output

New-NetFirewallRule -DisplayName "Remote desktop - WebSocket" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private, Domain `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Any `
	-LocalPort 3387 -RemotePort Any `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-InterfaceType $DefaultInterface `
	-Description "rule for the Remote Desktop service to allow RDP over WebSocket traffic." |
Format-Output

New-NetFirewallRule -DisplayName "Remote desktop - WebSocket Secure" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Public `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Block -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Any `
	-LocalPort 3392 -RemotePort Any `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-InterfaceType $DefaultInterface `
	-Description "rule for the Remote Desktop service to allow RDP over WebSocket traffic." |
Format-Output

New-NetFirewallRule -DisplayName "Remote desktop - WebSocket Secure" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private, Domain `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Any `
	-LocalPort 3392 -RemotePort Any `
	-LocalUser $LocalSystem -EdgeTraversalPolicy Block `
	-InterfaceType $DefaultInterface `
	-Description "rule for the Remote Desktop service to allow RDP over WebSocket traffic." |
Format-Output

Update-Log
