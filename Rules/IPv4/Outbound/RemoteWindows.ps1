
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

. $PSScriptRoot\..\..\..\Config\ProjectSettings.ps1

# Check requirements
Initialize-Project -Abort

# Imports
. $PSScriptRoot\DirectionSetup.ps1
. $PSScriptRoot\..\IPSetup.ps1
Import-Module -Name Ruleset.Logging
Import-Module -Name Ruleset.UserInfo

# Setup local variables
$Group = "Remote Windows"
$Accept = "Outbound rules for remote Windows will be loaded, required for services such as remote desktop or remote registry"
$Deny = "Skip operation, outbound rules for remote Windows will not be loaded into firewall"

# User prompt
Update-Context "IPv$IPVersion" $Direction $Group @Logs
if (!(Approve-Execute -Accept $Accept -Deny $Deny @Logs)) { exit }

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore @Logs

#
# Windows system rules
# Rules that apply to Windows programs and utilities, which are not handled by predefined rules
# NOTE: There are no predefined rules for remote desktop
#

$Program = "%SystemRoot%\System32\mstsc.exe"
Test-File $Program @Logs

New-NetFirewallRule -DisplayName "Remote desktop - User Mode" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private, Domain `
	-Service Any -Program $Program -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress Any `
	-LocalPort Any -RemotePort 3389 `
	-LocalUser $UsersGroupSDDL `
	-InterfaceType $DefaultInterfaceterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Remote desktop connection.
Allows users to connect interactively to a remote computer.
To prevent remote use of this computer, clear the checkboxes on the Remote tab of the System
properties control panel item." `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Remote desktop - User Mode" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private, Domain `
	-Service Any -Program $Program -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Any `
	-LocalPort Any -RemotePort 3389 `
	-LocalUser $UsersGroupSDDL `
	-InterfaceType $DefaultInterfaceterface `
	-Description "Remote desktop connection.
Allows users to connect interactively to a remote computer.
To prevent remote use of this computer, clear the checkboxes on the Remote tab of the System
properties control panel item." `
	@Logs | Format-Output @Logs

Update-Log
