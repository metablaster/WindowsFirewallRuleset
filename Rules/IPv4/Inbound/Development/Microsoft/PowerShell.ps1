
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2021 metablaster zebal@protonmail.ch

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
Inbound firewall rules for PowerShell

.DESCRIPTION
Inbound firewall rules for PowerShell Core and Desktop editions

.PARAMETER Trusted
If specified, rules will be loaded for executables with missing or invalid digital signature.
By default an error is generated and rule isn't loaded.

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\PowerShell.ps1

.INPUTS
None. You cannot pipe objects to PowerShell.ps1

.OUTPUTS
None. PowerShell.ps1 does not generate any output

.NOTES
TODO: Rules for Core x86 remoting are missing
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
$Group = "Development - Microsoft PowerShell"
$Accept = "Inbound rules for PowerShell are needed for remoting"
$Deny = "Skip operation, inbound rules for PowerShell will not be loaded into firewall"

if (!(Approve-Execute -Accept $Accept -Deny $Deny -ContextLeaf $Group -Force:$Force)) { exit }
$PSDefaultParameterValues["Test-ExecutableFile:Force"] = $Trusted -or $SkipSignatureCheck
#endregion

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore

#
# PowerShell installation directories
#
$PowerShell64Root = "%SystemRoot%\System32\WindowsPowerShell\v1.0"
$PowerShell86Root = "%SystemRoot%\SysWOW64\WindowsPowerShell\v1.0"
$PowerShellCore64Root = "%PROGRAMFILES%\PowerShell\7"

#
# Rules for PowerShell
#

if ((Confirm-Installation "Powershell64" ([ref] $PowerShell64Root)) -or $ForceLoad)
{
	$Program = "$PowerShell64Root\powershell.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "PowerShell x64 remoting" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile Private, Domain `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress LocalSubnet4 `
			-LocalPort Any -RemotePort 5985 `
			-LocalUser $AdminGroupSDDL -EdgeTraversalPolicy Block `
			-InterfaceType $DefaultInterface `
			-Description "Rule for PowerShell Desktop to allow connections from remote hosts" |
		Format-RuleOutput
	}

	$Program = "$PowerShell64Root\powershell_ise.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "PowerShell ISE x64 remoting" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile Private, Domain `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress LocalSubnet4 `
			-LocalPort Any -RemotePort 5985 `
			-LocalUser $AdminGroupSDDL -EdgeTraversalPolicy Block `
			-InterfaceType $DefaultInterface `
			-Description "Rule for PowerShell ISE to allow connections from remote hosts" |
		Format-RuleOutput
	}
}

if ((Confirm-Installation "PowershellCore64" ([ref] $PowerShellCore64Root)) -or $ForceLoad)
{
	$Program = "$PowerShellCore64Root\pwsh.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "PowerShell Core x64 remoting" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile Private, Domain `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress LocalSubnet4 `
			-LocalPort Any -RemotePort 5985 `
			-LocalUser $AdminGroupSDDL -EdgeTraversalPolicy Block `
			-InterfaceType $DefaultInterface `
			-Description "Rule for PowerShell Core to allow connections from remote hosts" |
		Format-RuleOutput
	}
}

if ((Confirm-Installation "Powershell86" ([ref] $PowerShell86Root)) -or $ForceLoad)
{
	$Program = "$PowerShell86Root\powershell.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "PowerShell x86 remoting" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile Private, Domain `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress LocalSubnet4 `
			-LocalPort Any -RemotePort 5985 `
			-LocalUser $AdminGroupSDDL -EdgeTraversalPolicy Block `
			-InterfaceType $DefaultInterface `
			-Description "Rule for PowerShell Desktop to allow connections from remote hosts" |
		Format-RuleOutput
	}

	$Program = "$PowerShell86Root\powershell_ise.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "PowerShell ISE x86 remoting" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile Private, Domain `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress LocalSubnet4 `
			-LocalPort Any -RemotePort 5985 `
			-LocalUser $AdminGroupSDDL -EdgeTraversalPolicy Block `
			-InterfaceType $DefaultInterface `
			-Description "Rule for PowerShell ISE to allow connections from remote hosts" |
		Format-RuleOutput
	}
}

if ($UpdateGPO)
{
	Invoke-Process gpupdate.exe -NoNewWindow -ArgumentList "/target:computer"
}

Update-Log
