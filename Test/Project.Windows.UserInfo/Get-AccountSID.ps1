
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
# Unit test for Get-AccountSID
#
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1
New-Variable -Name ThisScript -Scope Private -Option Constant -Value (
	$MyInvocation.MyCommand.Name -replace ".{4}$" )

# Check requirements
Initialize-Project

# Imports
. $PSScriptRoot\ContextSetup.ps1
Import-Module -Name Project.AllPlatforms.Logging
Import-Module -Name Project.Windows.UserInfo

# User prompt
Update-Context $TestContext $ThisScript @Logs
if (!(Approve-Execute -Accept $Accept -Deny $Deny @Logs)) { exit }

Enter-Test $ThisScript

#
# Test users
#

[string[]] $Users = @("Administrator", $UnitTester, $UnitTesterAdmin)

Start-Test "Get-AccountSID -User $Users"
$AccountSID1 = Get-AccountSID -User $Users @Logs
$AccountSID1

Start-Test "Get-AccountSID -User $Users -CIM"
$AccountSID1 = Get-AccountSID -User $Users -CIM @Logs
$AccountSID1

Start-Test "$Users | Get-AccountSID -CIM"
$Users | Get-AccountSID -CIM @Logs

Start-Test "Get-TypeName"
$AccountSID1 | Get-TypeName @Logs

#
# Test NT AUTHORITY
#

[string[]] $NTUsers = @("SYSTEM", "LOCAL SERVICE", "USER MODE DRIVERS")
[string] $NTDomain = "NT AUTHORITY"

Start-Test "Get-AccountSID -Domain $NTDomain -User $NTUsers"
$AccountSID2 = Get-AccountSID -Domain $NTDomain -User $NTUsers # @Logs
$AccountSID2

# NOTE: not valid
# Start-Test "Get-AccountSID -Domain $NTDomain -User $NTUsers -CIM"
# $AccountSID2 = Get-AccountSID -Domain $NTDomain -User $NTUsers -CIM @Logs
# $AccountSID2

Start-Test "Get-TypeName"
$AccountSID2 | Get-TypeName @Logs

#
# Test APPLICATION PACKAGE AUTHORITY
#

[string] $AppDomain = "APPLICATION PACKAGE AUTHORITY"
[string] $AppUser = "Your Internet connection"

Start-Test "Get-AccountSID -Domain $AppDomain -User $AppUser"
$AccountSID3 = Get-AccountSID -Domain $AppDomain -User $AppUser @Logs
$AccountSID3

# NOTE: not valid
# Start-Test "Get-AccountSID -Domain $AppDomain -User $AppUser -CIM"
# $AccountSID3 = Get-AccountSID -Domain $AppDomain -User $AppUser -CIM @Logs
# $AccountSID3

Start-Test "Get-TypeName"
$AccountSID3 | Get-TypeName @Logs

Update-Log
Exit-Test
