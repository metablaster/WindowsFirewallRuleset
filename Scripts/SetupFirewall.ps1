
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

#
# Full firewall setup according to this repository
#
. $PSScriptRoot\..\Config\ProjectSettings.ps1

# First unblock all files
& "$ProjectRoot\Scripts\UnblockProject.ps1"

# Check requirements
Initialize-Project -Abort
Set-Variable -Name ProjectCheck -Scope Global -Option ReadOnly -Force -Value $false

# Imports
Import-Module -Name Project.AllPlatforms.Logging

# Clear errors, error and warning status
$Error.Clear()
Set-Variable -Name ErrorStatus -Scope Global -Value $false
Set-Variable -Name WarningStatus -Scope Global -Value $false

# Prompt to set screen buffer to recommended value
Set-ScreenBuffer @Logs

# Check all rules that apply to windows services
Test-File $ServiceHost @Logs
Get-NetworkService $ProjectRoot\Rules
Confirm-FileEncoding $ProjectRoot\Rules\NetworkServices.txt
Get-Content -Path $ProjectRoot\Rules\NetworkServices.txt -Encoding $DefaultEncoding |
ForEach-Object {
	Test-Service $_ @Logs
	Update-Log
}

#
# Execute IPv4 rules
#

# NOTE: the order of scripts is the same as it is shown in file explorer of Visual Studio Code

#
# Load Inbound rules
#

# User prompt strings
$IPVersion = "IPv4"
$Direction = "Inbound"
$RuleGroup = "inbound $IPVersion rules"
$Accept = "Continue selecting which $RuleGroup to load"
$Deny = "Skip operation, no rules from '$RuleGroup' group will be loaded"
Update-Context $IPVersion $Direction @Logs

if (Approve-Execute -Title "Selecting: $RuleGroup" -Accept $Accept -Deny $Deny @Logs)
{
	# Update user prompt strings
	$Ruleset = "common rules"
	$Accept = "Start executing scripts from '$Ruleset' ruleset, some of these rules are recommended for proper OS network functioning"
	$Deny = "Skip operation, no '$Ruleset' from '$RuleGroup' group will be loaded"

	if (Approve-Execute -Title "Selecting: $Ruleset" -Accept $Accept -Deny $Deny @Logs)
	{
		# Common rules
		& "$ProjectRoot\Rules\$IPVersion\$Direction\AdditionalNetworking.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\BasicNetworking.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Broadcast.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\ICMP.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Multicast.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\NetworkDiscovery.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\NetworkSharing.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\RemoteWindows.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\StoreApps.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Temporary.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\WindowsServices.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\WirelessNetworking.ps1"
	}

	# Update user prompt strings
	$Ruleset = "rules for developers"
	$Accept = "Start executing scripts from '$Ruleset' ruleset, recommended to create rules if various 3rd party development software is installed"
	$Deny = "Skip operation, no '$Ruleset' from '$RuleGroup' group will be loaded"
	Update-Context $IPVersion $Direction @Logs

	if (Approve-Execute -Title "Selecting: $Ruleset" -Accept $Accept -Deny $Deny @Logs)
	{
		# Rules for developers
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Development\EpicGames.ps1"
	}

	# Update user prompt strings
	$Ruleset = "rules for servers"
	$Accept = "Start executing scripts from '$Ruleset' ruleset, recommended to create rules for server platforms and software"
	$Deny = "Skip operation, no '$Ruleset' from '$RuleGroup' group will be loaded"
	Update-Context $IPVersion $Direction @Logs

	if (Approve-Execute -Default "No" -Title "Selecting: $Ruleset" -Accept $Accept -Deny $Deny @Logs)
	{
		# Rules for servers
		# & "$ProjectRoot\Rules\$IPVersion\$Direction\Server\ScriptName.ps1"

		Write-Warning -Message "No inbound rules for server platforms or software exist"
	}

	# Update user prompt strings
	$Ruleset = "rules for 3rd party programs"
	$Accept = "Start executing scripts from '$Ruleset' ruleset, recommended to create rules for 3rd party software"
	$Deny = "Skip operation, no '$Ruleset' from '$RuleGroup' group will be loaded"
	Update-Context $IPVersion $Direction @Logs

	if (Approve-Execute -Title "Selecting: $Ruleset" -Accept $Accept -Deny $Deny @Logs)
	{
		# rules for programs
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Software\FileZilla.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Software\InternetBrowser.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Software\Steam.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Software\TeamViewer.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Software\uTorrent.ps1"
	}

	# Update user prompt strings
	$Ruleset = "rules for Microsoft programs"
	$Accept = "Start executing scripts from '$Ruleset' ruleset, recommended to create rules for software published by Microsoft"
	$Deny = "Skip operation, no '$Ruleset' from '$RuleGroup' group will be loaded"
	Update-Context $IPVersion $Direction @Logs

	if (Approve-Execute -Title "Selecting: $Ruleset" -Accept $Accept -Deny $Deny @Logs)
	{
		# rules for programs
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Software\Microsoft\MicrosoftOffice.ps1"
	}
}

