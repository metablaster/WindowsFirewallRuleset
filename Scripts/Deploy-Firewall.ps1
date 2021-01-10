
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

<#PSScriptInfo

.VERSION 0.9.1

.GUID d7809432-c822-4699-9244-97c8da8d64bf

.AUTHOR metablaster zebal@protonmail.com
#>

<#
.SYNOPSIS
Deploy firewall rules and configuration to local or remote computer.

.DESCRIPTION
Deploy-Firewall.ps1 is a master script to deploy rules and configuration to local and/or multiple
remote computers.

.PARAMETER Force
If specified, no prompt for confirmation is shown to perform actions

.EXAMPLE
PS> .\Deploy-Firewall.ps1

.INPUTS
None. You cannot pipe objects to Deploy-Firewall.ps1

.OUTPUTS
None. Deploy-Firewall.ps1 does not generate any output

.NOTES
TODO: This script should be simplified by using Get-ChildItem to get all rule scripts.
TODO: Logic should probably be separated into separate scripts: Deploy-FirewallRules, Complete-Profile etc.
TODO: OutputType attribute
TODO: Setup trap for this script to restore global variables

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/tree/master/Scripts
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding()]
param (
	[Parameter()]
	[switch] $Force
)

#region Initialization
& $PSScriptRoot\Unblock-Project.ps1
. $PSScriptRoot\..\Config\ProjectSettings.ps1 $PSCmdlet

Initialize-Project -Strict

# User prompt
$ExecuteParams = @{
	Accept = "Deploy firewall to '$PolicyStore' computer"
	Deny = "Abort firewall deployment operation"
	Force = $Force
}

if (!(Approve-Execute @ExecuteParams)) { exit }
Write-Information -Tags "User" -MessageData "INFO: Initializing deployment..."

# Skip checking requirements for all subsequent operations
Set-Variable -Name ProjectCheck -Scope Global -Option ReadOnly -Force -Value $false

# Clear errors, error and warning status, disable auto GPO update
$Error.Clear()
Set-Variable -Name ErrorStatus -Scope Global -Value $false
Set-Variable -Name WarningStatus -Scope Global -Value $false
Set-Variable -Name UpdateGPO -Scope Global -Value $false

# Prompt to set screen buffer to recommended value
Set-ScreenBuffer 4000

# Check all rules which apply to windows services
Build-ServiceList $ProjectRoot\Rules -Log | Test-Service | Out-Null
Update-Log
#endregion

#
# Deploy Inbound IPv4 rules
# NOTE: the order of scripts is the same as it is shown in file explorer of Visual Studio Code
#
$Destination = "$ProjectRoot\Rules\IPv4\Inbound"

# User prompt strings
$ExecuteParams["Accept"] = "Continue prompting which inbound IPv4 rules to deploy"
$ExecuteParams["Deny"] = "Skip all inbound IPv4 rules"
$ExecuteParams["Title"] = "Selecting inbound IPv4 rules"
$ExecuteParams["Question"] = "Do you want to deploy these rules?"
$ExecuteParams["Context"] = "IPv4\Inbound"

