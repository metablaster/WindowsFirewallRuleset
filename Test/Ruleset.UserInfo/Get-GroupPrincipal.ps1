
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
Unit test for Get-GroupPrincipal

.DESCRIPTION
Test correctness of Get-GroupPrincipal function

.PARAMETER Domain
If specified, only remoting tests against specified computer name are performed

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\Get-GroupPrincipal.ps1

.INPUTS
None. You cannot pipe objects to Get-GroupPrincipal.ps1

.OUTPUTS
None. Get-GroupPrincipal.ps1 does not generate any output

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

Enter-Test "Get-GroupPrincipal"

if ($Domain -ne [System.Environment]::MachineName)
{
	Start-Test "Remote CimSession"
	Get-GroupPrincipal "Users", "Administrators" -CimSession $CimServer

	Start-Test "Remote -Unique"
	Get-GroupPrincipal "Users", "Administrators" -CimSession $CimServer -Unique

	# Start-Test "Remote Domain"
	# Get-GroupPrincipal "Users", "Administrators" -Domain $TestDomain
}
else
{
	Start-Test "Users -Domain localhost"
	$UsersTest = Get-GroupPrincipal "Users" -Domain "localhost"
	$UsersTest

	Start-Test "Disabled Administrators"
	Get-GroupPrincipal "Administrators" -Disabled

	Start-Test "Users, Administrators"
	Get-GroupPrincipal "Users", "Administrators" -Domain "localhost"

	Start-Test "Disabled Users, Administrators"
	Get-GroupPrincipal "Users", "Administrators" -Domain "localhost" -Disabled

	Start-Test "Failure test" -Force
	Get-GroupPrincipal "Nonexistent Users" -EV +TestEV -EA SilentlyContinue
	Restore-Test

	Test-Output $UsersTest -Command Get-GroupPrincipal -Force
}

Update-Log
Exit-Test