#
# Load Outbound rules
#

# Update user prompt strings
$IPVersion = "IPv4"
$Direction = "Outbound"
$RuleGroup = "outbound $IPVersion rules"
$Accept = "Continue selecting which $RuleGroup to load"
$Deny = "Skip operation, no rules from '$RuleGroup' group will be loaded"
Update-Context $IPVersion $Direction @Logs

if (Approve-Execute -Title "Selecting: $RuleGroup" -Accept $Accept -Deny $Deny @Logs)
{
	# Update user prompt strings
	$Ruleset = "common rules"
	$Accept = "Start executing scripts from '$Ruleset' ruleset, most of these rules are required for proper OS network functioning"
	$Deny = "Skip operation, no '$Ruleset' from '$RuleGroup' group will be loaded"

	if (Approve-Execute -Title "Selecting: $Ruleset" -Accept $Accept -Deny $Deny @Logs)
	{
		# Common rules
		& "$ProjectRoot\Rules\$IPVersion\$Direction\AdditionalNetworking.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\BasicNetworking.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Broadcast.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\ICMP.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Multicast.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\NetworkDiscovery.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\NetworkSharing.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\RemoteWindows.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\StoreApps.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Temporary.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\WindowsServices.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\WindowsSystem.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\WirelessNetworking.ps1"
	}

	# Update user prompt strings
	$Ruleset = "rules for developers, 3rd party tools"
	$Accept = "Start executing scripts from '$Ruleset' ruleset, recommended to create rules if various 3rd party development software is installed"
	$Deny = "Skip operation, no '$Ruleset' from '$RuleGroup' group will be loaded"
	Update-Context $IPVersion $Direction @Logs

	if (Approve-Execute -Title "Selecting: $Ruleset" -Accept $Accept -Deny $Deny @Logs)
	{
		# Rules for developers
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Development\Chocolatey.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Development\EpicGames.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Development\Github.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Development\Incredibuild.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Development\MSYS2.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Development\RealWorld.ps1"
	}

	# Update user prompt strings
	$Ruleset = "rules for developers, Microsoft tools"
	$Accept = "Start executing scripts from '$Ruleset' ruleset, recommended to create rules if various Microsoft development software is installed"
	$Deny = "Skip operation, no '$Ruleset' from '$RuleGroup' group will be loaded"
	Update-Context $IPVersion $Direction @Logs

	if (Approve-Execute -Title "Selecting: $Ruleset" -Accept $Accept -Deny $Deny @Logs)
	{
		# Rules for developers
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Development\Microsoft\dotnet.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Development\Microsoft\HelpViewer.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Development\Microsoft\NuGet.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Development\Microsoft\PowerShell.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Development\Microsoft\vcpkg.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Development\Microsoft\VisualStudio.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Development\Microsoft\VSCode.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Development\Microsoft\WebPlatform.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Development\Microsoft\WindowsSDK.ps1"
	}

	# Update user prompt strings
	$Ruleset = "rules for games"
	$Accept = "Start executing scripts from '$Ruleset' ruleset, recommended to create rules if multiplayer games are installed"
	$Deny = "Skip operation, no '$Ruleset' from '$RuleGroup' group will be loaded"
	Update-Context $IPVersion $Direction @Logs

	if (Approve-Execute -Title "Selecting: $Ruleset" -Accept $Accept -Deny $Deny @Logs)
	{
		# Rules for games
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Games\ArenaChess.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Games\CounterStrikeGO.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Games\DemiseOfNations.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Games\EVEOnline.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Games\LeagueOfLegends.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Games\OpenTTD.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Games\PathOfExile.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Games\PinballArcade.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Games\PokerStars.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Games\WarThunder.ps1"
	}

	# Update user prompt strings
	$Ruleset = "rules for servers"
	$Accept = "Start executing scripts from '$Ruleset' ruleset, recommended to create rules for server platforms and software"
	$Deny = "Skip operation, no '$Ruleset' from '$RuleGroup' group will be loaded"
	Update-Context $IPVersion $Direction @Logs

	if (Approve-Execute -Title "Selecting: $Ruleset" -Accept $Accept -Deny $Deny @Logs)
	{
		# Rules for servers
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Server\SQLServer.ps1"
	}

	# Update user prompt strings
	$Ruleset = "rules for 3rd party programs"
	$Accept = "Start executing scripts from '$Ruleset' ruleset, recommended to create rules for 3rd party software"
	$Deny = "Skip operation, no '$Ruleset' from '$RuleGroup' group will be loaded"
	Update-Context $IPVersion $Direction @Logs

	if (Approve-Execute -Title "Selecting: $Ruleset" -Accept $Accept -Deny $Deny @Logs)
	{
		# rules for 3rd party programs
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Software\Adobe.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Software\CPUID.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Software\DnsCrypt.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Software\FileZilla.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Software\Google.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Software\GPG.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Software\Greenshot.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Software\Intel.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Software\InternetBrowser.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Software\Java.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Software\Metatrader.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Software\MSI.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Software\Nvidia.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Software\OBSStudio.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Software\OpenSSH.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Software\PasswordSafe.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Software\qBittorrent.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Software\RivaTuner.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Software\Steam.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Software\TeamViewer.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Software\Thunderbird.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Software\uTorrent.ps1"
	}

	# Update user prompt strings
	$Ruleset = "rules for Microsoft programs"
	$Accept = "Start executing scripts from '$Ruleset' ruleset, recommended to create rules for software published by Microsoft"
	$Deny = "Skip operation, no '$Ruleset' from '$RuleGroup' group will be loaded"
	Update-Context $IPVersion $Direction @Logs

	if (Approve-Execute -Title "Selecting: $Ruleset" -Accept $Accept -Deny $Deny @Logs)
	{
		# rules for Microsoft programs
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Software\Microsoft\MicrosoftOffice.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Software\Microsoft\OneDrive.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Software\Microsoft\SysInternals.ps1"
	}
}

