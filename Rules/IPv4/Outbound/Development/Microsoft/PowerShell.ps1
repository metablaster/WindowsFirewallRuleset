
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

. $PSScriptRoot\..\..\..\..\..\Config\ProjectSettings.ps1

# Check requirements for this project
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.System
Test-SystemRequirements

# Includes
. $PSScriptRoot\..\..\DirectionSetup.ps1
. $PSScriptRoot\..\..\..\IPSetup.ps1
Import-Module -Name $ProjectRoot\Modules\Project.Windows.UserInfo
Import-Module -Name $ProjectRoot\Modules\Project.Windows.ProgramInfo
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Logging
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Utility

#
# Setup local variables:
#
$Group = "Development - Microsoft PowerShell"
$Profile = "Private, Public"

# Ask user if he wants to load these rules
Update-Context "IPv$IPVersion" $Direction $Group @Logs
if (!(Approve-Execute @Logs)) { exit }

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction SilentlyContinue

#
# PowerShell installation directories
#
$PowerShell64Root = "" #"%SystemRoot%\System32\WindowsPowerShell\v1.0"
$PowerShell86Root = "" #"%SystemRoot%\SysWOW64\WindowsPowerShell\v1.0"
$PowerShellCore64Root = ""

#
# Rules for PowerShell
#

# TODO: add rules for Core
# NOTE: administartors may need powershell, let them add them self temporary? currently adding them for PS x64
$PowerShellUsers = Get-SDDL -Groups @("Users", "Administrators")

# Test if installation exists on system
if ((Test-Installation "Powershell64" ([ref] $PowerShell64Root)) -or $Force)
{
	$Program = "$PowerShell64Root\powershell_ise.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
	-DisplayName "PowerShell ISE x64" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
	-LocalUser $UsersSDDL `
	-Description "Rule to allow powershell help update" | Format-Output

	$Program = "$PowerShell64Root\powershell.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
	-DisplayName "PowerShell x64" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
	-LocalUser $PowerShellUsers `
	-Description "Rule to allow powershell help update" | Format-Output
}

# Test if installation exists on system
if ((Test-Installation "PowershellCore64" ([ref] $PowerShellCore64Root)) -or $Force)
{
	$Program = "$PowerShellCore64Root\pwsh.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
	-DisplayName "PowerShell Core x64" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
	-LocalUser $PowerShellUsers `
	-Description "Rule to allow powershell help update" | Format-Output
}

# Test if installation exists on system
if ((Test-Installation "Powershell86" ([ref] $PowerShell86Root)) -or $Force)
{
	$Program = "$PowerShell86Root\powershell_ise.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
	-DisplayName "PowerShell ISE x86" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
	-LocalUser $UsersSDDL `
	-Description "Rule to allow powershell help update" | Format-Output

	$Program = "$PowerShell86Root\powershell.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
	-DisplayName "PowerShell x86" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
	-LocalUser $UsersSDDL `
	-Description "Rule to allow powershell help update" | Format-Output
}
