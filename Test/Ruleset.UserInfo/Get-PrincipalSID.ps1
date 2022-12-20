
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
Unit test for Get-PrincipalSID

.DESCRIPTION
Test correctness of Get-PrincipalSID function

.PARAMETER Domain
If specified, only remoting tests against specified computer name are performed

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\Get-PrincipalSID.ps1

.INPUTS
None. You cannot pipe objects to Get-PrincipalSID.ps1

.OUTPUTS
None. Get-PrincipalSID.ps1 does not generate any output

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

Enter-Test "Get-PrincipalSID"

if ($Domain -ne [System.Environment]::MachineName)
{
	Start-Test "Get remote user" -Command Get-GroupPrincipal
	$Users = Get-GroupPrincipal -Group Users -CimSession $CimServer
	$Users

	Start-Test "Remote CimSession $($Users[0].User)"
	Get-PrincipalSID -User $Users[0].User -CimSession $CimServer

	# Start-Test "Remote Domain"
	# Get-PrincipalSID -User $Users -Domain $Domain
}
else
{
	[string[]] $Users = @("Administrator", $TestUser, $TestAdmin)

	#
	# Test users
	#

	Start-Test "-User $Users -Domain localhost"
	$AccountSID1 = Get-PrincipalSID -User $Users -Domain "localhost"
	$AccountSID1

	Start-Test "-User $Users"
	$AccountSID1 = Get-PrincipalSID -User $Users -Domain $Domain
	$AccountSID1

	Start-Test "$Users | Get-PrincipalSID"
	$Users | Get-PrincipalSID -Domain $Domain

	Start-Test "Get-TypeName"
	$AccountSID1 | Get-TypeName -Force

	#
	# Test NT AUTHORITY
	#

	[string[]] $NTUsers = @("SYSTEM", "LOCAL SERVICE", "USER MODE DRIVERS")
	[string] $NTDomain = "NT AUTHORITY"

	Start-Test "-Domain $NTDomain -User $NTUsers"
	$AccountSID2 = Get-PrincipalSID -Domain $NTDomain -User $NTUsers #
	$AccountSID2

	# NOTE: not valid
	# Start-Test "-Domain $NTDomain -User $NTUsers"
	# $AccountSID2 = Get-PrincipalSID -Domain $NTDomain -User $NTUsers
	# $AccountSID2

	Start-Test "Get-TypeName"
	$AccountSID2 | Get-TypeName -Force

	#
	# Test APPLICATION PACKAGE AUTHORITY
	#

	[string] $AppDomain = "APPLICATION PACKAGE AUTHORITY"
	[string] $AppUser = "Your Internet connection"

	Start-Test "-Domain $AppDomain -User $AppUser"
	$AccountSID3 = Get-PrincipalSID -Domain $AppDomain -User $AppUser
	$AccountSID3

	# NOTE: not valid
	# Start-Test "-Domain $AppDomain -User $AppUser"
	# $AccountSID3 = Get-PrincipalSID -Domain $AppDomain -User $AppUser
	# $AccountSID3

	Test-Output $AccountSID3 -Command Get-PrincipalSID -Force
}

Update-Log
Exit-Test
