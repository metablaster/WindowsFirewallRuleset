
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

. $PSScriptRoot\..\..\..\..\Config\ProjectSettings.ps1

# Check requirements
Initialize-Project

# Imports
. $PSScriptRoot\..\DirectionSetup.ps1
. $PSScriptRoot\..\..\IPSetup.ps1
Import-Module -Name Project.AllPlatforms.Logging
Import-Module -Name Project.Windows.UserInfo

#
# Setup local variables
#
$Group = "Games - League of Legends"
$FirewallProfile = "Private, Public"

# User prompt
Update-Context "IPv$IPVersion" $Direction $Group @Logs
if (!(Approve-Execute @Logs)) { exit }

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore @Logs

#
# League of Legends installation directories
#
# NOTE: The path should be ""%ProgramFiles(x86)%\Riot Games" but root to game is added,
# for consistency with Find-Installation, see todo below for info
$LoLRoot = "%ProgramFiles(x86)%\Riot Games\League of Legends"

#
# Rules for League of Legends
# Below is official link for firewall rules, however it seems like it's not up to date
# https://support-leagueoflegends.riotgames.com/hc/en-us/articles/201752664-Troubleshooting-Connection-Issues
#

# Test if installation exists on system
if ((Test-Installation "LoLGame" ([ref] $LoLRoot) @Logs) -or $ForceLoad)
{
	# TODO: trimming such as the one below is present in multiple rule scripts, we should do
	# this job universally inside "Test-Installation" function instead

	# Returned path is root to game, instead of installation root
	$LoLRoot = Split-Path $LoLRoot -Parent

	$Program = "$LoLRoot\Riot Client\RiotClientServices.exe"
	Test-File $Program @Logs

	New-NetFirewallRule -DisplayName "LoL launcher services" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 443 `
		-LocalUser $UsersGroupSDDL `
		-InterfaceType $Interface `
		-Description "Game launcher services, server traffic" `
		@Logs | Format-Output @Logs

	# TODO: Official site says both 5222 and 5223 but 5222 is not used
	New-NetFirewallRule -DisplayName "LoL launcher services - PVP.Net" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 5223 `
		-LocalUser $UsersGroupSDDL `
		-InterfaceType $Interface `
		-Description "Game launcher services - PVP.Net (game chat)" `
		@Logs | Format-Output @Logs

	$Program = "$LoLRoot\Riot Client\UX\RiotClientUx.exe"
	Test-File $Program @Logs

	# TODO: rule not used or not tested
	New-NetFirewallRule -DisplayName "LoL launcher services - user experience" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 443 `
		-LocalUser $UsersGroupSDDL `
		-InterfaceType $Interface `
		-Description "Game launcher services - user experience" `
		@Logs | Format-Output @Logs

	$Program = "$LolRoot\League of Legends\LeagueClient.exe"
	Test-File $Program @Logs

	New-NetFirewallRule -DisplayName "LoL launcher client" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 80, 443 `
		-LocalUser $UsersGroupSDDL `
		-InterfaceType $Interface `
		-Description "Game launcher client - UI (user interface),
The Launcher is the initial window that checks for game updates and launches the PVP.net client
for League of Legends." `
		@Logs | Format-Output @Logs

	New-NetFirewallRule -DisplayName "LoL launcher client - PVP.net" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 2099 `
		-LocalUser $UsersGroupSDDL `
		-InterfaceType $Interface `
		-Description "PVP.net is a platform for League of Legends to launch from.
It allows you to add friends, check the League of Legends store, and join chat rooms.
PVP.net can be considered a separate entity from the actual game but the two are linked and cannot
be used separately." `
		@Logs | Format-Output @Logs

	$Program = "$LolRoot\League of Legends\LeagueClientUx.exe"
	Test-File $Program @Logs

	New-NetFirewallRule -DisplayName "LoL launcher client - user experience" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 80, 443 `
		-LocalUser $UsersGroupSDDL `
		-InterfaceType $Interface `
		-Description "game client - UX (user experience)" `
		@Logs | Format-Output @Logs

	$Program = "$LolRoot\League of Legends\Game\League of Legends.exe"
	Test-File $Program @Logs

	New-NetFirewallRule -DisplayName "LoL game client - multiplayer" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 5000-5500 `
		-LocalUser $UsersGroupSDDL `
		-InterfaceType $Interface `
		-LocalOnlyMapping $false -LooseSourceMapping $false `
		-Description "Game online multiplayer traffic" `
		@Logs | Format-Output @Logs

	New-NetFirewallRule -DisplayName "LoL game client - server" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 443 `
		-LocalUser $UsersGroupSDDL `
		-InterfaceType $Interface `
		-Description "Game client server traffic" `
		@Logs | Format-Output @Logs

	# TODO: rule not used or not tested
	New-NetFirewallRule -DisplayName "LoL game client - PVP.net" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 2099 `
		-LocalUser $UsersGroupSDDL `
		-InterfaceType $Interface `
		-Description "PVP.net is a platform for League of Legends to launch from.
It allows you to add friends, check the League of Legends store, and join chat rooms.
PVP.net can be considered a separate entity from the actual game but the two are linked and cannot
be used separately." `
		@Logs | Format-Output @Logs

	# TODO: need to test spectator traffic
	New-NetFirewallRule -DisplayName "LoL game client - spectator" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 8088 `
		-LocalUser $UsersGroupSDDL `
		-InterfaceType $Interface `
		-LocalOnlyMapping $false -LooseSourceMapping $false `
		-Description "Game spectator UDP traffic" `
		@Logs | Format-Output @Logs

	New-NetFirewallRule -DisplayName "LoL game client - spectator" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 8088 `
		-LocalUser $UsersGroupSDDL `
		-InterfaceType $Interface `
		-Description "Game spectator UDP traffic" `
		@Logs | Format-Output @Logs
}

Update-Log
