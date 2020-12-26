
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

<#
.SYNOPSIS
Unit test for Split-Principal

.DESCRIPTION
Unit test for Split-Principal

.EXAMPLE
PS> .\Split-Principal.ps1

.INPUTS
None. You cannot pipe objects to Split-Principal.ps1

.OUTPUTS
None. Split-Principal.ps1 does not generate any output

.NOTES
None.
#>

#region Initialization
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1
New-Variable -Name ThisScript -Scope Private -Option Constant -Value ((Get-Item $PSCommandPath).Basename)

# Check requirements
Initialize-Project -Abort

# Imports
. $PSScriptRoot\ContextSetup.ps1
Import-Module -Name Ruleset.UserInfo

# User prompt
Update-Context $TestContext $ThisScript
if (!(Approve-Execute -Accept $Accept -Deny $Deny)) { exit }
#endregion

Enter-Test

Start-Test "Get-GroupPrincipal 'Users', 'Administrators'"
$UserAccounts = Get-GroupPrincipal "Users", "Administrators"
$UserAccounts

Start-Test "Split-Principal"
$UserNames = Split-Principal ($UserAccounts | Select-Object -ExpandProperty Principal)
$UserNames

Start-Test "Split-Principal -DomainName"
Split-Principal ($UserAccounts | Select-Object -ExpandProperty Principal) -DomainName

Start-Test "Split-Principal NT AUTHORITY"
Split-Principal "NT AUTHORITY\NETWORK SERVICE"

Start-Test "Split-Principal NT AUTHORITY -Domain"
Split-Principal "NT AUTHORITY\NETWORK SERVICE" -Domain

Start-Test "Split-Principal 'MicrosoftAccount\$TestUser@domain.com'"
Split-Principal "MicrosoftAccount\$TestUser@domain.com"

Start-Test "Split-Principal '$TestUser@domain.com' -DomainName"
Split-Principal "$TestUser@domain.com" -DomainName

Start-Test "Split-Principal FAIL"
$BadAccount = "\ac", "$TestUser@email"
Split-Principal $BadAccount

Test-Output $UserNames -Command Split-Principal

Update-Log
Exit-Test
