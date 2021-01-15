
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2021 metablaster zebal@protonmail.ch

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
Unit test for rules based on store apps

.DESCRIPTION
Unit test for adding store apps rules based on computer users

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\RuleAppSID.ps1

.INPUTS
None. You cannot pipe objects to RuleAppSID.ps1

.OUTPUTS
None. RuleAppSID.ps1 does not generate any output

.NOTES
None.
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
$Group = "Test - AppSID"
$LocalProfile = "Any"

Enter-Test

Start-Test "Remove-NetFirewallRule"
# Remove previous test
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore

Start-Test "Get-GroupPrincipal"
$Principals = Get-GroupPrincipal "Users"
$Principals

[string] $PackageSID = ""
[string] $OwnerSID = ""
foreach ($Account in $Principals)
{
	Start-Test "Processing for: $($Account.Principal)"
	$OwnerSID = Get-PrincipalSID $Account.User -Domain $Account.Domain
	$OwnerSID

	Get-UserApps -User $Account.User | ForEach-Object {
		$PackageSID = Get-AppSID -FamilyName $_.PackageFamilyName
		$PackageSID
	}
}

Start-Test "New-NetFirewallRule"

New-NetFirewallRule -DisplayName "Get-AppSID" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Any `
	-LocalPort Any -RemotePort Any `
	-LocalUser Any `
	-InterfaceType $DefaultInterface `
	-Owner $OwnerSID -Package $PackageSID `
	-Description "TargetProgram test rule description" |
Format-RuleOutput

Update-Log
Exit-Test
