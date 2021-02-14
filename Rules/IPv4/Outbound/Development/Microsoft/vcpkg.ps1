
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2021 metablaster zebal@protonmail.ch

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

.PARAMETER Force
If specified, no prompt to run script is shown

.PARAMETER Trusted
If specified, rules will be loaded for executables with missing or invalid digital signature.
By default an error is generated and rule isn't loaded.

.EXAMPLE
PS> .\vcpkg.ps1

.INPUTS
None. You cannot pipe objects to vcpkg.ps1

.OUTPUTS
None. vcpkg.ps1 does not generate any output

.NOTES
TODO: There are many potential executables that may be downloaded by vcpkg and that may need firewall rules
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding()]
param (
	[Parameter()]
	[switch] $Trusted,

	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\..\..\..\..\Config\ProjectSettings.ps1 $PSCmdlet
. $PSScriptRoot\..\..\DirectionSetup.ps1

Initialize-Project -Strict
Import-Module -Name Ruleset.UserInfo

# Setup local variables
$Group = "Development - Microsoft vcpkg"
$Accept = "Outbound rules for vcpkg repository will be loaded, recommended if vcpkg repository is installed to let it access to network"
$Deny = "Skip operation, outbound rules for vcpkg repository will not be loaded into firewall"

if (!(Approve-Execute -Accept $Accept -Deny $Deny -ContextLeaf $Group -Force:$Force)) { exit }
$PSDefaultParameterValues["Test-ExecutableFile:Force"] = $Trusted -or $SkipSignatureCheck
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
if ((Confirm-Installation "vcpkg" ([ref] $vcpkgRoot)) -or $ForceLoad)
{
	$Program = "$vcpkgRoot\scripts\tls12-download.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "vcpkg (bootstrap)" `
		 -Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "bootstrap vcpkg" | Format-RuleOutput
	}

	$Program = "$vcpkgRoot\vcpkg.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "vcpkg" `
		 -Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "install package source code" | Format-RuleOutput
	}

	# TODO: need to update for all users
	# TODO: this bad path somehow gets into rule
	$Program = "%SystemDrive%\Users\$DefaultUser\AppData\Local\Temp\vcpkg\vcpkgmetricsuploader-2020.02.04.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "vcpkg (telemetry)" `
		 -Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "vcpkg sends usage data to Microsoft" | Format-RuleOutput
	}

	$Program = "$vcpkgRoot\downloads\tools\powershell-core-6.2.1-windows\powershell.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "vcpkg (powershell)" `
		 -Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "vcpkg has it's own powershell" | Format-RuleOutput
	}

	# TODO: if cmake in root and of required version it's used, needs conditional rule
	# $Program = "$vcpkgRoot\downloads\tools\cmake-3.14.0-windows\cmake-3.14.0-win32-x86\bin\cmake.exe"
	# Test-ExecutableFile $Program
	# New-NetFirewallRule -DisplayName "vcpkg (cmake)" `
	# -Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
	# 	-Service Any -Program $Program -Group $Group `
	# 	-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
	# 	-LocalAddress Any -RemoteAddress Internet4 `
	# -LocalPort Any -RemotePort 443 `
	# 	-LocalUser $UsersGroupSDDL `
	# -InterfaceType $DefaultInterface `
	# 	-Description "vcpkg has it's own cmake" | Format-RuleOutput

	# TODO: Why cmd needs network to download packages, is it just temporary?
	$Program = Format-Path "C:\Windows\SysWOW64"
	$Program += "\cmd.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "cmd" `
		 -Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 80, 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "" | Format-RuleOutput
	}
}

if ($UpdateGPO)
{
	Invoke-Process gpupdate.exe -NoNewWindow -ArgumentList "/target:computer"
}

Update-Log
