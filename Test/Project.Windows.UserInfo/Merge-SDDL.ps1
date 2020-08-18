
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
# Unit test for Merge-SDDL
#
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1

# Check requirements for this project
Import-Module -Name Project.AllPlatforms.System
Test-SystemRequirements

# Imports
. $PSScriptRoot\ContextSetup.ps1
Import-Module -Name Project.AllPlatforms.Logging
Import-Module -Name Project.AllPlatforms.Test @Logs
Import-Module -Name Project.Windows.UserInfo @Logs
Import-Module -Name Project.AllPlatforms.Utility @Logs

# Ask user if he wants to load these rules
Update-Context $TestContext $($MyInvocation.MyCommand.Name -replace ".{4}$") @Logs
if (!(Approve-Execute @Logs)) { exit }

Start-Test

[string[]] $Users = @("user")
[string] $Domain = [System.Environment]::MachineName
[string[]] $Groups = @("Users", "Administrators")

New-Test "Get-SDDL -User $Users -Group $Groups -Domain $Domain"
$TestUsersSDDL = Get-SDDL -User $Users -Group $Groups -Domain $Domain @Logs
$TestUsersSDDL

New-Test "Get-SDDL -Domain 'NT AUTHORITY' -User 'SYSTEM', 'UserModeDrivers'"
$NewSDDL = Get-SDDL -Domain "NT AUTHORITY" -User "SYSTEM", "UserModeDrivers" @Logs

New-Test "Merge-SDDL"
Merge-SDDL ([ref] $TestUsersSDDL) $NewSDDL @Logs
$TestUsersSDDL

New-Test "Get-TypeName"
$TestUsersSDDL | Get-TypeName @Logs

Update-Log
Exit-Test
