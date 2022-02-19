
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2022 metablaster zebal@protonmail.ch

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
Inbound firewall rules for sysinternals

.DESCRIPTION
Inbound firewall rules for sysinternals software suite

.PARAMETER Trusted
If specified, rules will be loaded for executables with missing or invalid digital signature.
By default an error is generated and rule isn't loaded.

.PARAMETER Interactive
If program installation directory is not found, script will ask user to
specify program installation location.

.PARAMETER Quiet
If specified, it suppresses warning, error or informationall messages if user specified or default
program path does not exist or if it's of an invalid syntax needed for firewall.

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\SysInternals.ps1

.INPUTS
None. You cannot pipe objects to SysInternals.ps1

.OUTPUTS
None. SysInternals.ps1 does not generate any output

.NOTES
None.
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding()]
param (
	[Parameter()]
	[switch] $Trusted,

	[Parameter()]
	[switch] $Interactive,

	[Parameter()]
	[switch] $Quiet,

	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\..\..\..\..\Config\ProjectSettings.ps1 $PSCmdlet
. $PSScriptRoot\..\..\DirectionSetup.ps1

Initialize-Project -Strict
Import-Module -Name Ruleset.UserInfo

# Setup local variables
$Group = "Microsoft - SysInternals"
$SysInternalsUsers = Get-SDDL -Group "Users", "Administrators" -Merge
$Accept = "Inbound rules for SysInternals software will be loaded, recommended if SysInternals software is installed to let it access to network"
$Deny = "Skip operation, inbound rules for SysInternals software will not be loaded into firewall"

if (!(Approve-Execute -Accept $Accept -Deny $Deny -ContextLeaf $Group -Force:$Force)) { exit }
$PSDefaultParameterValues = @{
	"Confirm-Installation:Quiet" = $Quiet
	"Confirm-Installation:Interactive" = $Interactive
	"Confirm-Installation:Session" = $SessionInstance
	"Confirm-Installation:CimSession" = $CimServer
	"Test-ExecutableFile:Quiet" = $Quiet
	"Test-ExecutableFile:Force" = $Trusted -or $SkipSignatureCheck
	"Test-ExecutableFile:Session" = $SessionInstance
}
#endregion

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore

#
# SysInternals installation directories
#
$SysInternalsRoot = "%SystemDrive%\tools"

#
# Rules for SysInternals
#

# Test if installation exists on system
if ((Confirm-Installation "SysInternals" ([ref] $SysInternalsRoot)) -or $ForceLoad)
{
	$Program = "$SysInternalsRoot\psping.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "Sysinternals PSPing server" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol Any `
			-LocalAddress Any -RemoteAddress Any `
			-LocalPort Any -RemotePort Any `
			-LocalUser $SysInternalsUsers -EdgeTraversalPolicy Block `
			-InterfaceType $DefaultInterface `
			-Description "PsPing implements Ping functionality, TCP ping, latency and bandwidth measurement.
Due to wide range of address and port options these should be set to Any.
This rule serves to allow PSPing.exe to act as a server." | Format-RuleOutput
	}

	$Program = "$SysInternalsRoot\psping64.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "Sysinternals PSPing64 server" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol Any `
			-LocalAddress Any -RemoteAddress Any `
			-LocalPort Any -RemotePort Any `
			-LocalUser $SysInternalsUsers -EdgeTraversalPolicy Block `
			-InterfaceType $DefaultInterface `
			-Description "PsPing implements Ping functionality, TCP ping, latency and bandwidth measurement.
Due to wide range of address and port options these should be set to Any.
This rule serves to allow PSPing64.exe to act as a server." | Format-RuleOutput
	}
}

if ($UpdateGPO)
{
	Invoke-Process gpupdate.exe -NoNewWindow -ArgumentList "/target:computer"
}

Update-Log
