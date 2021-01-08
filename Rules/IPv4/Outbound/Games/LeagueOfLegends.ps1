
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
Outbound firewall rules for LeagueOfLegends

.DESCRIPTION
Outbound firewall rules for League Of Legends multiplayer game

.PARAMETER Force
If specified, no prompt to run script is shown.

.PARAMETER Trusted
If specified, rules will be loaded for executables with missing or invalid digital signature.
By default an error is generated and rule isn't loaded.

.EXAMPLE
PS> .\LeagueOfLegends.ps1

.INPUTS
None. You cannot pipe objects to LeagueOfLegends.ps1

.OUTPUTS
None. LeagueOfLegends.ps1 does not generate any output

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
Initialize-Project -Strict

# Imports
. $PSScriptRoot\..\DirectionSetup.ps1
Import-Module -Name Ruleset.UserInfo

# Setup local variables
$Group = "Games - League of Legends"
$Accept = "Outbound rules for League of Legends game will be loaded, recommended if League of Legends game is installed to let it access to network"
$Deny = "Skip operation, outbound rules for League of Legends game will not be loaded into firewall"

# User prompt
Update-Context "IPv$IPVersion" $Direction $Group
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
$PSDefaultParameterValues["Test-ExecutableFile:Force"] = $Trusted -or $SkipSignatureCheck
#endregion

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore

#
# League of Legends installation directories
#
# NOTE: The path should be ""%ProgramFiles(x86)%\Riot Games" but root to game is added,
# for consistency with Search-Installation, see todo below for info
$LoLRoot = "%ProgramFiles(x86)%\Riot Games\League of Legends"

#
# Rules for League of Legends
# Below is official link for firewall rules, however it seems like it's not up to date
# https://support-leagueoflegends.riotgames.com/hc/en-us/articles/201752664-Troubleshooting-Connection-Issues
#

# Test if installation exists on system
if ((Confirm-Installation "LoLGame" ([ref] $LoLRoot)) -or $ForceLoad)
{
	# TODO: trimming such as the one below is present in multiple rule scripts, we should do
	# this job universally inside "Confirm-Installation" function instead

	# Returned path is root to game, instead of installation root
	$LoLRoot = Split-Path $LoLRoot -Parent

	$Program = "$LoLRoot\Riot Client\RiotClientServices.exe"
	if (Test-ExecutableFile $Program)
	{
		New-NetFirewallRule -DisplayName "LoL launcher services" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "Game launcher services, server traffic" |
		Format-Output

		# TODO: Official site says both 5222 and 5223 but 5222 is not used
		New-NetFirewallRule -DisplayName "LoL launcher services - PVP.Net" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 5223 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "Game launcher services - PVP.Net (game chat)" |
		Format-Output
	}

	$Program = "$LoLRoot\Riot Client\UX\RiotClientUx.exe"
	if (Test-ExecutableFile $Program)
	{
		# TODO: rule not used or not tested
		New-NetFirewallRule -DisplayName "LoL launcher services - user experience" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "Game launcher services - user experience" |
		Format-Output
	}

	$Program = "$LolRoot\League of Legends\LeagueClient.exe"
	if (Test-ExecutableFile $Program)
	{
		New-NetFirewallRule -DisplayName "LoL launcher client" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 80, 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "Game launcher client - UI (user interface),
The Launcher is the initial window that checks for game updates and launches the PVP.net client
for League of Legends." |
		Format-Output

		New-NetFirewallRule -DisplayName "LoL launcher client - PVP.net" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 2099 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "PVP.net is a platform for League of Legends to launch from.
It allows you to add friends, check the League of Legends store, and join chat rooms.
PVP.net can be considered a separate entity from the actual game but the two are linked and cannot
be used separately." |
		Format-Output
	}

	$Program = "$LolRoot\League of Legends\LeagueClientUx.exe"
	if (Test-ExecutableFile $Program)
	{
		New-NetFirewallRule -DisplayName "LoL launcher client - user experience" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 80, 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "game client - UX (user experience)" |
		Format-Output
	}

	$Program = "$LolRoot\League of Legends\Game\League of Legends.exe"
	if (Test-ExecutableFile $Program)
	{
		New-NetFirewallRule -DisplayName "LoL game client - multiplayer" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 5000-5500 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-LocalOnlyMapping $false -LooseSourceMapping $false `
			-Description "Game online multiplayer traffic" |
		Format-Output

		New-NetFirewallRule -DisplayName "LoL game client - server" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "Game client server traffic" |
		Format-Output

		# TODO: rule not used or not tested
		New-NetFirewallRule -DisplayName "LoL game client - PVP.net" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 2099 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "PVP.net is a platform for League of Legends to launch from.
It allows you to add friends, check the League of Legends store, and join chat rooms.
PVP.net can be considered a separate entity from the actual game but the two are linked and cannot
be used separately." |
		Format-Output

		# TODO: need to test spectator traffic
		New-NetFirewallRule -DisplayName "LoL game client - spectator" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 8088 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-LocalOnlyMapping $false -LooseSourceMapping $false `
			-Description "Game spectator UDP traffic" |
		Format-Output

		New-NetFirewallRule -DisplayName "LoL game client - spectator" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 8088 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "Game spectator UDP traffic" |
		Format-Output
	}
}

Update-Log
