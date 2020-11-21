
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

<#
.SYNOPSIS
Outbound firewall rules for vcpkg

.DESCRIPTION
Outbound firewall rules for vcpkg C++ library manager

.EXAMPLE
PS> .\vcpkg.ps1

.INPUTS
None. You cannot pipe objects to vcpkg.ps1

.OUTPUTS
None. vcpkg.ps1 does not generate any output

.NOTES
None.
#>

#region Initialization
#Requires -RunAsAdministrator
. $PSScriptRoot\..\..\..\..\..\Config\ProjectSettings.ps1

# Check requirements
Initialize-Project -Abort

# Imports
. $PSScriptRoot\..\..\DirectionSetup.ps1
Import-Module -Name Ruleset.UserInfo

# Setup local variables
$Group = "Development - Microsoft vcpkg"
$Accept = "Outbound rules for vcpkg repository will be loaded, recommended if vcpkg repository is installed to let it access to network"
$Deny = "Skip operation, outbound rules for vcpkg repository will not be loaded into firewall"

# User prompt
Update-Context "IPv$IPVersion" $Direction $Group
if (!(Approve-Execute -Accept $Accept -Deny $Deny)) { exit }
#endregion

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore

#
# vcpkg installation directories
#
$vcpkgRoot = "Unknown Directory"

#
# Rules for vcpkg
#

# Test if installation exists on system
if ((Test-Installation "vcpkg" ([ref] $vcpkgRoot)) -or $ForceLoad)
{
	$Program = "$vcpkgRoot\vcpkg.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
		-DisplayName "vcpkg" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
		-LocalUser $UsersGroupSDDL `
		-Description "install package source code" | Format-Output

	# TODO: need to update for all users
	# TODO: this bad path somehow gets into rule
	$Program = "%SystemDrive%\Users\$DefaultUser\AppData\Local\Temp\vcpkg\vcpkgmetricsuploader-2020.02.04.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
		-DisplayName "vcpkg (telemetry)" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
		-LocalUser $UsersGroupSDDL `
		-Description "vcpkg sends usage data to Microsoft" | Format-Output

	$Program = "$vcpkgRoot\downloads\tools\powershell-core-6.2.1-windows\powershell.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
		-DisplayName "vcpkg (powershell)" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
		-LocalUser $UsersGroupSDDL `
		-Description "vcpkg has it's own powershell" | Format-Output

	# TODO: if cmake in root and of required version it's used, needs conditional rule
	# $Program = "$vcpkgRoot\downloads\tools\cmake-3.14.0-windows\cmake-3.14.0-win32-x86\bin\cmake.exe"
	# Test-File $Program
	# New-NetFirewallRule -Platform $Platform `
	# 	-DisplayName "vcpkg (cmake)" -Service Any -Program $Program `
	# 	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
	# 	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
	# 	-LocalUser $UsersGroupSDDL `
	# 	-Description "vcpkg has it's own cmake" | Format-Output

	# TODO: Why cmd needs network to download packages, is it just temporary?
	$Program = Format-Path "C:\Windows\SysWOW64"
	$Program += "\cmd.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
		-DisplayName "cmd" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
		-LocalUser $UsersGroupSDDL `
		-Description "" | Format-Output
}

Update-Log
