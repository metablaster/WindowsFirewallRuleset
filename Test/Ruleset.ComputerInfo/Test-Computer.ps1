
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
Unit test for Test-Computer

.DESCRIPTION
Test correctness of Test-Computer function

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\Test-Computer.ps1

.INPUTS
None. You cannot pipe objects to Test-Computer.ps1

.OUTPUTS
None. Test-Computer.ps1 does not generate any output

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

Enter-Test "Test-Computer"

if ($PSVersionTable.PSEdition -eq "Core")
{
	Start-Test "-Retry 2 -Timeout 1"
	Test-Computer ([System.Environment]::MachineName) -Retry 2 -Timeout 1
}
else
{
	Start-Test "-Retry 2"
	Test-Computer ([System.Environment]::MachineName) -Retry 2
}

Start-Test "-Retry" -Expected "FAIL"
Test-Computer "FAILURE-COMPUTER" -Retry 2

Start-Test "default"
$Result = Test-Computer ([System.Environment]::MachineName)
$Result

Test-Output $Result -Command Test-Computer

Update-Log
Exit-Test