if (Approve-Execute @ExecuteParams)
{
	# Update user prompt strings
	$ExecuteParams["Accept"] = "Continue prompting which core rules to deploy"
	$ExecuteParams["Deny"] = "Skip all core rules"
	$ExecuteParams["Title"] = "Selecting core rules"

	if (Approve-Execute @ExecuteParams)
	{
		# Core rules
		& "$Destination\AdditionalNetworking.ps1" -Force:$Force
		& "$Destination\Broadcast.ps1" -Force:$Force
		& "$Destination\CoreNetworking.ps1" -Force:$Force
		& "$Destination\ICMP.ps1" -Force:$Force
		& "$Destination\Multicast.ps1" -Force:$Force
		& "$Destination\NetworkDiscovery.ps1" -Force:$Force
		& "$Destination\NetworkSharing.ps1" -Force:$Force
		& "$Destination\RemoteWindows.ps1" -Force:$Force
		& "$Destination\StoreApps.ps1" -Force:$Force
		& "$Destination\Temporary.ps1" -Force:$Force
		& "$Destination\WindowsServices.ps1" -Force:$Force
		& "$Destination\WirelessNetworking.ps1" -Force:$Force
	}

	# Update user prompt strings
	$ExecuteParams["Accept"] = "Continue prompting which rules for 3rd party development software to deploy"
	$ExecuteParams["Deny"] = "Skip all rules for 3rd party development software"
	$ExecuteParams["Title"] = "Selecting rules for 3rd party development software"

	if (Approve-Execute @ExecuteParams)
	{
		# Rules for 3rd party development software
		& "$Destination\Development\EpicGames.ps1" -Force:$Force
	}

	# Update user prompt strings
	$ExecuteParams["Accept"] = "Continue prompting which rules for games to deploy"
	$ExecuteParams["Deny"] = "Skip all rules for games"
	$ExecuteParams["Title"] = "Selecting rules for games"
	$ExecuteParams["Unsafe"] = $true

	if (Approve-Execute @ExecuteParams)
	{
		# Rules for games
		# & "$Destination\Games\ScriptName.ps1" -Force:$Force

		Write-Warning -Message "No inbound rules for games exist"
	}

	# Update user prompt strings
	$ExecuteParams["Accept"] = "Continue prompting which rules for servers to deploy"
	$ExecuteParams["Deny"] = "Skip all rules for servers"
	$ExecuteParams["Title"] = "Selecting rules for servers"

	if (Approve-Execute @ExecuteParams)
	{
		# Rules for servers
		# & "$Destination\Server\ScriptName.ps1" -Force:$Force

		Write-Warning -Message "No inbound rules for server platforms or software exist"
	}

	# Update user prompt strings
	$ExecuteParams["Accept"] = "Continue prompting which rules for 3rd party software to deploy"
	$ExecuteParams["Deny"] = "Skip all rules for 3rd party software"
	$ExecuteParams["Title"] = "Selecting rules for 3rd party software"
	$ExecuteParams.Remove("Unsafe")

	if (Approve-Execute @ExecuteParams)
	{
		# Rules for 3rd party software
		& "$Destination\Software\FileZilla.ps1" -Force:$Force
		& "$Destination\Software\InternetBrowser.ps1" -Force:$Force
		& "$Destination\Software\Steam.ps1" -Force:$Force
		& "$Destination\Software\TeamViewer.ps1" -Force:$Force
		& "$Destination\Software\uTorrent.ps1" -Force:$Force
	}

	# Update user prompt strings
	$ExecuteParams["Accept"] = "Continue prompting which rules for Microsoft software to deploy"
	$ExecuteParams["Deny"] = "Skip all rules for Microsoft software"
	$ExecuteParams["Title"] = "Selecting rules for Microsoft software"

	if (Approve-Execute @ExecuteParams)
	{
		# Rules for Microsoft software
		& "$Destination\Software\Microsoft\MicrosoftOffice.ps1" -Force:$Force
		& "$Destination\Software\Microsoft\SysInternals.ps1" -Force:$Force
	}
}

#
# Deploy Outbound IPv4 rules
#
$Destination = "$ProjectRoot\Rules\IPv4\Outbound"

# Update user prompt strings
$ExecuteParams["Accept"] = "Continue prompting which outbound IPv4 rules to deploy"
$ExecuteParams["Deny"] = "Skip all outbound IPv4 rules"
$ExecuteParams["Title"] = "Selecting outbound IPv4 rules"
$ExecuteParams["Context"] = "IPv4\Outbound"

