
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2021 metablaster zebal@protonmail.ch

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
Unit test for Test-Service

.DESCRIPTION
Test correctness of Test-Service function

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\Test-Service.ps1

.INPUTS
None. You cannot pipe objects to Test-Service.ps1

.OUTPUTS
None. Test-Service.ps1 does not generate any output

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

Enter-Test "Test-Service"

Start-Test "dnscache"
$Result = Test-Service dnscache
$Result

Start-Test "array to pipeline"
@("msiserver", "DOESNOTEXIST", "Spooler", "WSearch") | Test-Service

Start-Test "*xbox*" -Command "Get-Service" -Expected "FAIL"
Test-Service (Get-Service -Name *xbox*)

Start-Test "*xbox* to pipeline" -Command "Get-Service" -Expected "FAIL"
Get-Service -Name *xbox* | Test-Service

Start-Test "*xbox*"
Test-Service "*xbox*"

Start-Test "*xbox* pipeline"
"*xbox*" | Test-Service

Start-Test "FailureTest"
Test-Service "FailureTest"

Start-Test "project rules"
Build-ServiceList $ProjectRoot\Rules | Test-Service | Measure-Object

Test-Output $Result -Command Test-Service

Update-Log
Exit-Test
