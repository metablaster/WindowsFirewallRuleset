
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
Unit test for Test-NetBiosName

.DESCRIPTION
Test correctness of Test-NetBiosName function

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\Test-NetBiosName.ps1

.INPUTS
None. You cannot pipe objects to Test-NetBiosName.ps1

.OUTPUTS
None. Test-NetBiosName.ps1 does not generate any output

.NOTES
TODO: Test cases for user names and principals are missing.
TODO: Test cases for missing user name or computer name or null/empty are missing.
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

Enter-Test "Test-NetBiosName"
# $private:PSDefaultParameterValues.Add("Test-NetBiosName:Quiet", $true)

$TestString = "*SERVER"
Start-Test $TestString -Expected "FAIL"
$Result = Test-NetBiosName $TestString -Operation Domain
$Result

$TestString = "*SERVER"
Start-Test "$TestString -Strict" -Expected "FAIL"
Test-NetBiosName $TestString -Operation Domain -Strict

$TestString = "SER*VER*"
Start-Test "$TestString -Strict"
Test-NetBiosName $TestString -Operation Domain -Strict

$TestString = "SERVER"
Start-Test $TestString -Expected "FAIL"
Test-NetBiosName $TestString -Operation Domain

$TestString = "\\SERVER-01"
Start-Test $TestString -Expected "FAIL"
Test-NetBiosName $TestString -Operation Domain

$TestString = "-SERVER-01"
Start-Test $TestString
Test-NetBiosName $TestString -Operation Domain

$TestString = "site@domain.com"
Start-Test $TestString
Test-NetBiosName $TestString -Operation Domain

$TestString = "site@domain.com"
Start-Test "$TestString -Strict" -Expected "FAIL"
Test-NetBiosName $TestString -Operation Domain -Strict

$TestString = "site.domain.com"
Start-Test $TestString
Test-NetBiosName $TestString -Operation Domain

$TestString = "site.domain.com"
Start-Test "$TestString -Strict" -Expected "FAIL"
Test-NetBiosName $TestString -Strict -Operation Domain

$TestString = ""
Start-Test "'$TestString'" -Expected "FAIL"
$TestString | Test-NetBiosName -Operation Domain

$TestString = ".COMPUTER"
Start-Test $TestString -Expected "FAIL"
Test-NetBiosName $TestString -Operation Domain

$TestString = "VeryLongSuperDuperComputerName"
Start-Test $TestString -Expected "FAIL"
Test-NetBiosName $TestString -Operation Domain

$TestString = "Super$([char][byte] 24)Computer"
Start-Test $TestString -Expected "FAIL"
Test-NetBiosName $TestString -Operation Domain

$TestString = "Super$([char][byte] 24)Computer"
Start-Test $TestString -Expected "FAIL"
Test-NetBiosName $TestString -Operation Domain -Strict

$TestString = "3904758"
Start-Test $TestString -Expected "WARNING"
Test-NetBiosName $TestString -Operation Domain

$TestString = "APPLICATION PACKAGE AUTHORITY\Your Internet connection"
Start-Test $TestString -Expected "WARNING"
Test-NetBiosName $TestString -Force

Test-Output $Result -Command Test-NetBiosName

Update-Log
Exit-Test
