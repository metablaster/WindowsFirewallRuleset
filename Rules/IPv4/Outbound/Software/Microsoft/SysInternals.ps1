
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
Outbound firewall rules for sysinternals

.DESCRIPTION
Outbound firewall rules for sysinternals software suite

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
$Accept = "Outbound rules for SysInternals software will be loaded, recommended if SysInternals software is installed to let it access to network"
$Deny = "Skip operation, outbound rules for SysInternals software will not be loaded into firewall"

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
	$Program = "$SysInternalsRoot\Autoruns64.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "Sysinternals Autoruns" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $SysInternalsUsers `
			-InterfaceType $DefaultInterface `
			-Description "Access to VirusTotal" | Format-RuleOutput
	}

	# TODO: It also uses port 80 but not known for what, not setting here.
	# Most likely to fetch symbols
	$Program = "$SysInternalsRoot\procexp64.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "Sysinternals ProcessExplorer" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $SysInternalsUsers `
			-InterfaceType $DefaultInterface `
			-Description "Access to VirusTotal" | Format-RuleOutput
	}

	$Program = "$SysInternalsRoot\Procmon.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "Sysinternals ProcessMonitor" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $SysInternalsUsers `
			-InterfaceType $DefaultInterface `
			-Description "Access to symbols server" | Format-RuleOutput
	}

	$Program = "$SysInternalsRoot\Tcpview.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "Sysinternals TcpView" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 43 `
			-LocalUser $SysInternalsUsers `
			-InterfaceType $DefaultInterface `
			-Description "WhoIs access" | Format-RuleOutput
	}

	$Program = "$SysInternalsRoot\whois64.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "Sysinternals WhoIs" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 43 `
			-LocalUser $SysInternalsUsers `
			-InterfaceType $DefaultInterface `
			-Description "WhoIs performs the registration record for the domain name or IP address
that you specify" | Format-RuleOutput
	}

	$Program = "$SysInternalsRoot\psping.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "Sysinternals PSPing client" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol Any `
			-LocalAddress Any -RemoteAddress Any `
			-LocalPort Any -RemotePort Any `
			-LocalUser $SysInternalsUsers `
			-InterfaceType $DefaultInterface `
			-Description "PsPing implements Ping functionality, TCP ping, latency and bandwidth measurement.
Due to wide range of address and port options these should be set to Any.
This rule serves to allow PSPing.exe to act as a client." | Format-RuleOutput
	}

	$Program = "$SysInternalsRoot\psping64.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "Sysinternals PSPing64 client" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol Any `
			-LocalAddress Any -RemoteAddress Any `
			-LocalPort Any -RemotePort Any `
			-LocalUser $SysInternalsUsers `
			-InterfaceType $DefaultInterface `
			-Description "PsPing implements Ping functionality, TCP ping, latency and bandwidth measurement.
Due to wide range of address and port options these should be set to Any.
This rule serves to allow PSPing64.exe to act as a client." | Format-RuleOutput
	}

	$Program = "$SysInternalsRoot\sigcheck.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "Sysinternals sigcheck" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $SysInternalsUsers `
			-InterfaceType $DefaultInterface `
			-Description "Connection to virus total to upload file for scan" |
		Format-RuleOutput
	}

	$Program = "$SysInternalsRoot\sigcheck64.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "Sysinternals sigcheck64" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $SysInternalsUsers `
			-InterfaceType $DefaultInterface `
			-Description "Connection to virus total to upload file for scan" |
		Format-RuleOutput
	}
}

if ($UpdateGPO)
{
	Invoke-Process gpupdate.exe -NoNewWindow -ArgumentList "/target:computer"
}

Update-Log
