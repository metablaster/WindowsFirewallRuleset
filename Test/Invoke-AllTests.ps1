
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
Master unit test

.DESCRIPTION
Run all unit tests located inside "Test" folder one by one

.PARAMETER Pester
If specified, run only pester tests

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\Invoke-AllTests.ps1

.INPUTS
None. You cannot pipe objects to Invoke-AllTests.ps1

.OUTPUTS
None. Invoke-AllTests.ps1 does not generate any output

.NOTES
TODO: This script might yield odd and unexpected results
TODO: Output of some unit tests is either delayed or not displayed at all
NOTE: Delay happens when mixing Write-Output with other streams (none waits)
NOTE: This might get fixed with consistent outputs, formats and better pipelines
TODO: Test should be run in order of module or function (or both) inter dependency
TODO: We should handle to skip "dangerous" tests


.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Test/README.md
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding()]
param (
	[Parameter()]
	[switch] $Pester,

	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\Config\ProjectSettings.ps1 $PSCmdlet
. $PSScriptRoot\ContextSetup.ps1
Initialize-Project -Strict

# User prompt
New-Variable -Name Accept -Scope Local -Option ReadOnly -Force -Value "Run all unit tests one by one"
New-Variable -Name Deny -Scope Local -Option ReadOnly -Force -Value "Abort operation, no unit tests will run"
if ($Pester)
{
	Set-Variable -Name Accept -Scope Local -Option ReadOnly -Force -Value "Run all pester tests only, one by one"
}

if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#endregion

$PreviousProjectCheck = (Get-Variable -Name ProjectCheck -Scope Global).Value
Set-Variable -Name ProjectCheck -Scope Global -Option ReadOnly -Force -Value $false
Reset-TestDrive

# Prompt to set screen buffer to recommended value for tests
Set-ScreenBuffer 3000

Write-Warning -Message "[$ThisScript] Output of some tests cases may be unexpected with Invoke-AllTests.ps1"

if (!$Pester)
{
	# Recursively get list of powershell scripts (unit tests)
	$UnitTests = Get-ChildItem -Path $ProjectRoot\Test -Recurse -Filter *.ps1 -Exclude "ContextSetup.ps1", "$ThisScript.ps1" |
	Where-Object { $_.FullName -notlike "*\Experiment\*" }

	if ($UnitTests)
	{
		# Run them all
		foreach ($Test in $UnitTests)
		{
			& $Test.FullName
		}
	}
	else
	{
		Write-Error -Category ObjectNotFound -TargetObject $Files -Message "No PowerShell test scripts found"
	}
}

Write-Information -Tags "Test" -MessageData "INFO: Starting pester tests"

# Recursively get list of pester tests
# TODO: Tests from Private folder excluded because out of date
$PesterTests = Get-ChildItem -Path $ProjectRoot\Modules\Ruleset.IP\Test\Public -Filter *.ps1
# $PesterTests += Get-ChildItem -Path $ProjectRoot\Modules\Ruleset.PolicyFileEditor\Test -Filter *.ps1

if ($PSVersionTable.PSVersion -ge "6.1")
{
	$PesterTests += Get-ChildItem -Path $ProjectRoot\Modules\Ruleset.Compatibility\Test -Filter *.ps1
}
else
{
	Write-Warning -Message "[$ThisScript] Tests for 'Ruleset.Compatibility' module skipped, PowerShell Core >= 6.1 required to run them"
}

if ($PesterTests)
{
	# Run all pester tests
	foreach ($Test in $PesterTests)
	{
		& $Test.FullName
	}
}
else
{
	Write-Error -Category ObjectNotFound -TargetObject $Files -Message "No Pester test scripts found"
}

if (!$Pester)
{
	Test-MarkdownLink -LiteralPath $ProjectRoot -Recurse -Unique #-Exclude "github.com"
}

Set-Variable -Name ProjectCheck -Scope Global -Force -Value $PreviousProjectCheck
Write-Information -Tags "Test" -MessageData "INFO: Running all tests done"

Disconnect-Computer $PolicyStore
Update-Log
