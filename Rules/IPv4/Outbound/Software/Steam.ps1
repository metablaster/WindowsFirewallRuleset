
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
$Group = "Software - Steam"
$Profile = "Private, Public"

# Ask user if he wants to load these rules
Update-Context "IPv$IPVersion" $Direction $Group @Logs
if (!(Approve-Execute @Logs)) { exit }

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction SilentlyContinue

#
# Steam installation directories
#
$SteamRoot = "%ProgramFiles(x86)%\Steam"

#
# Rules for Steam client
# TODO: unknown if some of these rules need LAN networking
#

# Test if installation exists on system
if ((Test-Installation "Steam" ([ref] $SteamRoot)) -or $ForceLoad)
{
	$Program = "$SteamRoot\Steam.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Steam (game client trafic)" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 27000-27015 `
	-LocalUser $UsersGroupSDDL -LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "" | Format-Output

	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Steam (HTTP/HTTPS)" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
	-LocalUser $UsersSDDL `
	-Description "" | Format-Output

	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Steam downloads" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 27015-27030 `
	-LocalUser $UsersSDDL `
	-Description "" | Format-Output

	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Steam Matchmaking and HLTV" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 27015-27030 `
	-LocalUser $UsersGroupSDDL -LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "" | Format-Output

	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Steam P2P Networking and Steam Voice Chat" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 3478, 4379, 4380 `
	-LocalUser $UsersGroupSDDL -LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "" | Format-Output

	$Program = "$SteamRoot\SteamService.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
	-DisplayName "SteamService" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80 `
	-LocalUser $UsersGroupSDDL -LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "" | Format-Output

	$Program = "$SteamRoot\bin\cef\cef.win7\steamwebhelper.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Steam (webhelper x86)" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
	-LocalUser $UsersSDDL `
	-Description "" | Format-Output

	$Program = "$SteamRoot\bin\cef\cef.win7x64\steamwebhelper.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Steam (webhelper x64)" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
	-LocalUser $UsersSDDL `
	-Description "" | Format-Output
}
