
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

<#PSScriptInfo

.VERSION 0.15.0

.GUID d7809432-c822-4699-9244-97c8da8d64bf

.AUTHOR metablaster zebal@protonmail.com

.REQUIREDSCRIPTS ProjectSettings.ps1

.EXTERNALMODULEDEPENDENCIES Ruleset.Logging, Ruleset.Initialize, Ruleset.Utility
#>

<#
.SYNOPSIS
Deploy firewall rules and configuration to local or remote computer.

.DESCRIPTION
Deploy-Firewall.ps1 is a master script to deploy rules and configuration to local and/or multiple
remote computers.
In addition to deployment of rules and setting, target GPO firewall is configured, desktop shortcut
to management console is set and optionally custom firewall log location is set.

.PARAMETER Domain
Specify computer name onto which to deploy firewall.
The default value is this machine (localhost)

.PARAMETER Interactive
If any program installation directory is not found, Deploy-Firewall will ask
user to optionally specify program installation location.

.PARAMETER Quiet
If specified, it suppresses warning, error and informationall messages if user specified or
default program path does not exist or if it's of an invalid syntax needed for firewall.

.PARAMETER Force
If specified, firewall deployment is automated and no prompt to choose
rulesets to load is shown.
By default a user is present with a series of questions to fine tune deployment.
To avoid all prompts completely combine this switch with -Confirm:$false

.EXAMPLE
PS> Deploy-Firewall

.EXAMPLE
PS> Deploy-Firewall -Interactive

.EXAMPLE
PS> Deploy-Firewall -Domain Server01 -Quiet

.EXAMPLE
PS> Deploy-Firewall -Force -Confirm:$false

.INPUTS
None. You cannot pipe objects to Deploy-Firewall.ps1

.OUTPUTS
None. Deploy-Firewall.ps1 does not generate any output

.NOTES
TODO: Rule deployment should probably be separated into new script
TODO: Setting a network profile should probably be handled before rules are deployed
so that correct rules for network discovery and sharing are enabled.

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Scripts/README.md
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding(PositionalBinding = $false, SupportsShouldProcess = $true)]
[OutputType([void])]
param (
	[Parameter(Position = 0)]
	[Alias("ComputerName", "CN")]
	[string] $Domain = [System.Environment]::MachineName,

	[Parameter()]
	[switch] $Interactive,

	[Parameter()]
	[switch] $Quiet,

	[Parameter()]
	[switch] $Force
)

#region Initialization
& $PSScriptRoot\Unblock-Project.ps1
. $PSScriptRoot\..\Config\ProjectSettings.ps1 $PSCmdlet -Domain $Domain
Write-Debug -Message "[$ThisScript] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"
Initialize-Project

# User prompt
$ExecuteParams = @{
	Accept = "Deploy firewall to '$Domain' computer"
	Deny = "Abort firewall deployment operation"
	Force = $Force
}

if (!(Approve-Execute @ExecuteParams)) { exit }
Write-Information -Tags $ThisScript -MessageData "INFO: Initializing deployment..."

# Save the state of global variables
$PreviousProjectCheck = (Get-Variable -Name ProjectCheck -Scope Global).Value
$PreviousUpdateGPO = (Get-Variable -Name UpdateGPO -Scope Global).Value
# TODO: These 2 variables should probably not be saved since only this script makes use of them
$PreviousErrorStatus = (Get-Variable -Name ErrorStatus -Scope Global).Value
$PreviousWarningStatus = (Get-Variable -Name WarningStatus -Scope Global).Value

# Skip checking requirements for all subsequent operations
Set-Variable -Name ProjectCheck -Scope Global -Option ReadOnly -Force -Value $false

# Clear errors, error and warning status, disable auto GPO update
$Error.Clear()
Set-Variable -Name ErrorStatus -Scope Global -Value $false
Set-Variable -Name WarningStatus -Scope Global -Value $false
Set-Variable -Name UpdateGPO -Scope Global -Value $false

