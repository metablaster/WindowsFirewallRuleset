
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020 metablaster zebal@protonmail.ch

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
Unit test for ConvertFrom-SID

.DESCRIPTION
Unit test for ConvertFrom-SID

.EXAMPLE
PS> .\ConvertFrom-SID.ps1

.INPUTS
None. You cannot pipe objects to ConvertFrom-SID.ps1

.OUTPUTS
None. ConvertFrom-SID.ps1 does not generate any output

.NOTES
None.
#>

#region Initialization
#Requires -RunAsAdministrator
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1
New-Variable -Name ThisScript -Scope Private -Option Constant -Value (
	$MyInvocation.MyCommand.Name -replace ".{4}$" )

# Check requirements
Initialize-Project -Abort

# Imports
. $PSScriptRoot\ContextSetup.ps1
Import-Module -Name Ruleset.UserInfo

# User prompt
Update-Context $TestContext $ThisScript
if (!(Approve-Execute -Accept $Accept -Deny $Deny)) { exit }
#endregion

$VerbosePreference = "Continue"
$DebugPreference = "Continue"

Enter-Test

Start-Test "Get-GroupPrincipal 'Users', 'Administrators', NT SYSTEM, NT LOCAL SERVICE"
$UserAccounts = Get-GroupPrincipal "Users", "Administrators"
$UserAccounts

Test-Output $UserAccounts[0] -Command Get-GroupPrincipal

Start-Test "Get-AccountSID NT SYSTEM, NT LOCAL SERVICE"
$NTAccounts = Get-AccountSID -Domain "NT AUTHORITY" -User "SYSTEM", "LOCAL SERVICE"
$NTAccounts

Start-Test "ConvertFrom-SID users and admins"
$AccountSIDs = @()
foreach ($Account in $UserAccounts)
{
	$AccountSIDs += $Account.SID
}
$AccountSIDs | ConvertFrom-SID | Format-Table

Start-Test "ConvertFrom-SID NT AUTHORITY users"
foreach ($Account in $NTAccounts)
{
	ConvertFrom-SID $Account | Format-Table
}

Start-Test "ConvertFrom-SID Unknown domain"
ConvertFrom-SID "S-1-5-21-0000-0000-1111-1111" -ErrorAction SilentlyContinue | Format-Table

Start-Test "ConvertFrom-SID App SID"
$AppSID = "S-1-15-2-2967553933-3217682302-2494645345-2077017737-3805576244-585965800-1797614741"
$AppResult = ConvertFrom-SID $AppSID
$AppResult | Format-Table

Start-Test "ConvertFrom-SID nonexistent App SID"
$AppSID = "S-1-15-2-2967553933-3217682302-0000000000000000000-2077017737-3805576244-585965800-1797614741"
$AppResult = ConvertFrom-SID $AppSID -ErrorAction SilentlyContinue
$AppResult | Format-Table

Start-Test "ConvertFrom-SID APPLICATION PACKAGE AUTHORITY"
$AppSID = "S-1-15-2-2"
$PackageResult = ConvertFrom-SID $AppSID
$PackageResult | Format-Table

Start-Test "ConvertFrom-SID Capability"
$AppSID = "S-1-15-3-12345"
$PackageResult = ConvertFrom-SID $AppSID
$PackageResult | Format-Table

Test-Output $AppResult -Command ConvertFrom-SID

Update-Log
Exit-Test
