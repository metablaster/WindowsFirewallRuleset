
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

. $PSScriptRoot\..\..\..\..\Config\ProjectSettings.ps1

# Check requirements for this project
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.System
Test-SystemRequirements

# Includes
. $PSScriptRoot\..\DirectionSetup.ps1
. $PSScriptRoot\..\..\IPSetup.ps1
Import-Module -Name $ProjectRoot\Modules\Project.Windows.UserInfo
Import-Module -Name $ProjectRoot\Modules\Project.Windows.ProgramInfo
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Logging
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Utility

#
# Setup local variables:
#
$Group = "Games - WarThunder"
$Profile = "Private, Public"

# Ask user if he wants to load these rules
Update-Context "IPv$IPVersion" $Direction $Group @Logs
if (!(Approve-Execute @Logs)) { exit }

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction SilentlyContinue

#
# Steam installation directories
#
$WarThunderRoot = "%ProgramFiles(x86)%\Steam\steamapps\common\War Thunder"

#
# Rules for WarThunder game
#

# Test if installation exists on system
if ((Test-Installation "WarThunder" ([ref] $WarThunderRoot)) -or $Force)
{
	$Program = "$WarThunderRoot\win64\aces.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
	-DisplayName "WarThunder - aces" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443, 7800-7802, 7850-7854 `
	-LocalUser $UsersSDDL `
	-Description "" | Format-Output

	New-NetFirewallRule -Platform $Platform `
	-DisplayName "WarThunder - aces" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 1900, 20010-20500 `
	-LocalUser $UserAccountsSDDL -LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "" | Format-Output

	$Program = "$WarThunderRoot\gaijin_downloader.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
	-DisplayName "WarThunder - gajin_downloader" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
	-LocalUser $UsersSDDL `
	-Description "" | Format-Output

	New-NetFirewallRule -Platform $Platform `
	-DisplayName "WarThunder - gajin_downloader" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 20010 `
	-LocalUser $UserAccountsSDDL -LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "" | Format-Output

	$Program = "$WarThunderRoot\gjagent.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
	-DisplayName "WarThunder - gjagent" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 20010 `
	-LocalUser $UserAccountsSDDL -LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "" | Format-Output

	$Program = "$WarThunderRoot\launcher.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
	-DisplayName "WarThunder - Launcher" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
	-LocalUser $UsersSDDL `
	-Description "" | Format-Output

	New-NetFirewallRule -Platform $Platform `
	-DisplayName "WarThunder - Launcher" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 20010 `
	-LocalUser $UserAccountsSDDL -LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "" | Format-Output
}
