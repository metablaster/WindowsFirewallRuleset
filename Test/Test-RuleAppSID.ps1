
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
. $ProjectRoot\Test\ContextSetup.ps1
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Test
Import-Module -Name $ProjectRoot\Modules\Project.Windows.UserInfo
Import-Module -Name $ProjectRoot\Modules\Project.Windows.ProgramInfo
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Logging
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Utility

# Ask user if he wants to load these rules
Update-Context $TestContext $IPVersion $Direction
if (!(Approve-Execute @Logs)) { exit }

$Group = "Test - AppSID"
$Profile = "Any"

New-Test "Remove-NetFirewallRule"
# Remove previous test
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction SilentlyContinue

New-Test "Get-UserAccounts:"
[string[]] $UserAccounts = Get-UserAccounts("Users")
$UserAccounts

New-Test "ConvertFrom-UserAccounts:"
$Users = ConvertFrom-UserAccounts($UserAccounts)
$Users

New-Test "Get-UserSID:"
foreach($User in $Users)
{
	$(Get-UserSID($User))
}

New-Test "Get-AppSID: foreach User"
[string] $PackageSID = ""
[string] $OwnerSID = ""
foreach($User in $Users) {
	New-Test "Processing for: $User"
	$OwnerSID = Get-UserSID($User)

	Get-AppxPackage -User $User -PackageTypeFilter Bundle | ForEach-Object {
		$PackageSID = (Get-AppSID $User $_.PackageFamilyName)
		$PackageSID
	}
}

New-Test "New-NetFirewallRule"
New-NetFirewallRule -Platform $Platform `
-DisplayName "Get-AppSID" -Program Any -Service Any `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType Any `
-Direction $Direction -Protocol Any -LocalAddress Any -RemoteAddress Any -LocalPort Any -RemotePort Any `
-LocalUser Any -Owner $OwnerSID -Package $PackageSID `
-Description "" | Format-Output

New-Test "Test store apps for $User"
$User = "testuser-apps"
$OwnerSID = Get-UserSID($User)

Get-AppxPackage -User $User -PackageTypeFilter Bundle | ForEach-Object {
	$PackageSID = (Get-AppSID $User $_.PackageFamilyName)

	if ($PackageSID)
	{
		New-NetFirewallRule -Platform $Platform `
		-DisplayName $_.Name -Program Any -Service Any `
		-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType Any `
		-Direction $Direction -Protocol Any -LocalAddress Any -RemoteAddress Any -LocalPort Any -RemotePort Any `
		-LocalUser Any -Owner $OwnerSID -Package $PackageSID `
		-Description "" | Format-Output
	}
}

New-Test "Test system apps for $User"
Get-AppxPackage -User $User -PackageTypeFilter Main | Where-Object { $_.SignatureKind -eq "System" -and $_.Name -like "Microsoft*" } | ForEach-Object {
	$PackageSID = (Get-AppSID $User $_.PackageFamilyName)

	if ($PackageSID)
	{
		New-NetFirewallRule -Platform $Platform `
		-DisplayName $_.Name -Program Any -Service Any `
		-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType Any `
		-Direction $Direction -Protocol Any -LocalAddress Any -RemoteAddress Any -LocalPort Any -RemotePort Any `
		-LocalUser Any -Owner $OwnerSID -Package $PackageSID `
		-Description "" | Format-Output
	}
}

# New-Test "Test all aps for Admins"
# $OwnerSID = Get-UserSID("Admin")

# New-NetFirewallRule -Platform $Platform `
# -DisplayName "All store apps" -Program Any -Service Any `
# -PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType Any `
# -Direction $Direction -Protocol Any -LocalAddress Any -RemoteAddress Any -LocalPort Any -RemotePort Any `
# -LocalUser Any -Owner $OwnerSID -Package "*" `
# -Description "" | Format-Output

Exit-Test
