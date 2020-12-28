
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

TODO: Update Copyright date and author
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
Unit test for Test-Function or Test-Script

.DESCRIPTION
Test correctness of Test-Function or Test-Script
Use TestTemplate.ps1 as a template to test out scripts and module functions

.EXAMPLE
PS> .\TestTemplate.ps1

.INPUTS
None. You cannot pipe objects to TestTemplate.ps1

.OUTPUTS
None. TestTemplate.ps1 does not generate any output

.NOTES
None.
TODO: Common parameters, Verbose, Debug etc. don't work or are overridden by ProjectSettings,
Make it possible to run test with verbose or debug flag
#>

[CmdletBinding()]
[OutputType([void])]
param (
	# TODO: Remove if not needed or test is safe
	[Parameter()]
	[switch] $Force
)

#region Initialization
#Requires -Version 5.1
# TODO: Adjust path to project settings and elevation requirement
#Requires -RunAsAdministrator
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1
New-Variable -Name ThisScript -Scope Private -Option Constant -Value ((Get-Item $PSCommandPath).Basename)

# Check requirements
Initialize-Project -Abort
Write-Debug -Message "[$ThisScript] params($($PSBoundParameters.Values))"

# Imports
# TODO: Include modules and scripts as needed
. $PSScriptRoot\ContextSetup.ps1

# User prompt
Update-Context $TestContext $ThisScript
if (!(Approve-Execute -Accept $Accept -Deny $Deny)) { exit }
#Endregion

Enter-Test

# TODO Specify temporary Test-Function parameters
# $private:PSDefaultParameterValues.Add("Test-Function:Parameter", Value)

# TODO: Keep this check if this test is:
# 1. potentially dangerous
# 2. it should not be part of RunAllTests.ps1
# 3. it takes too much time to complete
if ($Force -or $PSCmdlet.ShouldContinue("Template Target", "Accept dangerous unit test"))
{
	Start-Test "Test-Function"
	$Result = Test-Function
	$Result

	Test-Output $Result -Command Test-Function
}

Update-Log
Exit-Test
