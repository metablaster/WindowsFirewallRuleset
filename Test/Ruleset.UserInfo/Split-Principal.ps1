
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
Unit test for Split-Principal

.DESCRIPTION
Test correctness of Split-Principal function

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\Split-Principal.ps1

.INPUTS
None. You cannot pipe objects to Split-Principal.ps1

.OUTPUTS
None. Split-Principal.ps1 does not generate any output

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
#endregion

Enter-Test "Split-Principal"

Start-Test "Get-GroupPrincipal 'Users', 'Administrators'"
$UserAccounts = Get-GroupPrincipal "Users", "Administrators"
$UserAccounts

Start-Test "default"
$UserNames = Split-Principal ($UserAccounts | Select-Object -ExpandProperty Principal)
$UserNames

Start-Test "-DomainName"
Split-Principal ($UserAccounts | Select-Object -ExpandProperty Principal) -DomainName

Start-Test "NT AUTHORITY"
Split-Principal "NT AUTHORITY\NETWORK SERVICE"

Start-Test "NT AUTHORITY -Domain"
Split-Principal "NT AUTHORITY\NETWORK SERVICE" -Domain

Start-Test "'MicrosoftAccount\$TestUser@domain.com'"
Split-Principal "MicrosoftAccount\$TestUser@domain.com"

Start-Test "'$TestUser@domain.com' -DomainName"
Split-Principal "$TestUser@domain.com" -DomainName

Start-Test "FAIL"
$BadAccount = "\ac", "$TestUser@email"
Split-Principal $BadAccount

Test-Output $UserNames -Command Split-Principal

Update-Log
Exit-Test
