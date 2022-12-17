
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
Unit test for Test-UPN

.DESCRIPTION
Test correctness of Test-UPN function

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\Test-UPN.ps1

.INPUTS
None. You cannot pipe objects to Test-UPN.ps1

.OUTPUTS
None. Test-UPN.ps1 does not generate any output

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
Import-Module -Name Ruleset.UserInfo
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#Endregion

Enter-Test "Test-UPN"
$private:PSDefaultParameterValues.Add("Test-UPN:Quiet", $true)

$Domain = "domain.com"

Start-Test "$TestUser@$Domain"
$Result = Test-UPN "$TestUser@$Domain"
$Result

Start-Test "MicrosoftAccount\$TestUser@$Domain"
Test-UPN "MicrosoftAccount\$TestUser@$Domain"

$Domain = "si-te.domain-def.com"
Start-Test "'$Domain' -Suffix"
Test-UPN $Domain -Suffix

$Domain = "[192.8.1.1]"
Start-Test "'$Domain' -Suffix"
Test-UPN $Domain -Suffix

$Domain = "user@[192.8.1.1]"
Start-Test "'$Domain'"
Test-UPN $Domain

#
# Bad syntax
#
New-Section "Bad syntax"

$BadUser = "User."
Start-Test "'$BadUser' -Prefix"
Test-UPN $BadUser -Prefix

$BadUser = "Us...er"
Start-Test "'$BadUser' -Prefix"
Test-UPN $BadUser -Prefix

$BadUser = "Use!r"
Start-Test "'$BadUser' -Prefix"
Test-UPN $BadUser -Prefix

$BadDomain = "-domain.com"
Start-Test "'$BadDomain' -Suffix"
Test-UPN $BadDomain -Suffix

$BadDomain = "domain.-com"
Start-Test "'$BadDomain' -Suffix"
Test-UPN $BadDomain -Suffix

$BadDomain = "[192.8.1]"
Start-Test "'$BadDomain' -Suffix"
Test-UPN $BadDomain -Suffix

$Domain = "user@192.8.1.1"
Start-Test "'$Domain'"
Test-UPN $Domain

$BadUPN = "user.user@domain@domain2.lan"
Start-Test "'$BadUPN'"
Test-UPN $BadUPN

$BadUPN = "@"
Start-Test "'$BadUPN'"
Test-UPN $BadUPN

$BadDomain = "@domain.lan"
Start-Test "'$BadDomain'"
Test-UPN $BadDomain

$BadUser = "user@"
Start-Test "'$BadUser'"
Test-UPN $BadUser

$BadDomain = "@domain.lan -Prefix"
Start-Test "'$BadDomain'"
Test-UPN $BadDomain -Prefix

$BadUser = "user@"
Start-Test "'$BadUser' -Suffix"
Test-UPN $BadUser -Suffix

#
# Suffix or Prefix
#
New-Section "Suffix or Prefix"

Start-Test "'$TestUser' -Prefix"
Test-UPN $TestUser -Prefix

Start-Test "'$Domain' -Suffix"
Test-UPN $Domain -Suffix

Start-Test "'$TestUser'"
Test-UPN $TestUser

Start-Test "'$Domain'"
Test-UPN $Domain

Start-Test "$TestUser@$Domain -Prefix"
Test-UPN "$TestUser@$Domain" -Prefix

Start-Test "$TestUser@$Domain -Suffix"
Test-UPN "$TestUser@$Domain" -Suffix

#
# null or empty test
#
New-Section "null or empty"

Start-Test "null pipeline -Suffix" -Expected "FAIL" -Force
$NullString = @($null, $Domain, $null)
$NullString | Test-UPN -Suffix -EV +TestEV -EA SilentlyContinue
Restore-Test

$EmptyString = @("", $TestUser, "")
Start-Test "empty pipeline -Prefix"
$EmptyString | Test-UPN -Prefix

Start-Test "empty -Suffix"
$TestString = ""
Test-UPN $TestString -Suffix

Start-Test "empty"
Test-UPN $TestString

Start-Test "null -Prefix" -Expected "FAIL" -Force
$TestString = $null
Test-UPN $TestString -Prefix -EV +TestEV -EA SilentlyContinue
Restore-Test

Start-Test "null" -Expected "FAIL" -Force
Test-UPN $TestString -EV +TestEV -EA SilentlyContinue
Restore-Test

Start-Test "separator only"
$TestString = "@"
Test-UPN $TestString

Test-Output $Result -Command Test-UPN

Update-Log
Exit-Test