if (Approve-Execute @ExecuteParams)
{
	# Update user prompt strings
	$ExecuteParams["Accept"] = "Continue prompting which core rules to deploy"
	$ExecuteParams["Deny"] = "Skip all core rules"
	$ExecuteParams["Title"] = "Selecting core rules"

	if (Approve-Execute @ExecuteParams)
	{
		# Core rules
		& "$Destination\AdditionalNetworking.ps1" -Force:$Force
		& "$Destination\Broadcast.ps1" -Force:$Force
		& "$Destination\CoreNetworking.ps1" -Force:$Force
		& "$Destination\ICMP.ps1" -Force:$Force
		& "$Destination\Multicast.ps1" -Force:$Force
		& "$Destination\NetworkDiscovery.ps1" -Force:$Force
		& "$Destination\NetworkSharing.ps1" -Force:$Force
		& "$Destination\RemoteWindows.ps1" -Force:$Force
		& "$Destination\StoreApps.ps1" -Force:$Force
		& "$Destination\Temporary.ps1" -Force:$Force
		& "$Destination\WindowsServices.ps1" -Force:$Force
		& "$Destination\WindowsSystem.ps1" -Force:$Force
		& "$Destination\WirelessNetworking.ps1" -Force:$Force
	}

	# Update user prompt strings
	$ExecuteParams["Accept"] = "Continue prompting which rules for 3rd party development software to deploy"
	$ExecuteParams["Deny"] = "Skip all rules for 3rd party development software"
	$ExecuteParams["Title"] = "Selecting rules for 3rd party development software"

	if (Approve-Execute @ExecuteParams)
	{
		# Rules for 3rd party development software
		& "$Destination\Development\Chocolatey.ps1" -Force:$Force
		& "$Destination\Development\CMake.ps1" -Force:$Force
		& "$Destination\Development\EpicGames.ps1" -Force:$Force
		& "$Destination\Development\GitHub.ps1" -Force:$Force
		& "$Destination\Development\Incredibuild.ps1" -Force:$Force
		& "$Destination\Development\MSYS2.ps1" -Force:$Force
		& "$Destination\Development\RealWorld.ps1" -Force:$Force
	}

	# Update user prompt strings
	$ExecuteParams["Accept"] = "Continue prompting which rules for Microsoft development software to deploy"
	$ExecuteParams["Deny"] = "Skip all rules for Microsoft development software"
	$ExecuteParams["Title"] = "Selecting rules for Microsoft development software"

	if (Approve-Execute @ExecuteParams)
	{
		# Rules for Microsoft development software
		& "$Destination\Development\Microsoft\dotnet.ps1" -Force:$Force
		& "$Destination\Development\Microsoft\HelpViewer.ps1" -Force:$Force
		& "$Destination\Development\Microsoft\NuGet.ps1" -Force:$Force
		& "$Destination\Development\Microsoft\PowerShell.ps1" -Force:$Force
		& "$Destination\Development\Microsoft\vcpkg.ps1" -Force:$Force
		& "$Destination\Development\Microsoft\VisualStudio.ps1" -Force:$Force
		& "$Destination\Development\Microsoft\VSCode.ps1" -Force:$Force
		& "$Destination\Development\Microsoft\WebPlatform.ps1" -Force:$Force
		& "$Destination\Development\Microsoft\WindowsSDK.ps1" -Force:$Force
	}

	# Update user prompt strings
	$ExecuteParams["Accept"] = "Continue prompting which rules for games to deploy"
	$ExecuteParams["Deny"] = "Skip all rules for games"
	$ExecuteParams["Title"] = "Selecting rules for games"

	if (Approve-Execute @ExecuteParams)
	{
		# Rules for games
		& "$Destination\Games\ArenaChess.ps1" -Force:$Force
		& "$Destination\Games\CounterStrikeGO.ps1" -Force:$Force
		& "$Destination\Games\DemiseOfNations.ps1" -Force:$Force
		& "$Destination\Games\EVEOnline.ps1" -Force:$Force
		& "$Destination\Games\LeagueOfLegends.ps1" -Force:$Force
		& "$Destination\Games\OpenTTD.ps1" -Force:$Force
		& "$Destination\Games\PathOfExile.ps1" -Force:$Force
		& "$Destination\Games\PinballArcade.ps1" -Force:$Force
		& "$Destination\Games\PokerStars.ps1" -Force:$Force
		& "$Destination\Games\WarThunder.ps1" -Force:$Force
	}

	# Update user prompt strings
	$ExecuteParams["Accept"] = "Continue prompting which rules for servers to deploy"
	$ExecuteParams["Deny"] = "Skip all rules for servers"
	$ExecuteParams["Title"] = "Selecting rules for servers"

	if (Approve-Execute @ExecuteParams)
	{
		# Rules for servers
		& "$Destination\Server\SQLServer.ps1" -Force:$Force
	}

	# Update user prompt strings
	$ExecuteParams["Accept"] = "Continue prompting which rules for 3rd party software to deploy"
	$ExecuteParams["Deny"] = "Skip all rules for 3rd party software"
	$ExecuteParams["Title"] = "Selecting rules for 3rd party software"

	if (Approve-Execute @ExecuteParams)
	{
		# Rules for 3rd party programs
		& "$Destination\Software\Adobe.ps1" -Force:$Force
		& "$Destination\Software\CPUID.ps1" -Force:$Force
		& "$Destination\Software\DnsCrypt.ps1" -Force:$Force
		& "$Destination\Software\FileZilla.ps1" -Force:$Force
		& "$Destination\Software\Google.ps1" -Force:$Force
		& "$Destination\Software\GPG.ps1" -Force:$Force
		& "$Destination\Software\Greenshot.ps1" -Force:$Force
		& "$Destination\Software\Intel.ps1" -Force:$Force
		& "$Destination\Software\InternetBrowser.ps1" -Force:$Force
		& "$Destination\Software\Java.ps1" -Force:$Force
		& "$Destination\Software\Metatrader.ps1" -Force:$Force
		& "$Destination\Software\MSI.ps1" -Force:$Force
		& "$Destination\Software\Nvidia.ps1" -Force:$Force
		& "$Destination\Software\OBSStudio.ps1" -Force:$Force
		& "$Destination\Software\OpenSSH.ps1" -Force:$Force
		& "$Destination\Software\PasswordSafe.ps1" -Force:$Force
		& "$Destination\Software\qBittorrent.ps1" -Force:$Force
		& "$Destination\Software\RivaTuner.ps1" -Force:$Force
		& "$Destination\Software\Steam.ps1" -Force:$Force
		& "$Destination\Software\TeamViewer.ps1" -Force:$Force
		& "$Destination\Software\Thunderbird.ps1" -Force:$Force
		& "$Destination\Software\uTorrent.ps1" -Force:$Force
	}

	# Update user prompt strings
	$ExecuteParams["Accept"] = "Continue prompting which rules for Microsoft software to deploy"
	$ExecuteParams["Deny"] = "Skip all rules for Microsoft software"
	$ExecuteParams["Title"] = "Selecting rules for Microsoft software"

	if (Approve-Execute @ExecuteParams)
	{
		# Rules for Microsoft programs
		& "$Destination\Software\Microsoft\BingWallpaper.ps1" -Force:$Force
		& "$Destination\Software\Microsoft\EdgeChromium.ps1" -Force:$Force
		& "$Destination\Software\Microsoft\MicrosoftOffice.ps1" -Force:$Force
		& "$Destination\Software\Microsoft\OneDrive.ps1" -Force:$Force
		& "$Destination\Software\Microsoft\SysInternals.ps1" -Force:$Force
	}
}

