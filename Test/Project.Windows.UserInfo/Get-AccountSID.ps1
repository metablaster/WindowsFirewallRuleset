
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
# Unit test for Get-AccountSID
#
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1

# Check requirements for this project
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.System
Test-SystemRequirements

# Includes
. $ProjectRoot\Test\ContextSetup.ps1
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Test
Import-Module -Name $ProjectRoot\Modules\Project.Windows.UserInfo
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Logging
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Utility

# Ask user if he wants to load these rules
Update-Context $TestContext $($MyInvocation.MyCommand.Name -replace ".{4}$") @Logs
if (!(Approve-Execute @Logs)) { exit }

Start-Test

[string[]] $Users = @("Administrator", "test", "haxor")

New-Test "Get-AccountSID -Users $Users"
$AccountSID = Get-AccountSID -User $Users @Logs
$AccountSID

New-Test "Get-AccountSID -Users $Users -CIM"
$AccountSID = Get-AccountSID -User $Users -CIM @Logs
$AccountSID

New-Test "$Users | Get-AccountSID -CIM"
$Users | Get-AccountSID -CIM @Logs

[string[]] $Users = @("SYSTEM", "NETWORK SERVICE")
[string] $Domain = "NT AUTHORITY"

New-Test "Get-AccountSID -Users $Users"
$AccountSID = Get-AccountSID -User $Users -Domain $Domain @Logs
$AccountSID

New-Test "Get-AccountSID -Users $Users -CIM"
$AccountSID = Get-AccountSID -User $Users -Domain $Domain -CIM @Logs
$AccountSID

New-Test "$Users | Get-AccountSID -CIM"
$Users | Get-AccountSID -CIM -Domain $Domain @Logs

New-Test "Get-TypeName"
$Users | Get-TypeName @Logs

Update-Logs
Exit-Test