# Set -Confirm parameter
$GrantLogsParams = @{
	User = $DefaultUser
	Force = $Force
}
$SetShortCutParams = @{
}
$SetScreenBufferParams = @{
}
if ($PSBoundParameters.ContainsKey("Confirm"))
{
	$SetScreenBufferParams["Confirm"] = $PSBoundParameters["Confirm"]
	$GrantLogsParams["Confirm"] = $PSBoundParameters["Confirm"]
	$SetShortCutParams["Confirm"] = $PSBoundParameters["Confirm"]
}

# Prompt to set screen buffer to recommended value
# TODO: It will ask again in same session, seems like set size is not set or Set-ScreenBuffer doesn't work
Set-ScreenBuffer 3000 @SetScreenBufferParams

# Check all rules which apply to windows services
Write-ServiceList $ProjectRoot\Rules -Log | ForEach-Object {
	Test-Service $_ -Session $SessionInstance | Out-Null
}

Update-Log
#endregion

#
# Deploy Inbound IPv4 rules
# NOTE: the order of scripts is the same as it is shown in file explorer of Visual Studio Code
#
$Destination = "$ProjectRoot\Rules\IPv4\Inbound"

# User prompt
[bool] $YesToAll = $Force
[bool] $NoToAll = $false
[bool] $AllCurrent = $YesToAll
[bool] $NoCurrent = $false

# Parameters which apply to a subset of rules scripts, that support them
$ScriptParams = @{
	Quiet = $Quiet
	Interactive = $Interactive
}
# Parameters which apply to all rule scripts
$AllScriptParams = @{
	Domain = $Domain
	Force = $AllCurrent
}

$ExecuteParams["Accept"] = "Continue prompting which inbound IPv4 rules to deploy"
$ExecuteParams["Deny"] = "Skip all inbound IPv4 rules"
$ExecuteParams["Title"] = "Selecting inbound IPv4 rules"
$ExecuteParams["Question"] = "Do you want to deploy these rules?"
$ExecuteParams["Context"] = "IPv4\Inbound"
$ExecuteParams["YesToAll"] = ([ref] $YesToAll)
$ExecuteParams["NoToAll"] = ([ref] $NoToAll)
$ExecuteParams["YesAllHelp"] = "Deploy all inbound IPv4 rules"
$ExecuteParams["NoAllHelp"] = "Abort deploying rules and finish deployment"

