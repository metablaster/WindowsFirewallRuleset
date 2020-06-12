
<#
MIT License

Project: "Windows Firewall Ruleset" serves to manage firewall on Windows systems
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
# Unit test for Get-SDDL
#
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1

# Check requirements for this project
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.System
Test-SystemRequirements

# Includes
. $PSScriptRoot\ContextSetup.ps1
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Logging
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Test @Logs
Import-Module -Name $ProjectRoot\Modules\Project.Windows.UserInfo @Logs
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Utility @Logs

# Ask user if he wants to load these rules
Update-Context $TestContext $($MyInvocation.MyCommand.Name -replace ".{4}$") @Logs
if (!(Approve-Execute @Logs)) { exit }

Start-Test

#
# Test groups
#

[string[]] $Groups = @("Users", "Administrators")

New-Test "Get-SDDL -Group $Groups"
$TestUsersSDDL = Get-SDDL -Group $Groups @Logs
$TestUsersSDDL

New-Test "Get-SDDL -Group $Groups -CIM"
$TestUsersSDDL = Get-SDDL -Group $Groups -CIM @Logs
$TestUsersSDDL

#
# Test users
#

[string[]] $Users = "Administrator", "Admin", "User"
New-Test "Get-SDDL -User $Users"
$TestUsersSDDL = Get-SDDL -User $Users @Logs
$TestUsersSDDL

New-Test "Get-SDDL -User $Users -CIM"
$TestUsersSDDL = Get-SDDL -User $Users -CIM @Logs
$TestUsersSDDL

#
# Test NT AUTHORITY
#

[string] $NTDomain = "NT AUTHORITY"
[string[]] $NTUsers = "SYSTEM", "LOCAL SERVICE"

New-Test "Get-SDDL -Domain $NTDomain -User $NTUsers"
$TestUsersSDDL = Get-SDDL -Domain $NTDomain -User $NTUsers @Logs
$TestUsersSDDL

#
# Test APPLICATION PACKAGE AUTHORITY
#

[string] $AppDomain = "APPLICATION PACKAGE AUTHORITY"
[string[]] $AppUser = "Your Internet connection", "Your pictures library"

New-Test "Get-SDDL -Domain $AppDomain -User $AppUser"
$TestUsersSDDL = Get-SDDL -Domain $AppDomain -User $AppUser @Logs
$TestUsersSDDL

New-Test "Get-TypeName"
$TestUsersSDDL | Get-TypeName @Logs

Update-Logs
Exit-Test
