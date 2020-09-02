
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019, 2020 metablaster zebal@protonmail.ch

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

#
# Run all unit tests located inside "Test" folder one by one
# TODO: This script might yield odd and unexpected results
# TODO: Output of some unit tests is either delayed or not displayed at all
# TODO: Test should be run in order of module or function (or both) inter dependency
#

. $PSScriptRoot\..\Config\ProjectSettings.ps1
New-Variable -Name ThisScript -Scope Private -Option Constant -Value (
	$MyInvocation.MyCommand.Name -replace ".{4}$" )

# Check requirements
Initialize-Project

# Imports
. $PSScriptRoot\ContextSetup.ps1
Import-Module -Name Project.AllPlatforms.Logging

# User prompt
Set-Variable -Name Accept -Scope Local -Option ReadOnly -Force -Value "Run all unit tests one by one"
Set-Variable -Name Deny -Scope Local -Option ReadOnly -Force -Value "Abort operation, no unit tests will run"
Update-Context $TestContext $ThisScript
if (!(Approve-Execute -Accept $Accept -Deny $Deny @Logs)) { exit }

# Recursively get list of powershell scripts (unit tests)
$UnitTests = Get-ChildItem -Path $ProjectRoot\Test -Recurse -Filter *.ps1 -Exclude "ContextSetup.ps1", "$ThisScript.ps1" @Logs

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
	Write-Error -Category ObjectNotFound -TargetObject $Files -Message "No powershell script files found" @Logs
}

Write-Information -Tags "Project" -MessageData "INFO: Starting pester tests"

# Recursively get list of pester tests
$PesterTests = Get-ChildItem -Path $ProjectRoot\Modules\Indented.Net.IP\Test\Public -Recurse -Filter *.ps1 @Logs

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
	Write-Error -Category ObjectNotFound -TargetObject $Files -Message "No powershell script files found" @Logs
}

Write-Information -Tags "Project" -MessageData "INFO: Running all tests done"

Update-Log