if (Approve-Execute @ExecuteParams)
{
	# Update user prompt
	$AllCurrent = $YesToAll
	$ExecuteParams["Accept"] = "Continue prompting which core rules to deploy"
	$ExecuteParams["Deny"] = "Skip all core rules"
	$ExecuteParams["Title"] = "Selecting core rules"
	$ExecuteParams["YesToAll"] = ([ref] $AllCurrent)
	$ExecuteParams["NoToAll"] = ([ref] $NoCurrent)
	$ExecuteParams["YesAllHelp"] = "Deploy all core rules"
	$ExecuteParams["NoAllHelp"] = "Skip all subsequent inbound IPv4 rules"

	if (Approve-Execute @ExecuteParams)
	{
		# Core rules
		$AllScriptParams["Force"] = $AllCurrent
		& "$Destination\AdditionalNetworking.ps1" -Quiet:$Quiet @AllScriptParams
		& "$Destination\Broadcast.ps1" @AllScriptParams
		& "$Destination\CoreNetworking.ps1" @AllScriptParams
		& "$Destination\ICMP.ps1" @AllScriptParams
		& "$Destination\Multicast.ps1" @AllScriptParams
		& "$Destination\NetworkDiscovery.ps1" @AllScriptParams
		& "$Destination\NetworkSharing.ps1" @AllScriptParams
		& "$Destination\RemoteWindows.ps1" -Quiet:$Quiet @AllScriptParams
		& "$Destination\StoreApps.ps1" @AllScriptParams
		& "$Destination\Temporary.ps1" @AllScriptParams
		& "$Destination\WindowsServices.ps1" @AllScriptParams
		& "$Destination\WirelessNetworking.ps1" -Quiet:$Quiet @AllScriptParams
		$AllCurrent = $YesToAll
	}

	# Update user prompt
	$ExecuteParams["Accept"] = "Continue prompting which rules for 3rd party development software to deploy"
	$ExecuteParams["Deny"] = "Skip all rules for 3rd party development software"
	$ExecuteParams["Title"] = "Selecting rules for 3rd party development software"
	$ExecuteParams["YesToAll"] = ([ref] $AllCurrent)
	$ExecuteParams["NoToAll"] = ([ref] $NoCurrent)
	$ExecuteParams["YesAllHelp"] = "Deploy all rules for 3rd party development software"

	if (Approve-Execute @ExecuteParams)
	{
		# Rules for 3rd party development software
		$AllScriptParams["Force"] = $AllCurrent
		& "$Destination\Development\EpicGames.ps1" @ScriptParams @AllScriptParams
		$AllCurrent = $YesToAll
	}

	# Update user prompt
	$ExecuteParams["Accept"] = "Continue prompting which rules for games to deploy"
	$ExecuteParams["Deny"] = "Skip all rules for games"
	$ExecuteParams["Title"] = "Selecting rules for games"
	$ExecuteParams["Unsafe"] = $true
	$ExecuteParams["YesToAll"] = ([ref] $AllCurrent)
	$ExecuteParams["NoToAll"] = ([ref] $NoCurrent)
	$ExecuteParams["YesAllHelp"] = "Deploy all rules for games"

	if (Approve-Execute @ExecuteParams)
	{
		# Rules for games
		# $AllScriptParams["Force"] = $AllCurrent
		# & "$Destination\Games\ScriptName.ps1" @AllScriptParams
		$AllCurrent = $YesToAll

		Write-Warning -Message "[$ThisScript] No inbound rules for games exist"
	}

	# Update user prompt
	$ExecuteParams["Accept"] = "Continue prompting which rules for servers to deploy"
	$ExecuteParams["Deny"] = "Skip all rules for servers"
	$ExecuteParams["Title"] = "Selecting rules for servers"
	$ExecuteParams["YesToAll"] = ([ref] $AllCurrent)
	$ExecuteParams["NoToAll"] = ([ref] $NoCurrent)
	$ExecuteParams["YesAllHelp"] = "Deploy all rules for servers"

	if (Approve-Execute @ExecuteParams)
	{
		# Rules for servers
		$AllScriptParams["Force"] = $AllCurrent
		& "$Destination\Server\SshServer.ps1" @ScriptParams @AllScriptParams
		$AllCurrent = $YesToAll

		Write-Warning -Message "[$ThisScript] No inbound rules for server platforms or software exist"
	}

	# Update user prompt
	$ExecuteParams["Accept"] = "Continue prompting which rules for 3rd party software to deploy"
	$ExecuteParams["Deny"] = "Skip all rules for 3rd party software"
	$ExecuteParams["Title"] = "Selecting rules for 3rd party software"
	$ExecuteParams.Remove("Unsafe")
	$ExecuteParams["YesToAll"] = ([ref] $AllCurrent)
	$ExecuteParams["NoToAll"] = ([ref] $NoCurrent)
	$ExecuteParams["YesAllHelp"] = "Deploy all rules for 3rd party software"

	if (Approve-Execute @ExecuteParams)
	{
		# Rules for 3rd party software
		$AllScriptParams["Force"] = $AllCurrent
		& "$Destination\Software\FileZilla.ps1" @ScriptParams @AllScriptParams
		& "$Destination\Software\InternetBrowser.ps1" @ScriptParams @AllScriptParams
		& "$Destination\Software\Steam.ps1" @ScriptParams @AllScriptParams
		& "$Destination\Software\TeamViewer.ps1" @ScriptParams @AllScriptParams
		& "$Destination\Software\uTorrent.ps1" @ScriptParams @AllScriptParams
		$AllCurrent = $YesToAll
	}

	# Update user prompt
	$ExecuteParams["Accept"] = "Continue prompting which rules for Microsoft software to deploy"
	$ExecuteParams["Deny"] = "Skip all rules for Microsoft software"
	$ExecuteParams["Title"] = "Selecting rules for Microsoft software"
	$ExecuteParams["YesToAll"] = ([ref] $AllCurrent)
	$ExecuteParams["NoToAll"] = ([ref] $NoCurrent)
	$ExecuteParams["YesAllHelp"] = "Deploy all rules for Microsoft software"

	if (Approve-Execute @ExecuteParams)
	{
		# Rules for Microsoft software
		$AllScriptParams["Force"] = $AllCurrent
		& "$Destination\Software\Microsoft\MicrosoftOffice.ps1" @ScriptParams @AllScriptParams
		& "$Destination\Software\Microsoft\SysInternals.ps1" @ScriptParams @AllScriptParams
		$AllCurrent = $YesToAll
	}
}