#
# Execute IPv6 rules
#

#
# Load Inbound rules
#

# Update user prompt strings
$IPVersion = "IPv6"
$Direction = "Inbound"
$RuleGroup = "inbound $IPVersion Rules"
$Accept = "Continue selecting which $RuleGroup to load"
$Deny = "Skip operation, no rules from '$RuleGroup' group will be loaded"
Update-Context $IPVersion $Direction @Logs

if (Approve-Execute -Title "Selecting: $RuleGroup" -Accept $Accept -Deny $Deny @Logs)
{
	# Update user prompt strings
	$Ruleset = "common rules"
	$Accept = "Start executing scripts from '$Ruleset' ruleset, some of these rules are required for proper OS network functioning even if there is no IPv6 connectivity"
	$Deny = "Skip operation, no '$Ruleset' from '$RuleGroup' group will be loaded"

	if (Approve-Execute -Title "Selecting: $Ruleset" -Accept $Accept -Deny $Deny @Logs)
	{
		# Common rules
		& "$ProjectRoot\Rules\$IPVersion\$Direction\BasicNetworking.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\ICMP.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Multicast.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Temporary.ps1"
	}
}

#
# Load Outbound rules
#

# Update user prompt strings
$IPVersion = "IPv6"
$Direction = "Outbound"
$RuleGroup = "outbound $IPVersion Rules"
$Accept = "Continue selecting which $RuleGroup to load"
$Deny = "Skip operation, no rules from '$RuleGroup' group will be loaded"
Update-Context $IPVersion $Direction @Logs

if (Approve-Execute -Title "Selecting: $RuleGroup" -Accept $Accept -Deny $Deny @Logs)
{
	# Update user prompt strings
	$Ruleset = "common rules"
	$Accept = "Start executing scripts from '$Ruleset' ruleset, most of these rules are required for proper OS network functioning even if there is no IPv6 connectivity"
	$Deny = "Skip operation, no '$Ruleset' from '$RuleGroup' group will be loaded"

	if (Approve-Execute -Title "Selecting: $Ruleset" -Accept $Accept -Deny $Deny @Logs)
	{
		# Common rules
		& "$ProjectRoot\Rules\$IPVersion\$Direction\BasicNetworking.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\ICMP.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Multicast.ps1"
		& "$ProjectRoot\Rules\$IPVersion\$Direction\Temporary.ps1"
	}
}

Write-Information -Tags "User" -MessageData "INFO: Loading rules was completed" @Logs

# Set up global firewall setting, network and firewall profile
& "$ProjectRoot\Scripts\SetupProfile.ps1"

# Update Local Group Policy for changes to take effect
Write-Output ""
gpupdate.exe

if ($Develop)
{
	# TODO: why? probably no longer needed
	# Need to re-import required module in develop mode
	Import-Module -Name Project.AllPlatforms.Logging
}

# Show status of execution
if ($ErrorStatus)
{
	Write-Output ""
	Write-Warning -Message "Errors were generated" @Logs

	Write-Output ""
	Write-Information -Tags "User" -MessageData "INFO: All errors were saved to: $("$ProjectRoot\Logs")" @Logs
	Write-Information -Tags "User" -MessageData "INFO: If module is edited don't forget to restart Powershell" @Logs
}

if ($WarningStatus)
{
	Write-Output ""
	Write-Warning -Message "Warnings were generated" @Logs
	Write-Information -Tags "User" -MessageData "INFO: All warnings were saved to: $("$ProjectRoot\Logs")" @Logs
	Write-Information -Tags "User" -MessageData "INFO: you can review these logs to see if you want to resolve some of them" @Logs
}

if (!$ErrorStatus -and !$WarningStatus)
{
	Write-Output ""
	Write-Information -Tags "User" -MessageData "INFO: All operations completed successfully!" @Logs
}

Write-Output ""
Write-Information -Tags "User" -MessageData "INFO: Make sure you visit Local Group Policy and adjust your rules as needed." @Logs
Write-Output ""

# Clear warning/error status
Set-Variable -Name ErrorStatus -Scope Global -Value $false @Logs
Set-Variable -Name WarningStatus -Scope Global -Value $false @Logs

Update-Log
