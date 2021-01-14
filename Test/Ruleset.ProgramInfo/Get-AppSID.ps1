
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
Unit test for Get-AppSID

.DESCRIPTION
Test correctness of Get-AppSID function

.PARAMETER Force
If specified, no prompt to run script is shown.

.EXAMPLE
PS> .\Get-AppSID.ps1

.INPUTS
None. You cannot pipe objects to Get-AppSID.ps1

.OUTPUTS
None. Get-AppSID.ps1 does not generate any output

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
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 $PSCmdlet
. $PSScriptRoot\..\ContextSetup.ps1

Initialize-Project -Strict
Import-Module -Name Ruleset.UserInfo

if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#endregion

Enter-Test "Get-AppSID"

Start-Test "default" -Command "Get-GroupPrincipal"
$GroupAccounts = Get-GroupPrincipal "Users", "Administrators"
$GroupAccounts

foreach ($Account in $GroupAccounts)
{
	Start-Test "$($Account.User)"
	Get-UserApps -User $Account.User | ForEach-Object {
		[PSCustomObject]@{
			PackageFamilyName = $_.PackageFamilyName
			SID = Get-AppSID -FamilyName $_.PackageFamilyName
		} | Format-List
	}
}

Start-Test "system apps"
$Result = Get-SystemApps -User $TestAdmin | ForEach-Object {
	[PSCustomObject]@{
		PackageFamilyName = $_.PackageFamilyName
		SID = Get-AppSID -FamilyName $_.PackageFamilyName
	} | Format-List
}
$Result

Test-Output ($Result | Select-Object -Property SID) -Command Get-AppSID

Update-Log
Exit-Test