#
# Deploy Outbound IPv4 rules
#
$Destination = "$ProjectRoot\Rules\IPv4\Outbound"

# Update user prompt
$YesToAll = $Force
$NoCurrent = $false

$ExecuteParams["Accept"] = "Continue prompting which outbound IPv4 rules to deploy"
$ExecuteParams["Deny"] = "Skip all outbound IPv4 rules"
$ExecuteParams["Title"] = "Selecting outbound IPv4 rules"
$ExecuteParams["Context"] = "IPv4\Outbound"
$ExecuteParams["YesToAll"] = ([ref] $YesToAll)
$ExecuteParams["NoToAll"] = ([ref] $NoToAll)
$ExecuteParams["YesAllHelp"] = "Deploy all outbound IPv4 rules"
$ExecuteParams["NoAllHelp"] = "Abort deploying any subsequent rules and finish deployment"

if (Approve-Execute @ExecuteParams)
{
	# Update user prompt
	$AllCurrent = $YesToAll
	$ExecuteParams["Accept"] = "Continue prompting which core rules to deploy"
	$ExecuteParams["Deny"] = "Skip all core rules"
	$ExecuteParams["Title"] = "Selecting core rules"
	$ExecuteParams["YesToAll"] = ([ref] $AllCurrent)
	$ExecuteParams["NoToAll"] = ([ref] $NoCurrent)
	$ExecuteParams["YesAllHelp"] = "Deploy all core rules"
	$ExecuteParams["NoAllHelp"] = "Skip all subsequent outbound IPv4 rules"

	if (Approve-Execute @ExecuteParams)
	{
		# Core rules
		$AllScriptParams["Force"] = $AllCurrent
		& "$Destination\AdditionalNetworking.ps1" -Quiet:$Quiet @AllScriptParams
		& "$Destination\Broadcast.ps1" @AllScriptParams
		& "$Destination\CoreNetworking.ps1" @AllScriptParams
		& "$Destination\ICMP.ps1" @AllScriptParams
		& "$Destination\Multicast.ps1" @AllScriptParams
		& "$Destination\NetworkDiscovery.ps1" @AllScriptParams
		& "$Destination\NetworkSharing.ps1" @AllScriptParams
		& "$Destination\RemoteWindows.ps1" -Quiet:$Quiet @AllScriptParams
		& "$Destination\StoreApps.ps1" -Quiet:$Quiet @AllScriptParams
		& "$Destination\Temporary.ps1" @AllScriptParams
		& "$Destination\WindowsServices.ps1" @AllScriptParams
		& "$Destination\WindowsSystem.ps1" @ScriptParams @AllScriptParams
		& "$Destination\WirelessNetworking.ps1" -Quiet:$Quiet @AllScriptParams
		$AllCurrent = $YesToAll
	}

	# Update user prompt
	$ExecuteParams["Accept"] = "Continue prompting which rules for 3rd party development software to deploy"
	$ExecuteParams["Deny"] = "Skip all rules for 3rd party development software"
	$ExecuteParams["Title"] = "Selecting rules for 3rd party development software"
	$ExecuteParams["YesToAll"] = ([ref] $AllCurrent)
	$ExecuteParams["NoToAll"] = ([ref] $NoCurrent)
	$ExecuteParams["YesAllHelp"] = "Deploy all rules for 3rd party development software"

	if (Approve-Execute @ExecuteParams)
	{
		# Rules for 3rd party development software
		$AllScriptParams["Force"] = $AllCurrent
		& "$Destination\Development\Chocolatey.ps1" @ScriptParams @AllScriptParams
		& "$Destination\Development\CMake.ps1" @ScriptParams @AllScriptParams
		& "$Destination\Development\EpicGames.ps1" @ScriptParams @AllScriptParams
		& "$Destination\Development\GitHub.ps1" @ScriptParams @AllScriptParams
		& "$Destination\Development\Incredibuild.ps1" @ScriptParams @AllScriptParams
		& "$Destination\Development\MSYS2.ps1" @ScriptParams @AllScriptParams
		& "$Destination\Development\RealWorld.ps1" @ScriptParams @AllScriptParams
		$AllCurrent = $YesToAll
	}

	# Update user prompt
	$ExecuteParams["Accept"] = "Continue prompting which rules for Microsoft development software to deploy"
	$ExecuteParams["Deny"] = "Skip all rules for Microsoft development software"
	$ExecuteParams["Title"] = "Selecting rules for Microsoft development software"
	$ExecuteParams["YesToAll"] = ([ref] $AllCurrent)
	$ExecuteParams["NoToAll"] = ([ref] $NoCurrent)
	$ExecuteParams["YesAllHelp"] = "Deploy all rules for Microsoft development software"

	if (Approve-Execute @ExecuteParams)
	{
		# Rules for Microsoft development software
		$AllScriptParams["Force"] = $AllCurrent
		& "$Destination\Development\Microsoft\dotnet.ps1" @ScriptParams @AllScriptParams
		& "$Destination\Development\Microsoft\HelpViewer.ps1" @ScriptParams @AllScriptParams
		& "$Destination\Development\Microsoft\NuGet.ps1" @ScriptParams @AllScriptParams
		& "$Destination\Development\Microsoft\PowerShell.ps1" @ScriptParams @AllScriptParams
		& "$Destination\Development\Microsoft\vcpkg.ps1" @ScriptParams @AllScriptParams
		& "$Destination\Development\Microsoft\VisualStudio.ps1" @ScriptParams @AllScriptParams
		& "$Destination\Development\Microsoft\VSCode.ps1" @ScriptParams @AllScriptParams
		& "$Destination\Development\Microsoft\WebPlatform.ps1" @ScriptParams @AllScriptParams
		& "$Destination\Development\Microsoft\WindowsSDK.ps1" @ScriptParams @AllScriptParams
		$AllCurrent = $YesToAll
	}

	# Update user prompt
	$ExecuteParams["Accept"] = "Continue prompting which rules for games to deploy"
	$ExecuteParams["Deny"] = "Skip all rules for games"
	$ExecuteParams["Title"] = "Selecting rules for games"
	$ExecuteParams["YesToAll"] = ([ref] $AllCurrent)
	$ExecuteParams["NoToAll"] = ([ref] $NoCurrent)
	$ExecuteParams["YesAllHelp"] = "Deploy all rules for games"

	if (Approve-Execute @ExecuteParams)
	{
		# Rules for games
		$AllScriptParams["Force"] = $AllCurrent
		& "$Destination\Games\ArenaChess.ps1" @ScriptParams @AllScriptParams
		& "$Destination\Games\CounterStrikeGO.ps1" @ScriptParams @AllScriptParams
		& "$Destination\Games\DemiseOfNations.ps1" @ScriptParams @AllScriptParams
		& "$Destination\Games\EVEOnline.ps1" @ScriptParams @AllScriptParams
		& "$Destination\Games\LeagueOfLegends.ps1" @ScriptParams @AllScriptParams
		& "$Destination\Games\OpenTTD.ps1" @ScriptParams @AllScriptParams
		& "$Destination\Games\PathOfExile.ps1" @ScriptParams @AllScriptParams
		& "$Destination\Games\PinballArcade.ps1" @ScriptParams @AllScriptParams
		& "$Destination\Games\PokerStars.ps1" @ScriptParams @AllScriptParams
		& "$Destination\Games\WarThunder.ps1" @ScriptParams @AllScriptParams
		$AllCurrent = $YesToAll
	}

	# Update user prompt
	$ExecuteParams["Accept"] = "Continue prompting which rules for servers to deploy"
	$ExecuteParams["Deny"] = "Skip all rules for servers"
	$ExecuteParams["Title"] = "Selecting rules for servers"
	$ExecuteParams["YesToAll"] = ([ref] $AllCurrent)
	$ExecuteParams["NoToAll"] = ([ref] $NoCurrent)
	$ExecuteParams["YesAllHelp"] = "Deploy all rules for servers"

	if (Approve-Execute @ExecuteParams)
	{
		# Rules for servers
		$AllScriptParams["Force"] = $AllCurrent
		& "$Destination\Server\SQLServer.ps1" @ScriptParams @AllScriptParams
		$AllCurrent = $YesToAll
	}

	# Update user prompt
	$ExecuteParams["Accept"] = "Continue prompting which rules for 3rd party software to deploy"
	$ExecuteParams["Deny"] = "Skip all rules for 3rd party software"
	$ExecuteParams["Title"] = "Selecting rules for 3rd party software"
	$ExecuteParams["YesToAll"] = ([ref] $AllCurrent)
	$ExecuteParams["NoToAll"] = ([ref] $NoCurrent)
	$ExecuteParams["YesAllHelp"] = "Deploy all rules for 3rd party software"

	if (Approve-Execute @ExecuteParams)
	{
		# Rules for 3rd party programs
		$AllScriptParams["Force"] = $AllCurrent
		& "$Destination\Software\Adobe.ps1" @ScriptParams @AllScriptParams
		& "$Destination\Software\CPUID.ps1" @ScriptParams @AllScriptParams
		& "$Destination\Software\DnsCrypt.ps1" @ScriptParams @AllScriptParams
		& "$Destination\Software\FileZilla.ps1" @ScriptParams @AllScriptParams
		& "$Destination\Software\Google.ps1" @ScriptParams @AllScriptParams
		& "$Destination\Software\GPG.ps1" @ScriptParams @AllScriptParams
		& "$Destination\Software\Greenshot.ps1" @ScriptParams @AllScriptParams
		& "$Destination\Software\Intel.ps1" @ScriptParams @AllScriptParams
		& "$Destination\Software\InternetBrowser.ps1" @ScriptParams @AllScriptParams
		& "$Destination\Software\Java.ps1" @ScriptParams @AllScriptParams
		& "$Destination\Software\MetaTrader.ps1" @ScriptParams @AllScriptParams
		& "$Destination\Software\MSI.ps1" @ScriptParams @AllScriptParams
		& "$Destination\Software\Nvidia.ps1" @ScriptParams @AllScriptParams
		& "$Destination\Software\OBSStudio.ps1" @ScriptParams @AllScriptParams
		& "$Destination\Software\OpenSpace.ps1" @ScriptParams @AllScriptParams
		& "$Destination\Software\OpenSSH.ps1" @ScriptParams @AllScriptParams
		& "$Destination\Software\PasswordSafe.ps1" @ScriptParams @AllScriptParams
		& "$Destination\Software\Psiphon.ps1" @ScriptParams @AllScriptParams
		& "$Destination\Software\qBittorrent.ps1" @ScriptParams @AllScriptParams
		& "$Destination\Software\RivaTuner.ps1" @ScriptParams @AllScriptParams
		& "$Destination\Software\Steam.ps1" @ScriptParams @AllScriptParams
		& "$Destination\Software\TeamViewer.ps1" @ScriptParams @AllScriptParams
		& "$Destination\Software\Thunderbird.ps1" @ScriptParams @AllScriptParams
		& "$Destination\Software\uTorrent.ps1" @ScriptParams @AllScriptParams
		$AllCurrent = $YesToAll
	}

	# Update user prompt
	$ExecuteParams["Accept"] = "Continue prompting which rules for Microsoft software to deploy"
	$ExecuteParams["Deny"] = "Skip all rules for Microsoft software"
	$ExecuteParams["Title"] = "Selecting rules for Microsoft software"
	$ExecuteParams["YesToAll"] = ([ref] $AllCurrent)
	$ExecuteParams["NoToAll"] = ([ref] $NoCurrent)
	$ExecuteParams["YesAllHelp"] = "Deploy all rules for Microsoft software"

	if (Approve-Execute @ExecuteParams)
	{
		# Rules for Microsoft programs
		$AllScriptParams["Force"] = $AllCurrent
		& "$Destination\Software\Microsoft\BingWallpaper.ps1" @ScriptParams @AllScriptParams
		& "$Destination\Software\Microsoft\EdgeChromium.ps1" @ScriptParams @AllScriptParams
		& "$Destination\Software\Microsoft\MicrosoftOffice.ps1" @ScriptParams @AllScriptParams
		& "$Destination\Software\Microsoft\OneDrive.ps1" @ScriptParams @AllScriptParams
		& "$Destination\Software\Microsoft\SysInternals.ps1" @ScriptParams @AllScriptParams
		$AllCurrent = $YesToAll
	}
}

