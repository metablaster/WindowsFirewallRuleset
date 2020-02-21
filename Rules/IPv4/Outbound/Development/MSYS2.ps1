
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
Import-Module -Name $RepoDir\Modules\Project.AllPlatforms.System
Test-SystemRequirements

# Includes
. $PSScriptRoot\..\DirectionSetup.ps1
. $PSScriptRoot\..\..\IPSetup.ps1
Import-Module -Name $RepoDir\Modules\Project.Windows.UserInfo
Import-Module -Name $RepoDir\Modules\Project.Windows.ProgramInfo
Import-Module -Name $RepoDir\Modules\Project.AllPlatforms.Logging
Import-Module -Name $RepoDir\Modules\Project.AllPlatforms.Utility

#
# Setup local variables:
#
$Group = "Development - MSYS2"
$Profile = "Private, Public"

# Ask user if he wants to load these rules
Update-Context "IPv$IPVersion" $Direction $Group
if (!(Approve-Execute)) { exit }

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction SilentlyContinue

#
# Steam installation directories
#
$MSYS2Root = "%SystemRoot%\dev\msys64"

#
# Rules for Steam client
#

# Test if installation exists on system
if ((Test-Installation "MSYS2" ([ref] $MSYS2Root)) -or $Force)
{
	$Program = "$MSYS2Root\usr\bin\curl.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
	-DisplayName "MSYS2 - curl" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 21, 80 `
	-LocalUser $UserAccountsSDDL `
	-Description "download with curl in MSYS2 shell" | Format-Output

	$Program = "$MSYS2Root\usr\bin\git.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
	-DisplayName "MSYS2 - git protocol" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 9418 `
	-LocalUser $UserAccountsSDDL `
	-Description "git access over git:// protocol" | Format-Output

	$Program = "$MSYS2Root\usr\bin\git-remote-https.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
	-DisplayName "MSYS2 - git-remote-https" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
	-LocalUser $UserAccountsSDDL `
	-Description "git over HTTPS in MSYS2 shell" | Format-Output

	$Program = "$MSYS2Root\usr\bin\ssh.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
	-DisplayName "MSYS2 - git SSH" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 22 `
	-LocalUser $UserAccountsSDDL `
	-Description "git over SSH in MSYS2 shell" | Format-Output

	$Program = "$MSYS2Root\mingw64\bin\glade.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
	-DisplayName "MSYS2 - glade help" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
	-LocalUser $UserAccountsSDDL `
	-Description "Get online help for glade" | Format-Output

	$Program = "$MSYS2Root\usr\bin\pacman.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
	-DisplayName "MSYS2 - pacman" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
	-LocalUser $UserAccountsSDDL `
	-Description "pacman package manager in MSYS2 shell" | Format-Output

	$Program = "$MSYS2Root\usr\bin\pacman.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
	-DisplayName "MSYS2 - wget" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80 `
	-LocalUser $UserAccountsSDDL `
	-Description "HTTP dowload manager" | Format-Output
}
