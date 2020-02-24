
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
# Unit test for Get-AppSID
#

#Requires -RunAsAdministrator
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1

# Check requirements for this project
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.System
Test-SystemRequirements

# Includes
. $ProjectRoot\Test\ContextSetup.ps1
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Test
Import-Module -Name $ProjectRoot\Modules\Project.Windows.UserInfo
Import-Module -Name $ProjectRoot\Modules\Project.Windows.ProgramInfo
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Logging
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Utility

# Ask user if he wants to load these rules
Update-Context $TestContext $($MyInvocation.MyCommand.Name -replace ".{4}$")
if (!(Approve-Execute)) { exit }

Start-Test

New-Test "Get-UserAccounts:"

[string[]] $UserAccounts = Get-UserAccounts "Users" @Logs
Update-Logs

[string[]] $AdminAccounts = Get-UserAccounts "Administrators" @Logs
Update-Logs
$UserAccounts
$AdminAccounts

New-Test "ConvertFrom-UserAccounts:"

$Users = ConvertFrom-UserAccounts $UserAccounts @Logs
Update-Logs
$Admins = ConvertFrom-UserAccounts $AdminAccounts @Logs
Update-Logs

$Users
$Admins

New-Test "Get-UserSID:"

foreach($User in $Users)
{
	Get-UserSID $User @Logs
}
Update-Logs

foreach($Admin in $Admins)
{
	Get-UserSID $Admin @Logs
}
Update-Logs

New-Test "Get-AppSID: foreach User"

foreach($User in $Users) {
	Write-Information -Tags "Test" -MessageData "INFO: Processing for: $User"
	Get-AppxPackage -User $User -PackageTypeFilter Bundle @Logs | ForEach-Object {
		Get-AppSID $User $_.PackageFamilyName @Logs
	}
}
Update-Logs

New-Test "Get-AppSID: foreach Admin"

foreach($Admin in $Admins) {
	Write-Information -Tags "Test" -MessageData "INFO: Processing for: $Admin"
	Get-AppxPackage -User $Admin -PackageTypeFilter Bundle @Logs | ForEach-Object {
		Get-AppSID $Admin $_.PackageFamilyName @Logs
	}
}

Update-Logs

Exit-Test
