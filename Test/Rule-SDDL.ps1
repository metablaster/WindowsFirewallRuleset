
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

#
# Unit test for adding rules based on computer accounts
#

#Requires -RunAsAdministrator
. $PSScriptRoot\..\Config\ProjectSettings.ps1

# Check requirements for this project
Initialize-Project

# Imports
. $PSScriptRoot\ContextSetup.ps1
Import-Module -Name Project.AllPlatforms.Logging
Import-Module -Name Project.Windows.UserInfo

# Ask user if he wants to load these rules
Update-Context $TestContext "IPv$IPVersion" $Direction
if (!(Approve-Execute @Logs)) { exit }

$Group = "Test - Get-SDDL"
$FirewallProfile = "Any"

Start-Test
# TODO: Need separate test cases for users, groups and built in domains

New-Test "Remove-NetFirewallRule"
# Remove previous test
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore @Logs

#
# Test Groups, Users and NT AUTHORITY
#

New-Test "Get-SDDL + Merge-SDDL"
$RuleUsers = Get-SDDL -Group "Users", "Administrators" -User "User", "Admin" @Logs
$RuleSystemUsers = Get-SDDL -Domain "NT AUTHORITY" -User "SYSTEM", "LOCAL SERVICE" @Logs
Merge-SDDL ([ref] $RuleUsers) $RuleSystemUsers @Logs
$RuleUsers

New-Test "New-NetFirewallRule"

New-NetFirewallRule -DisplayName "Get-SDDL mix" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Any `
	-LocalPort Any -RemotePort Any `
	-LocalUser $RuleUsers `
	-InterfaceType $Interface `
	-Description "Get-SDDL test rule for mixture of NT AUTHORITY and users groups" `
	@Logs | Format-Output @Logs

#
# Test APPLICATION PACKAGE AUTHORITY
#

New-Test "Get-SDDL + Merge-SDDL for APPLICATION PACKAGE AUTHORITY"
$RuleAppUsers = Get-SDDL -Domain "APPLICATION PACKAGE AUTHORITY" -User "Your Internet connection" @Logs
Merge-SDDL ([ref] $RuleAppUsers) (Get-SDDL -Group "Users") @Logs
$RuleAppUsers

New-Test "Get-SDDL APPLICATION PACKAGE AUTHORITY"

New-NetFirewallRule -DisplayName "Get-SDDL APPLICATION PACKAGE AUTHORITY" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort 80, 443 `
	-LocalUser $RuleAppUsers `
	-InterfaceType $Interface `
	-Description "Get-SDDL test rule for APPLICATION PACKAGE AUTHORITY" `
	@Logs | Format-Output @Logs

Update-Log
Exit-Test
