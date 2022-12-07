
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2022 metablaster zebal@protonmail.ch

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
Unit test for principal based rules

.DESCRIPTION
Unit test for adding rules based on computer accounts

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\New-RuleSDDL.ps1

.INPUTS
None. You cannot pipe objects to New-RuleSDDL.ps1

.OUTPUTS
None. New-RuleSDDL.ps1 does not generate any output

.NOTES
None.

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Test/README.md
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding()]
param (
	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\Config\ProjectSettings.ps1 $PSCmdlet
. $PSScriptRoot\ContextSetup.ps1

Initialize-Project -Strict
Import-Module -Name Ruleset.UserInfo

if (!(Approve-Execute -Accept "Load test rule into firewall" -Deny $Deny -Force:$Force)) { exit }

# Setup local variables
$Group = "Test - Get-SDDL"
$LocalProfile = "Any"

Enter-Test
# TODO: Need separate test cases for users, groups and built in domains

Start-Test "Remove-NetFirewallRule"
# Remove previous test
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore

#
# Test Groups, Users and NT AUTHORITY
#

Start-Test "Get-SDDL + Merge-SDDL"
$RuleUsers = Get-SDDL -Group "Users", "Administrators" -User $TestUser, $TestAdmin -Merge
$RuleSystemUsers = Get-SDDL -Domain "NT AUTHORITY" -User "SYSTEM", "LOCAL SERVICE" -Merge
Merge-SDDL ([ref] $RuleUsers) -From $RuleSystemUsers
$RuleUsers

Start-Test "New-NetFirewallRule"

New-NetFirewallRule -DisplayName "Get-SDDL mix" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Any `
	-LocalPort Any -RemotePort Any `
	-LocalUser $RuleUsers `
	-InterfaceType $DefaultInterface `
	-Description "Get-SDDL test rule for mixture of NT AUTHORITY and users groups" | Format-RuleOutput

#
# Test APPLICATION PACKAGE AUTHORITY
#

Start-Test "Get-SDDL + Merge-SDDL for APPLICATION PACKAGE AUTHORITY"
$RuleAppUsers = Get-SDDL -Domain "APPLICATION PACKAGE AUTHORITY" -User "Your Internet connection"
Merge-SDDL ([ref] $RuleAppUsers) -From $UsersGroupSDDL
$RuleAppUsers

Start-Test "Get-SDDL APPLICATION PACKAGE AUTHORITY"

New-NetFirewallRule -DisplayName "Get-SDDL APPLICATION PACKAGE AUTHORITY" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet4 `
	-LocalPort Any -RemotePort 80, 443 `
	-LocalUser $RuleAppUsers `
	-InterfaceType $DefaultInterface `
	-Description "Get-SDDL test rule for APPLICATION PACKAGE AUTHORITY" | Format-RuleOutput

Update-Log
Exit-Test
