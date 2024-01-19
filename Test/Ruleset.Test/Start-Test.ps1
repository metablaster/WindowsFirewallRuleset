
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020-2024 metablaster zebal@protonmail.ch

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
Unit test for Start-Test and Restore-Test

.DESCRIPTION
Primarily unit test for Start-Test and Restore-Test but in addition
Enter-Test and Exit test are used.

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\Test-UnitTest.ps1

.INPUTS
None. You cannot pipe objects to Test-UnitTest.ps1

.OUTPUTS
None. Test-UnitTest.ps1 does not generate any output

.NOTES
None.
#>

#Requires -Version 5.1

[CmdletBinding()]
param (
	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 $PSCmdlet
. $PSScriptRoot\..\ContextSetup.ps1

Initialize-Project
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#endregion

Enter-Test "Start-Test"

#
# default test
#
Start-Test "default test"

#
# Test with -Expected
#
Start-Test "Test 1" -Expected "No output except this one with 'Start-Test Test 1'"

#
# Test with -Command
#
$Result = Start-Test "Test 2" -Command "New-Command" -Expected "No output except this one with 'New-Command Test 2'"
$Result
Test-Output $Result -Command Start-Test

#
# Test failure test
#

<#
.SYNOPSIS
Generates a sample error
#>
function Get-Error
{
	[CmdletBinding()]
	param()

	Write-Error -Category MetadataError -Message "Sample failure test error success"
}

Start-Test "Failure test" -Expected "Error converted to information" -Force
# Not needing -EA SilentlyContinue only because Get-Error is global function
Get-Error -EV +TestEV -EA SilentlyContinue
Restore-Test

Exit-Test