#
# Deploy Inbound IPv6 rules
#
$Destination = "$ProjectRoot\Rules\IPv6\Inbound"

# Update user prompt
$YesToAll = $Force
$NoCurrent = $false

$ExecuteParams["Accept"] = "Continue prompting which inbound IPv6 rules to deploy"
$ExecuteParams["Deny"] = "Skip all inbound IPv6 rules"
$ExecuteParams["Title"] = "Selecting inbound IPv6 rules"
$ExecuteParams["Context"] = "IPv6\Inbound"
$ExecuteParams["YesToAll"] = ([ref] $YesToAll)
$ExecuteParams["NoToAll"] = ([ref] $NoToAll)
$ExecuteParams["YesAllHelp"] = "Deploy all inbound IPv6 rules"
$ExecuteParams["NoAllHelp"] = "Abort deploying any subsequent rules and finish deployment"

if (Approve-Execute @ExecuteParams)
{
	# Update user prompt
	$AllCurrent = $YesToAll
	$ExecuteParams["Accept"] = "Continue prompting which core rules to deploy"
	$ExecuteParams["Deny"] = "Skip all core rules"
	$ExecuteParams["Title"] = "Selecting core rules"
	$ExecuteParams["YesToAll"] = ([ref] $AllCurrent)
	$ExecuteParams["NoToAll"] = ([ref] $NoCurrent)
	$ExecuteParams["YesAllHelp"] = "Deploy all core rules"
	$ExecuteParams["NoAllHelp"] = "Skip all subsequent inbound IPv6 rules"

	if (Approve-Execute @ExecuteParams)
	{
		# Core rules
		$AllScriptParams["Force"] = $AllCurrent
		& "$Destination\CoreNetworking.ps1" @AllScriptParams
		& "$Destination\ICMP.ps1" @AllScriptParams
		& "$Destination\Multicast.ps1" @AllScriptParams
		& "$Destination\Temporary.ps1" @AllScriptParams
		$AllCurrent = $YesToAll
	}
}

