
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
Unit test for ConvertFrom-SDDL

.DESCRIPTION
Test correctness of ConvertFrom-SDDL function

.PARAMETER Domain
If specified, only remoting tests against specified computer name are performed

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\ConvertFrom-SDDL.ps1

.INPUTS
None. You cannot pipe objects to ConvertFrom-SDDL.ps1

.OUTPUTS
None. ConvertFrom-SDDL.ps1 does not generate any output

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
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 $PSCmdlet
. $PSScriptRoot\..\ContextSetup.ps1

Initialize-Project -Strict
Import-Module -Name Ruleset.UserInfo
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#endregion

Enter-Test "ConvertFrom-SDDL"

if ($Domain -ne [System.Environment]::MachineName)
{
	#
	# Test data
	#

	[string[]] $Group = @("Users", "Administrators")

	Start-Test -Command "Get-GroupPrincipal -Group $Group -CimSession" -Message "$Group"
	$Principals = Get-GroupPrincipal -Group $Group -CimSession $CimServer
	$Principals

	Start-Test -Command "Get-SDDL -CimSession" -Message "Principals"
	$SDDL1 = Get-SDDL -User $Principals.User -CimSession $CimServer
	$SDDL1

	Start-Test -Command "Merge-SDDL" -Message "Merged SDDL"
	$MergedSDDL = $SDDL1[0]
	Merge-SDDL ([ref] $MergedSDDL) -From $SDDL1[1]
	$MergedSDDL

	#
	# Test convert
	#

	Start-Test "Convert SDDL remote"
	$Result = ConvertFrom-SDDL $SDDL1[0] -Session $SessionInstance
	$Result

	Start-Test "Convert merged SDDL remote"
	$Result = ConvertFrom-SDDL $MergedSDDL -Session $SessionInstance
	$Result
}
else
{
	#
	# Test groups
	#

	[string[]] $Group = @("Users", "Administrators")

	Start-Test -Command "Get-SDDL" -Message "$Group"
	$SDDL1 = Get-SDDL -Group $Group
	$SDDL1

	#
	# Test users
	#

	[string[]] $User = "Administrator", $TestAdmin, $TestUser

	Start-Test -Command "Get-SDDL" -Message "$User"
	$SDDL2 = Get-SDDL -User $User
	$SDDL2

	#
	# Test NT AUTHORITY
	#

	[string] $NTDomain = "NT AUTHORITY"
	[string[]] $NTUser = "SYSTEM", "LOCAL SERVICE", "NETWORK SERVICE"


	Start-Test -Command "Get-SDDL" -Message "$NTDomain"
	$SDDL3 = Get-SDDL -Domain $NTDomain -User $NTUser
	$SDDL3

	#
	# Test APPLICATION PACKAGE AUTHORITY
	#

	[string] $AppDomain = "APPLICATION PACKAGE AUTHORITY"
	[string[]] $AppUser = "Your Internet connection", "Your pictures library"

	Start-Test -Command "Get-SDDL" -Message "-Domain $AppDomain -User $AppUser"
	$SDDL4 = Get-SDDL -Domain $AppDomain -User $AppUser
	$SDDL4

	#
	# Test merged SDDL
	#

	Start-Test -Command "Get-SDDL" -Message "$User"
	$MergedSDDL = Get-SDDL -User $TestUser, $TestAdmin
	$MergedSDDL

	#
	# Test convert
	#

	Start-Test "ArraySDDL"
	$ArraySDDL = $SDDL1 + $SDDL2 + $SDDL3
	$Result = ConvertFrom-SDDL $ArraySDDL
	$Result

	Test-Output $Result -Command ConvertFrom-SDDL

	Start-Test "pipeline"
	$Result = $ArraySDDL | ConvertFrom-SDDL
	$Result

	Test-Output $Result -Command ConvertFrom-SDDL

	Start-Test "Store apps"
	$Result = ConvertFrom-SDDL $SDDL4
	$Result

	Start-Test "Merged SDDL"
	$Result = ConvertFrom-SDDL $MergedSDDL
	$Result

	Test-Output $Result -Command ConvertFrom-SDDL
}

Update-Log
Exit-Test
