
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

. $PSScriptRoot\Config\ProjectSettings.ps1

# First unblock all files
& "$ProjectRoot\UnblockProject.ps1"

# Check requirements
Initialize-Project
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
Get-Content -Path $ProjectRoot\Rules\NetworkServices.txt -Encoding utf8 | ForEach-Object {
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

Update-Context "IPv4" "Inbound" @Logs

if (Approve-Execute "Yes" "Applying: Inbound IPv4 Rules" @Logs)
{
	if (Approve-Execute "Yes" "Applying: Common rules" @Logs)
	{
		# Common rules
		& "$PSScriptRoot\Rules\IPv4\Inbound\AdditionalNetworking.ps1"
		& "$PSScriptRoot\Rules\IPv4\Inbound\BasicNetworking.ps1"
		& "$PSScriptRoot\Rules\IPv4\Inbound\Broadcast.ps1"
		& "$PSScriptRoot\Rules\IPv4\Inbound\ICMP.ps1"
		& "$PSScriptRoot\Rules\IPv4\Inbound\Multicast.ps1"
		& "$PSScriptRoot\Rules\IPv4\Inbound\NetworkDiscovery.ps1"
		& "$PSScriptRoot\Rules\IPv4\Inbound\NetworkSharing.ps1"
		& "$PSScriptRoot\Rules\IPv4\Inbound\RemoteWindows.ps1"
		& "$PSScriptRoot\Rules\IPv4\Inbound\StoreApps.ps1"
		& "$PSScriptRoot\Rules\IPv4\Inbound\Temporary.ps1"
		& "$PSScriptRoot\Rules\IPv4\Inbound\WindowsServices.ps1"
		& "$PSScriptRoot\Rules\IPv4\Inbound\WirelessNetworking.ps1"
	}

	Update-Context "IPv4" "Inbound" @Logs
	if (Approve-Execute "Yes" "Applying: Rules for developers" @Logs)
	{
		# Rules for developers
		& "$PSScriptRoot\Rules\IPv4\Inbound\Development\EpicGames.ps1"
	}

	# Update-Context "IPv4" "Inbound"
	# if (Approve-Execute "Yes" "Applying: Rules for servers")
	# {
	# 	# Rules for developers
	# 	& "$PSScriptRoot\Rules\IPv4\Inbound\Server\ScriptName.ps1"
	# }

	Update-Context "IPv4" "Inbound" @Logs
	if (Approve-Execute "Yes" "Applying: Rules for 3rd party programs" @Logs)
	{
		# rules for programs
		& "$PSScriptRoot\Rules\IPv4\Inbound\Software\FileZilla.ps1"
		& "$PSScriptRoot\Rules\IPv4\Inbound\Software\InternetBrowser.ps1"
		& "$PSScriptRoot\Rules\IPv4\Inbound\Software\Steam.ps1"
		& "$PSScriptRoot\Rules\IPv4\Inbound\Software\TeamViewer.ps1"
		& "$PSScriptRoot\Rules\IPv4\Inbound\Software\uTorrent.ps1"
	}

	Update-Context "IPv4" "Inbound" @Logs
	if (Approve-Execute "Yes" "Applying: Rules for Microsoft programs" @Logs)
	{
		# rules for programs
		& "$PSScriptRoot\Rules\IPv4\Inbound\Software\Microsoft\MicrosoftOffice.ps1"
	}
}

#
# Load Outbound rules
#
Update-Context "IPv4" "Outbound" @Logs

if (Approve-Execute "Yes" "Applying: Outbound IPv4 Rules" @Logs)
{
	if (Approve-Execute "Yes" "Applying: Common rules" @Logs)
	{
		# Common rules
		& "$PSScriptRoot\Rules\IPv4\Outbound\AdditionalNetworking.ps1"
		& "$PSScriptRoot\Rules\IPv4\Outbound\BasicNetworking.ps1"
		& "$PSScriptRoot\Rules\IPv4\Outbound\Broadcast.ps1"
		& "$PSScriptRoot\Rules\IPv4\Outbound\ICMP.ps1"
		& "$PSScriptRoot\Rules\IPv4\Outbound\Multicast.ps1"
		& "$PSScriptRoot\Rules\IPv4\Outbound\NetworkDiscovery.ps1"
		& "$PSScriptRoot\Rules\IPv4\Outbound\NetworkSharing.ps1"
		& "$PSScriptRoot\Rules\IPv4\Outbound\RemoteWindows.ps1"
		& "$PSScriptRoot\Rules\IPv4\Outbound\StoreApps.ps1"
		& "$PSScriptRoot\Rules\IPv4\Outbound\Temporary.ps1"
		& "$PSScriptRoot\Rules\IPv4\Outbound\WindowsServices.ps1"
		& "$PSScriptRoot\Rules\IPv4\Outbound\WindowsSystem.ps1"
		& "$PSScriptRoot\Rules\IPv4\Outbound\WirelessNetworking.ps1"
	}

	Update-Context "IPv4" "Outbound" @Logs
	if (Approve-Execute "Yes" "Applying: Rules for developers 3rd party tools" @Logs)
	{
		# Rules for developers
		& "$PSScriptRoot\Rules\IPv4\Outbound\Development\Chocolatey.ps1"
		& "$PSScriptRoot\Rules\IPv4\Outbound\Development\EpicGames.ps1"
		& "$PSScriptRoot\Rules\IPv4\Outbound\Development\Github.ps1"
		& "$PSScriptRoot\Rules\IPv4\Outbound\Development\Incredibuild.ps1"
		& "$PSScriptRoot\Rules\IPv4\Outbound\Development\MSYS2.ps1"
		& "$PSScriptRoot\Rules\IPv4\Outbound\Development\RealWorld.ps1"
	}

	Update-Context "IPv4" "Outbound" @Logs
	if (Approve-Execute "Yes" "Applying: Rules for developers Microsoft tools" @Logs)
	{
		# Rules for developers
		& "$PSScriptRoot\Rules\IPv4\Outbound\Development\Microsoft\HelpViewer.ps1"
		& "$PSScriptRoot\Rules\IPv4\Outbound\Development\Microsoft\NuGet.ps1"
		& "$PSScriptRoot\Rules\IPv4\Outbound\Development\Microsoft\PowerShell.ps1"
		& "$PSScriptRoot\Rules\IPv4\Outbound\Development\Microsoft\vcpkg.ps1"
		& "$PSScriptRoot\Rules\IPv4\Outbound\Development\Microsoft\VisualStudio.ps1"
		& "$PSScriptRoot\Rules\IPv4\Outbound\Development\Microsoft\VSCode.ps1"
		& "$PSScriptRoot\Rules\IPv4\Outbound\Development\Microsoft\WebPlatform.ps1"
		& "$PSScriptRoot\Rules\IPv4\Outbound\Development\Microsoft\WindowsSDK.ps1"
	}

	Update-Context "IPv4" "Outbound" @Logs
	if (Approve-Execute "Yes" "Applying: Rules for games" @Logs)
	{
		# Rules for games
		& "$PSScriptRoot\Rules\IPv4\Outbound\Games\ArenaChess.ps1"
		& "$PSScriptRoot\Rules\IPv4\Outbound\Games\CounterStrikeGO.ps1"
		& "$PSScriptRoot\Rules\IPv4\Outbound\Games\DemiseOfNations.ps1"
		& "$PSScriptRoot\Rules\IPv4\Outbound\Games\EVEOnline.ps1"
		& "$PSScriptRoot\Rules\IPv4\Outbound\Games\LeagueOfLegends.ps1"
		& "$PSScriptRoot\Rules\IPv4\Outbound\Games\OpenTTD.ps1"
		& "$PSScriptRoot\Rules\IPv4\Outbound\Games\PathOfExile.ps1"
		& "$PSScriptRoot\Rules\IPv4\Outbound\Games\PinballArcade.ps1"
		& "$PSScriptRoot\Rules\IPv4\Outbound\Games\PokerStars.ps1"
		& "$PSScriptRoot\Rules\IPv4\Outbound\Games\WarThunder.ps1"
	}

	# Update-Context "IPv4" "Outbound"
	# if (Approve-Execute "Yes" "Applying: Rules for servers")
	# {
	# 	# Rules for developers
	# 	& "$PSScriptRoot\Rules\IPv4\Outbound\Server\ScriptName.ps1"
	# }

	Update-Context "IPv4" "Outbound" @Logs
	if (Approve-Execute "Yes" "Applying: Rules for 3rd party programs" @Logs)
	{
		# rules for programs
		& "$PSScriptRoot\Rules\IPv4\Outbound\Software\Adobe.ps1"
		& "$PSScriptRoot\Rules\IPv4\Outbound\Software\CPUID.ps1"
		& "$PSScriptRoot\Rules\IPv4\Outbound\Software\DnsCrypt.ps1"
		& "$PSScriptRoot\Rules\IPv4\Outbound\Software\FileZilla.ps1"
		& "$PSScriptRoot\Rules\IPv4\Outbound\Software\Google.ps1"
		& "$PSScriptRoot\Rules\IPv4\Outbound\Software\GPG.ps1"
		& "$PSScriptRoot\Rules\IPv4\Outbound\Software\Greenshot.ps1"
		& "$PSScriptRoot\Rules\IPv4\Outbound\Software\Intel.ps1"
		& "$PSScriptRoot\Rules\IPv4\Outbound\Software\InternetBrowser.ps1"
		& "$PSScriptRoot\Rules\IPv4\Outbound\Software\Java.ps1"
		& "$PSScriptRoot\Rules\IPv4\Outbound\Software\Metatrader.ps1"
		& "$PSScriptRoot\Rules\IPv4\Outbound\Software\MSI.ps1"
		& "$PSScriptRoot\Rules\IPv4\Outbound\Software\Nvidia.ps1"
		& "$PSScriptRoot\Rules\IPv4\Outbound\Software\OBSStudio.ps1"
		& "$PSScriptRoot\Rules\IPv4\Outbound\Software\OpenSSH.ps1"
		& "$PSScriptRoot\Rules\IPv4\Outbound\Software\PasswordSafe.ps1"
		& "$PSScriptRoot\Rules\IPv4\Outbound\Software\qBittorrent.ps1"
		& "$PSScriptRoot\Rules\IPv4\Outbound\Software\RivaTuner.ps1"
		& "$PSScriptRoot\Rules\IPv4\Outbound\Software\Steam.ps1"
		& "$PSScriptRoot\Rules\IPv4\Outbound\Software\TeamViewer.ps1"
		& "$PSScriptRoot\Rules\IPv4\Outbound\Software\Thunderbird.ps1"
		& "$PSScriptRoot\Rules\IPv4\Outbound\Software\uTorrent.ps1"
	}

	Update-Context "IPv4" "Outbound" @Logs
	if (Approve-Execute "Yes" "Applying: Rules for Microsoft programs" @Logs)
	{
		# rules for Microsoft programs
		& "$PSScriptRoot\Rules\IPv4\Outbound\Software\Microsoft\MicrosoftOffice.ps1"
		& "$PSScriptRoot\Rules\IPv4\Outbound\Software\Microsoft\OneDrive.ps1"
		& "$PSScriptRoot\Rules\IPv4\Outbound\Software\Microsoft\SysInternals.ps1"
	}
}

#
# Execute IPv6 rules
#

#
# Load Inbound rules
#
Update-Context "IPv6" "Inbound" @Logs

if (Approve-Execute "Yes" "Applying: Inbound IPv6 Rules" @Logs)
{
	if (Approve-Execute "Yes" "Applying: Common rules" @Logs)
	{
		# Common rules
		& "$PSScriptRoot\Rules\IPv6\Inbound\BasicNetworking.ps1"
		& "$PSScriptRoot\Rules\IPv6\Inbound\ICMP.ps1"
		& "$PSScriptRoot\Rules\IPv6\Inbound\Multicast.ps1"
		& "$PSScriptRoot\Rules\IPv6\Inbound\Temporary.ps1"
	}
}

#
# Load Outbound rules
#
Update-Context "IPv6" "Outbound" @Logs

if (Approve-Execute "Yes" "Applying: Outbound IPv6 Rules" @Logs)
{
	if (Approve-Execute "Yes" "Applying: Common rules" @Logs)
	{
		# Common rules
		& "$PSScriptRoot\Rules\IPv6\Outbound\BasicNetworking.ps1"
		& "$PSScriptRoot\Rules\IPv6\Outbound\ICMP.ps1"
		& "$PSScriptRoot\Rules\IPv6\Outbound\Multicast.ps1"
		& "$PSScriptRoot\Rules\IPv6\Outbound\Temporary.ps1"
	}
}

Write-Output ""

# Set up global firewall setting, network and firewall profile
& .\SetupProfile.ps1

if ($Develop)
{
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