#
# Deploy Outbound IPv6 rules
#
$Destination = "$ProjectRoot\Rules\IPv6\Outbound"

# Update user prompt
$YesToAll = $Force
$NoCurrent = $false

$ExecuteParams["Accept"] = "Continue prompting which outbound IPv6 rules to deploy"
$ExecuteParams["Deny"] = "Skip all outbound IPv6 rules"
$ExecuteParams["Title"] = "Selecting outbound IPv6 rules"
$ExecuteParams["Context"] = "IPv6\Outbound"
$ExecuteParams["YesToAll"] = ([ref] $YesToAll)
$ExecuteParams["NoToAll"] = ([ref] $NoToAll)
$ExecuteParams["YesAllHelp"] = "Deploy all outbound IPv6 rules"
$ExecuteParams["NoAllHelp"] = "Abort deploying any subsequent rules and finish deployment"

if (Approve-Execute @ExecuteParams)
{
	# Update user prompt
	$AllCurrent = $YesToAll
	$ExecuteParams["Accept"] = "Continue prompting which core rules to deploy"
	$ExecuteParams["Deny"] = "Skip all core rules"
	$ExecuteParams["Title"] = "Selecting core rules"
	$ExecuteParams["YesToAll"] = ([ref] $AllCurrent)
	$ExecuteParams["NoToAll"] = ([ref] $NoCurrent)
	$ExecuteParams["YesAllHelp"] = "Deploy all core rules"
	$ExecuteParams["NoAllHelp"] = "Skip all subsequent outbound IPv6 rules"

	if (Approve-Execute @ExecuteParams)
	{
		# Core rules
		$AllScriptParams["Force"] = $AllCurrent
		& "$Destination\CoreNetworking.ps1" @AllScriptParams
		& "$Destination\ICMP.ps1" @AllScriptParams
		& "$Destination\Multicast.ps1" @AllScriptParams
		& "$Destination\Temporary.ps1" @AllScriptParams
		$AllCurrent = $YesToAll
	}
}

