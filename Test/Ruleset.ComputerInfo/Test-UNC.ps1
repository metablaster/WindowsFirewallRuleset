
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
Unit test for Test-UNC function

.DESCRIPTION
Test correctness of Test-UNC function

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\Test-UNC.ps1

.INPUTS
None. You cannot pipe objects to Test-UNC.ps1

.OUTPUTS
None. Test-UNC.ps1 does not generate any output

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
#Endregion

Enter-Test "Test-UNC"
# $private:PSDefaultParameterValues.Add("Test-UNC:Quiet", $true)

$TestString = "\\SERVER\Share"
Start-Test $TestString -Expected "FAIL"
$Result = Test-UNC $TestString
$Result

$TestString = "\\-Server-01\Share"
Start-Test "$TestString -Strict"
Test-UNC $TestString -Strict

$TestString = "\\-SERVER-01\Share"
Start-Test "$TestString -Strict"
Test-UNC $TestString -Strict

$TestString = "\\site.domain.com\Share"
Start-Test $TestString
Test-UNC $TestString

$TestString = "\\site.domain.com\Share"
Start-Test "$TestString -Strict" -Expected "FAIL"
Test-UNC $TestString -Strict

$TestString = "\\SERVER"
Start-Test $TestString -Expected "FAIL"
Test-UNC $TestString

$TestString = "\\*COMPUTER\Share$"
Start-Test $TestString -Expected "FAIL"
Test-UNC $TestString

$TestString = "\\COMPUTER\Share$"
Start-Test $TestString
Test-UNC $TestString

$TestString = "\\SERVER-01\Share\Directory DIR\file.exe"
Start-Test $TestString
Test-UNC $TestString

$TestString = "\\SERVER-01\Share Name\Directory Name"
Start-Test $TestString
Test-UNC $TestString

$TestString = "\SERVER-01\Share\Directory DIR"
Start-Test $TestString -Expected "FAIL"
Test-UNC $TestString

$TestString = "\\.\pipe\crashpad_2324_SAMPLE_STRING"
Start-Test $TestString -Expected "FAIL"
Test-UNC $TestString

$TestString = ""
Start-Test "Empty string" -Expected "FAIL"
Test-UNC $TestString

$TestString = $null
Start-Test "null" -Expected "FAIL"
Test-UNC $TestString

New-Section "Test data to pipeline"
$TestData = Get-Content -Path $ThisScript\..\TestData\UNC-Data.txt
$TestData | Test-UNC -Quiet

Test-Output $Result -Command Test-UNC

Update-Log
Exit-Test
