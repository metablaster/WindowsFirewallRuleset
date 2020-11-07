
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
Unit test for Get-SDDL

.DESCRIPTION
Unit test for Get-SDDL

.EXAMPLE
PS> .\Get-SDDL.ps1

.INPUTS
None. You cannot pipe objects to Get-SDDL.ps1

.OUTPUTS
None. Get-SDDL.ps1 does not generate any output

.NOTES
None.
#>

# Initialization
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1
New-Variable -Name ThisScript -Scope Private -Option Constant -Value (
	$MyInvocation.MyCommand.Name -replace ".{4}$" )

# Check requirements
Initialize-Project -Abort

# Imports
. $PSScriptRoot\ContextSetup.ps1
Import-Module -Name Ruleset.Logging
Import-Module -Name Ruleset.UserInfo

# User prompt
Update-Context $TestContext $ThisScript @Logs
if (!(Approve-Execute -Accept $Accept -Deny $Deny @Logs)) { exit }

Enter-Test $ThisScript

#
# Test groups
#

[string[]] $Groups = @("Users", "Administrators")

Start-Test "Get-SDDL -Group $Groups"
$TestUsersSDDL = Get-SDDL -Group $Groups @Logs
$TestUsersSDDL

Start-Test "Get-SDDL -Group $Groups -CIM"
$TestUsersSDDL = Get-SDDL -Group $Groups -CIM @Logs
$TestUsersSDDL

#
# Test users
#

[string[]] $Users = "Administrator", $TestAdmin, $TestUser
Start-Test "Get-SDDL -User $Users"
$TestUsersSDDL = Get-SDDL -User $Users @Logs
$TestUsersSDDL

Start-Test "Get-SDDL -User $Users -CIM"
$TestUsersSDDL = Get-SDDL -User $Users -CIM @Logs
$TestUsersSDDL

#
# Test NT AUTHORITY
#

[string] $NTDomain = "NT AUTHORITY"
[string[]] $NTUsers = "SYSTEM", "LOCAL SERVICE"

Start-Test "Get-SDDL -Domain $NTDomain -User $NTUsers"
$TestUsersSDDL = Get-SDDL -Domain $NTDomain -User $NTUsers @Logs
$TestUsersSDDL

#
# Test APPLICATION PACKAGE AUTHORITY
#

[string] $AppDomain = "APPLICATION PACKAGE AUTHORITY"
[string[]] $AppUser = "Your Internet connection", "Your pictures library"

Start-Test "Get-SDDL -Domain $AppDomain -User $AppUser"
$TestUsersSDDL = Get-SDDL -Domain $AppDomain -User $AppUser @Logs
$TestUsersSDDL

Test-Output $TestUsersSDDL -Command Get-SDDL @Logs

Update-Log
Exit-Test
