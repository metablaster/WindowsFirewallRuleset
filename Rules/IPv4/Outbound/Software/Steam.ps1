
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
Outbound firewall rules for Steam

.DESCRIPTION
Outbound firewall rules for Steam client

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
PS> .\Steam.ps1

.INPUTS
None. You cannot pipe objects to Steam.ps1

.OUTPUTS
None. Steam.ps1 does not generate any output

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
. $PSScriptRoot\..\..\..\..\Config\ProjectSettings.ps1 $PSCmdlet
. $PSScriptRoot\..\DirectionSetup.ps1

Initialize-Project -Strict
Import-Module -Name Ruleset.UserInfo

# Setup local variables
$Group = "Software - Steam"
$Accept = "Outbound rules for Steam client will be loaded, recommended if Steam client is installed to let it access to network"
$Deny = "Skip operation, outbound client for Steam software will not be loaded into firewall"

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

$BroadcastAddress = Get-InterfaceBroadcast

#
# Steam installation directories
#
$SteamRoot = "%ProgramFiles(x86)%\Steam"
$SteamCommon = "%ProgramFiles(x86)%\Common Files\Steam"

#
# Rules for Steam client
# TODO: unknown if some of these rules need LAN networking, edit: adjusted for In-Home Streaming
#

# Test if installation exists on system
if ((Confirm-Installation "Steam" ([ref] $SteamRoot)) -or $ForceLoad)
{
	$Program = "$SteamRoot\Steam.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "Steam (game client traffic)" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 27000-27015 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-LocalOnlyMapping $false -LooseSourceMapping $false `
			-Description "" | Format-RuleOutput

		New-NetFirewallRule -DisplayName "Steam (In-Home Streaming)" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
			-LocalAddress Any -RemoteAddress LocalSubnet4, $BroadcastAddress `
			-LocalPort 27031, 27036 -RemotePort 27031, 27036 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-LocalOnlyMapping $false -LooseSourceMapping $false `
			-Description "Steam's In-Home Streaming allows you to stream PC games from one PC to
another PC on the same local network." | Format-RuleOutput

		New-NetFirewallRule -DisplayName "Steam (In-Home Streaming)" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress LocalSubnet4, $BroadcastAddress `
			-LocalPort 27036, 27037 -RemotePort 27036, 27037 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "Steam's In-Home Streaming allows you to stream PC games from one PC to
another PC on the same local network." | Format-RuleOutput

		New-NetFirewallRule -DisplayName "Steam (HTTP/HTTPS)" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 80, 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "" | Format-RuleOutput

		New-NetFirewallRule -DisplayName "Steam downloads" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 27015-27030 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "" | Format-RuleOutput

		New-NetFirewallRule -DisplayName "Steam Matchmaking and HLTV" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 27015-27030 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-LocalOnlyMapping $false -LooseSourceMapping $false `
			-Description "" | Format-RuleOutput

		New-NetFirewallRule -DisplayName "Steam P2P Networking and Steam Voice Chat" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 3478, 4379, 4380 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-LocalOnlyMapping $false -LooseSourceMapping $false `
			-Description "" | Format-RuleOutput
	}

	$Program = "$SteamCommon\SteamService.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "SteamService" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 80 `
			-LocalUser $LocalSystem `
			-InterfaceType $DefaultInterface `
			-Description "" | Format-RuleOutput
	}

	# TODO: For all x86 rules we need checks, since those don't exist on x86 systems
	# This path is sometimes cef.win7 sometimes cef.win7x64, need solution for this
	# NOTE: It looks like cef.win7 is used during installation of steam on x64 system, and,
	# cef.win7x64 after installation is done, could be cef.win7 is used on x86 in both cases.
	$Program = "$SteamRoot\bin\cef\cef.win7\steamwebhelper.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "Steam (webhelper x86)" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 80, 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "" | Format-RuleOutput
	}

	if ([System.Environment]::Is64BitOperatingSystem)
	{
		$Program = "$SteamRoot\bin\cef\cef.win7x64\steamwebhelper.exe"
		if ((Test-ExecutableFile $Program) -or $ForceLoad)
		{
			New-NetFirewallRule -DisplayName "Steam (webhelper x64)" `
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
}

if ($UpdateGPO)
{
	Invoke-Process gpupdate.exe -NoNewWindow -ArgumentList "/target:computer"
}

Update-Log
