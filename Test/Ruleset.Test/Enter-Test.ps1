
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020-2022 metablaster zebal@protonmail.ch

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
Unit test for Enter-Test and Exit-Test

.DESCRIPTION
Test correctness of Enter-Test and Exit-Test functions

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\Enter-Test.ps1

.INPUTS
None. You cannot pipe objects to Enter-Test.ps1

.OUTPUTS
None. Enter-Test.ps1 does not generate any output

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

Initialize-Project -Strict
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#endregion

#
# Default test with no parameters
#
Start-Test "default" -Command "Enter-Test"

Enter-Test
Exit-Test

#
# Test specifying -Command
#
Start-Test "-Command" -Command "Enter-Test"

Enter-Test -Command "Some-Command"
Exit-Test

#
# Test exporting private module functions with dynamic module
#
Start-Test "-Private" -Command "Enter-Test"

$Result = Enter-Test -Private
$Result
Write-Information -Tags "Test" -MessageData "INFO: DynamicModule exported commands:"
Get-Module -Name Dynamic.UnitTest | Select-Object -ExpandProperty ExportedCommands | Format-Table
Exit-Test -Private

#
# Test specifying -Command and -Private
#
Start-Test "-Command -Private" -Command "Enter-Test"

Enter-Test -Command "Some-Command" -Private
Exit-Test -Private

# NOTE: These intentional errors can't be silenced and stop normal functioning of further
# tests due to script scope variable not set with Start-Test -Force
# It also doesn't run Restore-Test which hampers other unit tests, need to run manually
if ($false)
{
	#
	# Test forgetting specifying -Private
	#
	Start-Test "Forgot -Private" -Command "Enter-Test" -Expected "Error converted to information"

	Enter-Test -Private
	Exit-Test -EV +TestEV -EA SilentlyContinue
	Restore-Test
	# Remove it manually so that subsequent tests don't fail
	Remove-Module -Name Dynamic.UnitTest

	#
	# Test forgetting running Exit-Test
	#
	Start-Test "Forgot Exit-Test" -Command "Enter-Test" -Expected "Warning message"

	Enter-Test -InformationAction Ignore
	Enter-Test
	# Running Exit-Test will get rid of a warning
	Exit-Test

	#
	# Test running Exit-Test without Enter-Test
	#
	Start-Test "Forgot Enter-Test" -Command "Enter-Test" -Expected "Error converted to information" -Force

	Exit-Test -EV +TestEV -EA SilentlyContinue
	Restore-Test
}

#
# Test output type and attribute
#
Test-Output $Result -Command Enter-Test