#
# Deploy Inbound IPv6 rules
#
$Destination = "$ProjectRoot\Rules\IPv6\Inbound"

# Update user prompt strings
$ExecuteParams["Accept"] = "Continue prompting which inbound IPv6 rules to deploy"
$ExecuteParams["Deny"] = "Skip all inbound IPv6 rules"
$ExecuteParams["Title"] = "Selecting inbound IPv6 rules"
$ExecuteParams["Context"] = "IPv6\Inbound"

if (Approve-Execute @ExecuteParams)
{
	# Update user prompt strings
	$ExecuteParams["Accept"] = "Continue prompting which core rules to deploy"
	$ExecuteParams["Deny"] = "Skip all core rules"
	$ExecuteParams["Title"] = "Selecting core rules"

	if (Approve-Execute @ExecuteParams)
	{
		# Core rules
		& "$Destination\CoreNetworking.ps1" -Force:$Force
		& "$Destination\ICMP.ps1" -Force:$Force
		& "$Destination\Multicast.ps1" -Force:$Force
		& "$Destination\Temporary.ps1" -Force:$Force
	}
}

#
# Deploy Outbound rules
#
$Destination = "$ProjectRoot\Rules\IPv6\Outbound"

# Update user prompt strings
$ExecuteParams["Accept"] = "Continue prompting which outbound IPv6 rules to deploy"
$ExecuteParams["Deny"] = "Skip all outbound IPv6 rules"
$ExecuteParams["Title"] = "Selecting outbound IPv6 rules"
$ExecuteParams["Context"] = "IPv6\Outbound"

if (Approve-Execute @ExecuteParams)
{
	# Update user prompt strings
	$ExecuteParams["Accept"] = "Continue prompting which core rules to deploy"
	$ExecuteParams["Deny"] = "Skip all core rules"
	$ExecuteParams["Title"] = "Selecting core rules"

	if (Approve-Execute @ExecuteParams)
	{
		# Core rules
		& "$Destination\CoreNetworking.ps1" -Force:$Force
		& "$Destination\ICMP.ps1" -Force:$Force
		& "$Destination\Multicast.ps1" -Force:$Force
		& "$Destination\Temporary.ps1" -Force:$Force
	}
}

Write-Information -Tags "User" -MessageData "INFO: Deployment of firewall rules is complete"

# Set up global firewall setting, network and firewall profile and apply GPO changes
& "$ProjectRoot\Scripts\Complete-Firewall.ps1" -Force:$Force
Set-Variable -Name UpdateGPO -Scope Global -Value $true

# Set desktop shortcut to custom management console
Set-Shortcut -Name "Firewall.lnk" -Path "AllUsersDesktop" -TargetPath "$ProjectRoot\Config\Windows\Firewall.msc" -Admin `
	-Description "View and modify GPO firewall" -IconLocation "$Env:SystemDrive\Windows\System32\Shell32.dll" -IconIndex -19

# Show execution status
if ($ErrorLogging -and $ErrorStatus)
{
	Write-Output ""
	Write-Warning -Message "Errors were generated and saved to: $("$ProjectRoot\Logs")"
	Write-Information -Tags "User" -MessageData "INFO: You can review these logs to see if you want to resolve some of them"
}

if ($WarningLogging -and $WarningStatus)
{
	Write-Output ""
	Write-Warning -Message "Warnings were generated and saved to: $("$ProjectRoot\Logs")"
}

if ($ErrorStatus)
{
	Write-Information -Tags "User" -MessageData "INFO: Not all operations completed successfully"
}
else
{
	Write-Information -Tags "User" -MessageData "INFO: All operations completed successfully!"
}

Write-Output ""

# Clear warning/error status
Set-Variable -Name ErrorStatus -Scope Global -Value $false
Set-Variable -Name WarningStatus -Scope Global -Value $false

Update-Log
