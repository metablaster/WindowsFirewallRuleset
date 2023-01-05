
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

TODO: Update Copyright date and author
Copyright (C) 2020-2023 metablaster zebal@protonmail.ch

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
Unit test for Test-Function or Test-Script.ps1

.DESCRIPTION
Test correctness of Test-Function function or Test-Script script
Use TestTemplate.ps1 as a template to test out scripts and module functions

.PARAMETER Domain
If specified, only remoting tests against specified computer name are performed

.PARAMETER Force
If specified, this unit test runs without prompt to allow execute

.EXAMPLE
PS> TestTemplate

.INPUTS
None. You cannot pipe objects to TestTemplate.ps1

.OUTPUTS
None. TestTemplate.ps1 does not generate any output

.NOTES
None.
#>

# TODO: Remove elevation requirement
#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding()]
param (
	[Parameter()]
	[Alias("ComputerName", "CN")]
	[string] $Domain = [System.Environment]::MachineName,

	[Parameter()]
	[switch] $Force
)

#region Initialization
# TODO: Adjust paths
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 $PSCmdlet -Domain $Domain
. $PSScriptRoot\..\ContextSetup.ps1

Initialize-Project
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#Endregion

Enter-Test "Test-Function"

# TODO Specify temporary Test-Function parameters
# $PSDefaultParameterValues["Test-Function:Force"] = $Force

# TODO: Keep this check if this test is:
# 1. Experimental or potentially dangerous
# 2. It should not be executed by Invoke-AllTests.ps1 by default
# 3. It takes too much time to complete
[bool] $YesToAll = $false
[bool] $NoToAll = $false

# query, caption,
# hasSecurityImpact, If specified or true, the default option in the selection menu is "No"
# yesToAll, noToAll
if ($Force -or $PSCmdlet.ShouldContinue("Query", "Accept dangerous unit test", $true, [ref] $YesToAll, [ref] $NoToAll))
{
	if ($Domain -ne [System.Environment]::MachineName)
	{
		Start-Test "Remote default"
		Test-Function -Domain $Domain
	}
	else
	{
		Start-Test "Default test"
		$Result = Test-Function
		$Result

		Test-Output $Result -Command Test-Function
	}
}

Update-Log
Exit-Test
