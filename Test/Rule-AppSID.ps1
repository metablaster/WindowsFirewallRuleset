
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
# Unit test for adding rules for store apps based on computer users
#

#Requires -RunAsAdministrator
. $PSScriptRoot\..\Config\ProjectSettings.ps1

# Check requirements for this project
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.System
Test-SystemRequirements

# Includes
. $PSScriptRoot\ContextSetup.ps1
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Logging
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Test @Logs
Import-Module -Name $ProjectRoot\Modules\Project.Windows.UserInfo @Logs
Import-Module -Name $ProjectRoot\Modules\Project.Windows.ProgramInfo @Logs
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Utility @Logs

# Ask user if he wants to load these rules
Update-Context $TestContext "IPv$IPVersion" $Direction
if (!(Approve-Execute @Logs)) { exit }

$Group = "Test - AppSID"
$Profile = "Any"

Start-Test

New-Test "Remove-NetFirewallRule"
# Remove previous test
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore @Logs

New-Test "Get-GroupPrincipals"
$Principals = Get-GroupPrincipals "Users" @Logs
$Principals

[string] $PackageSID = ""
[string] $OwnerSID = ""
foreach ($Principal in $Principals)
{
	New-Test "Processing for: $($Principal.Account)"
	$OwnerSID = Get-AccountSID $Principal.User -Computer $Principal.Computer @Logs
	$OwnerSID

	Get-AppxPackage -User $Principal.User -PackageTypeFilter Bundle | ForEach-Object {
		$PackageSID = Get-AppSID $Principal.User $_.PackageFamilyName
		$PackageSID
	} @Logs
}

New-Test "New-NetFirewallRule"
New-NetFirewallRule -Platform $Platform `
	-DisplayName "Get-AppSID" -Program Any -Service Any `
	-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType Any `
	-Direction $Direction -Protocol Any -LocalAddress Any -RemoteAddress Any -LocalPort Any -RemotePort Any `
	-LocalUser Any -Owner $OwnerSID -Package $PackageSID `
	-Description "" @Logs | Format-Output @Logs

Update-Logs
Exit-Test
