
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
Outbound firewall rules for Steam

.DESCRIPTION
Outbound firewall rules for Steam client

.PARAMETER Force
If specified, no prompt to run script is shown.

.PARAMETER Trusted
If specified, rules will be loaded for executables with missing or invalid digital signature.
By default an error is generated and rule isn't loaded.

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
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\..\..\..\Config\ProjectSettings.ps1 $PSCmdlet

# Check requirements
Initialize-Project -Abort

# Imports
. $PSScriptRoot\..\DirectionSetup.ps1
Import-Module -Name Ruleset.UserInfo

# Setup local variables
$Group = "Software - Steam"
$Accept = "Outbound rules for Steam client will be loaded, recommended if Steam client is installed to let it access to network"
$Deny = "Skip operation, outbound client for Steam software will not be loaded into firewall"

# User prompt
Update-Context "IPv$IPVersion" $Direction $Group
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
$PSDefaultParameterValues["Test-ExecutableFile:Force"] = $Trusted -or $SkipSignatureCheck
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
	if (Test-ExecutableFile $Program)
	{
		New-NetFirewallRule -Platform $Platform `
			-DisplayName "Steam (game client traffic)" -Service Any -Program $Program `
			-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
			-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 27000-27015 `
			-LocalUser $UsersGroupSDDL -LocalOnlyMapping $false -LooseSourceMapping $false `
			-Description "" | Format-Output

		New-NetFirewallRule -Platform $Platform `
			-DisplayName "Steam (In-Home Streaming)" -Service Any -Program $Program `
			-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
			-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress LocalSubnet4, $BroadcastAddress -LocalPort 27031, 27036 -RemotePort 27031, 27036 `
			-LocalUser $UsersGroupSDDL -LocalOnlyMapping $false -LooseSourceMapping $false `
			-Description "Steam's In-Home Streaming allows you to stream PC games from one PC to
another PC on the same local network." | Format-Output

		New-NetFirewallRule -Platform $Platform `
			-DisplayName "Steam (In-Home Streaming)" -Service Any -Program $Program `
			-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
			-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress LocalSubnet4, $BroadcastAddress -LocalPort 27036, 27037 -RemotePort 27036, 27037 `
			-LocalUser $UsersGroupSDDL `
			-Description "Steam's In-Home Streaming allows you to stream PC games from one PC to
another PC on the same local network." | Format-Output

		New-NetFirewallRule -Platform $Platform `
			-DisplayName "Steam (HTTP/HTTPS)" -Service Any -Program $Program `
			-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
			-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
			-LocalUser $UsersGroupSDDL `
			-Description "" | Format-Output

		New-NetFirewallRule -Platform $Platform `
			-DisplayName "Steam downloads" -Service Any -Program $Program `
			-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
			-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 27015-27030 `
			-LocalUser $UsersGroupSDDL `
			-Description "" | Format-Output

		New-NetFirewallRule -Platform $Platform `
			-DisplayName "Steam Matchmaking and HLTV" -Service Any -Program $Program `
			-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
			-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 27015-27030 `
			-LocalUser $UsersGroupSDDL -LocalOnlyMapping $false -LooseSourceMapping $false `
			-Description "" | Format-Output

		New-NetFirewallRule -Platform $Platform `
			-DisplayName "Steam P2P Networking and Steam Voice Chat" -Service Any -Program $Program `
			-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
			-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 3478, 4379, 4380 `
			-LocalUser $UsersGroupSDDL -LocalOnlyMapping $false -LooseSourceMapping $false `
			-Description "" | Format-Output
	}

	$Program = "$SteamCommon\SteamService.exe"
	if (Test-ExecutableFile $Program)
	{
		New-NetFirewallRule -Platform $Platform `
			-DisplayName "SteamService" -Service Any -Program $Program `
			-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
			-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80 `
			-LocalUser $LocalSystem `
			-Description "" | Format-Output
	}

	# TODO: For all x86 rules we need checks, since those don't exist on x86 systems
	# This path is sometimes cef.win7 sometimes cef.win7x64, need solution for this
	# NOTE: It looks like cef.win7 is used during installation of steam on x64 system, and,
	# cef.win7x64 after installation is done, could be cef.win7 is used on x86 in both cases.
	$Program = "$SteamRoot\bin\cef\cef.win7\steamwebhelper.exe"
	if (Test-ExecutableFile $Program)
	{
		New-NetFirewallRule -Platform $Platform `
			-DisplayName "Steam (webhelper x86)" -Service Any -Program $Program `
			-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
			-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
			-LocalUser $UsersGroupSDDL `
			-Description "" | Format-Output
	}

	if ([System.Environment]::Is64BitOperatingSystem)
	{
		$Program = "$SteamRoot\bin\cef\cef.win7x64\steamwebhelper.exe"
		if (Test-ExecutableFile $Program)
		{
			New-NetFirewallRule -Platform $Platform `
				-DisplayName "Steam (webhelper x64)" -Service Any -Program $Program `
				-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
				-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
				-LocalUser $UsersGroupSDDL `
				-Description "" | Format-Output
		}
	}
}

Update-Log
