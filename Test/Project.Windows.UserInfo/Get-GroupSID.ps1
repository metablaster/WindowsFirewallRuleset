
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

#
# Unit test for Get-GroupSID
#
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1

# Check requirements for this project
Initialize-Project

# Imports
. $PSScriptRoot\ContextSetup.ps1
Import-Module -Name Project.AllPlatforms.Logging
Import-Module -Name Project.Windows.UserInfo

# Ask user if he wants to load these rules
Update-Context $TestContext $($MyInvocation.MyCommand.Name -replace ".{4}$") @Logs
if (!(Approve-Execute @Logs)) { exit }

Start-Test

#
# Test single group
#

[string] $SingleGroup = "Users"
New-Test "Get-GroupSID $SingleGroup"
$GroupsTest = Get-GroupSID $SingleGroup @Logs
$GroupsTest

New-Test "Get-GroupSID 'Users' -CIM"
$GroupsTest = Get-GroupSID $SingleGroup -CIM @Logs
$GroupsTest

New-Test "Get-TypeName"
$GroupsTest | Get-TypeName @Logs

#
# Test array of groups
#

[string[]] $GroupArray = @('Users', 'Hyper-V Administrators')

New-Test "Get-GroupSID $GroupArray"
$GroupsTest = Get-GroupSID $GroupArray @Logs
$GroupsTest

New-Test "Get-GroupSID $GroupArray -CIM"
$GroupsTest = Get-GroupSID $GroupArray -CIM @Logs
$GroupsTest

New-Test "Get-TypeName"
$GroupsTest | Get-TypeName @Logs

#
# Test pipeline
#

$GroupArray = @("Users", "Administrators")

New-Test "$GroupArray | Get-GroupSID"
$GroupArray | Get-GroupSID @Logs

New-Test "$GroupArray | Get-GroupSID -CIM"
$GroupArray | Get-GroupSID -CIM @Logs

#
# Test failure
#

New-Test "FAILURE TEST NO CIM: Get-GroupSID @('Users', 'Hyper-V Administrators')"
Get-GroupSID 'Users', 'Hyper-V Administrators' -Machine "CRAZYMACHINE" @Logs

New-Test "FAILURE TEST CONTACT: Get-GroupSID @('Users', 'Hyper-V Administrators')"
Get-GroupSID 'Users', 'Hyper-V Administrators' -Machine "CRAZYMACHINE" -CIM @Logs

Update-Log
Exit-Test
