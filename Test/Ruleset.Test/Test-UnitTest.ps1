
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020, 2021 metablaster zebal@protonmail.ch

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
Unit test for Ruleset.Test module

.DESCRIPTION
Unit test for:

1. Enter-Test
2. Start-Test
3. Stop-Test
4. Exit-Test

.PARAMETER Force
If specified, no prompt to run script is shown.

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

Initialize-Project -Strict
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#endregion

Enter-Test "Start-Test"

$Result = Start-Test "Test 1" -Expected "Test 1"
$Result
Test-Output $Result -Command Start-Test

$Result = Stop-Test
$Result
Test-Output $Result -Command Stop-Test

$Result = New-Section "Sample Section"
$Result
Test-Output $Result -Command New-Section

Start-Test "Test 2" -Expected "Test 2"
Stop-Test

$Result = Exit-Test
$Result
Test-Output $Result -Command Exit-Test