Write-Information -Tags $ThisScript -MessageData "INFO: Deployment of firewall rules is complete"

# TODO: This is a temporary measure because currently we change log file location only while debugging
# NOTE: It safest to be called before Log location is changed to detect location change and prompt for restart
# TODO: Granting logs remotely not implemented, also using custom log location outside repository not implemented
if ($Develop -and ($Domain -eq [System.Environment]::MachineName))
{
	# Verify permissions to write firewall logs if needed
	& "$ProjectRoot\Scripts\Grant-Logs.ps1" @GrantLogsParams
}

# Signal GPO update and disconnect to be done in Complete-Firewall.ps1
Set-Variable -Name UpdateGPO -Scope Global -Value $PreviousUpdateGPO

# Set up global firewall setting, network and firewall profile and apply GPO changes
& "$ProjectRoot\Scripts\Complete-Firewall.ps1" -Force:$Force -Domain $Domain

# HACK: Is it possible to have remote management console? and if so set shortcut locally to remote console
# TODO: Setting shortcut remotely not implemented
if ($Domain -eq [System.Environment]::MachineName)
{
	# Remove shortcut from previous versions
	$PublicDesktop = [System.Environment]::ExpandEnvironmentVariables("%Public%\Desktop")
	Get-ChildItem -Path $PublicDesktop -File | Where-Object {
		$_.Name -match "^Firewall\s?((\d+|\.){2,3})?\.lnk$"
	} | Remove-Item

	# Set new desktop shortcut to custom management console
	Set-Shortcut -Name "Firewall $ProjectVersion.lnk" -Path "AllUsersDesktop" -Admin `
		-TargetPath "$ProjectRoot\Config\System\Firewall.msc" `
		-Description "View and modify GPO firewall" -IconIndex -19 `
		-IconLocation "$env:SystemDrive\Windows\System32\Shell32.dll" @SetShortCutParams
}

# Show execution status
if ($ErrorStatus)
{
	if ($ErrorLogging)
	{
		# HACK: Will print when no errors were reported to console
		Write-Information -MessageData "" -InformationVariable ThrowAway
		Write-Warning -Message "[$ThisScript] Errors were generated and saved to: $("$ProjectRoot\Logs")"
		Write-Information -Tags $ThisScript -MessageData "INFO: You can review these logs to see if you want to resolve some of them"
	}

	Write-Warning -Message "[$ThisScript] Not all operations completed successfully"
}
else
{
	Write-Information -Tags $ThisScript -MessageData "INFO: All operations completed successfully"
}

Write-Information -MessageData "" -InformationVariable ThrowAway

# Restore changed variables status
Set-Variable -Name ErrorStatus -Scope Global -Value $PreviousErrorStatus
Set-Variable -Name WarningStatus -Scope Global -Value $PreviousWarningStatus
Set-Variable -Name ProjectCheck -Scope Global -Force -Value $PreviousProjectCheck

Update-Log
