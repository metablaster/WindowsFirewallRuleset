
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2023 metablaster zebal@protonmail.ch

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
Unit test for Get-SDDL

.DESCRIPTION
Test correctness of Get-SDDL function

.PARAMETER Domain
If specified, only remoting tests against specified computer name are performed

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\Get-SDDL.ps1

.INPUTS
None. You cannot pipe objects to Get-SDDL.ps1

.OUTPUTS
None. Get-SDDL.ps1 does not generate any output

.NOTES
None.
#>

#Requires -Version 5.1

[CmdletBinding()]
param (
	[Parameter()]
	[Alias("ComputerName", "CN")]
	[string] $Domain = [System.Environment]::MachineName,

	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 $PSCmdlet -Domain $Domain
. $PSScriptRoot\..\ContextSetup.ps1

Initialize-Project
Import-Module -Name Ruleset.UserInfo
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#endregion

Enter-Test "Get-SDDL"

if ($Domain -ne [System.Environment]::MachineName)
{
	Start-Test -Command "Get-GroupPrincipal" -Message "-Group Users"
	$Principals = Get-GroupPrincipal -Group Users -CimSession $CimServer
	$Principals

	Start-Test "Remote User"
	$SDDL1 = Get-SDDL -User $Principals[0].User -CimSession $CimServer
	$SDDL1

	Start-Test "Remote Group -CimSession"
	Get-SDDL -Group "Users" -CimSession $CimServer

	# Start-Test "Remote -Domain $Domain"
	# Get-SDDL -User "User" -Domain $Domain
}
else
{
	#
	# Test groups
	#
	[string[]] $Groups = @("Users", "Administrators")

	Start-Test "-Group $Groups"
	$Result = Get-SDDL -Group $Groups

	Test-SDDL $Result
	Test-Output $Result -Command Get-SDDL

	Start-Test "-Group $Groups -Merge"
	Get-SDDL -Group $Groups -Merge | Test-SDDL

	Start-Test "-Group $Groups"
	Get-SDDL -Group $Groups | Test-SDDL

	Start-Test "-Group $Groups -Merge"
	Get-SDDL -Group $Groups -Merge | Test-SDDL

	#
	# Test users
	#

	[string[]] $Users = "Administrator", $TestAdmin, $TestUser

	Start-Test "-User $Users"
	Get-SDDL -User $Users | Test-SDDL

	Start-Test "-User $Users -Merge"
	Get-SDDL -User $Users -Merge | Test-SDDL

	Start-Test "-User $Users"
	$Result = Get-SDDL -User $Users

	Test-SDDL $Result
	Test-Output $Result -Command Get-SDDL

	Start-Test "-User $Users -Merge"
	$Result = Get-SDDL -User $Users -Merge
	$Result | Test-SDDL

	Test-Output $Result -Command Get-SDDL

	#
	# Test NT AUTHORITY
	#

	[string] $NTDomain = "NT AUTHORITY"
	[string[]] $NTUsers = "SYSTEM", "LOCAL SERVICE"

	Start-Test "-Domain $NTDomain -User $NTUsers"
	Get-SDDL -Domain $NTDomain -User $NTUsers | Test-SDDL

	Start-Test "-Domain $NTDomain -User $NTUsers -Merge"
	Get-SDDL -Domain $NTDomain -User $NTUsers -Merge | Test-SDDL

	#
	# Test APPLICATION PACKAGE AUTHORITY
	#

	[string] $AppDomain = "APPLICATION PACKAGE AUTHORITY"
	[string[]] $AppUser = "Your Internet connection", "Your pictures library"

	Start-Test "-Domain $AppDomain -User $AppUser"
	Get-SDDL -Domain $AppDomain -User $AppUser | Test-SDDL

	Start-Test "-Domain $AppDomain -User $AppUser -Merge"
	$Result = Get-SDDL -Domain $AppDomain -User $AppUser -Merge
	$Result | Test-SDDL

	Test-Output $Result -Command Get-SDDL
}

Update-Log
Exit-Test
