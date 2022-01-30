
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

.VERSION 0.12.0

.GUID d7809432-c822-4699-9244-97c8da8d64bf

.AUTHOR metablaster zebal@protonmail.com
#>

<#
.SYNOPSIS
Deploy firewall rules and configuration to local or remote computer.

.DESCRIPTION
Deploy-Firewall.ps1 is a master script to deploy rules and configuration to local and/or multiple
remote computers.
In addition to deployment of rules, target GPO firewall is configured, desktop shortcut to
management console is set and optionally custom firewall log location is set.

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
By default the user is present with a series of questions to fine tune deployment.
To avoid all prompts completely combine this switch with -Confirm:$false

.EXAMPLE
PS> .\Deploy-Firewall.ps1

.EXAMPLE
PS> .\Deploy-Firewall.ps1 -Force

.INPUTS
None. You cannot pipe objects to Deploy-Firewall.ps1

.OUTPUTS
None. Deploy-Firewall.ps1 does not generate any output

.NOTES
TODO: Rule deployment should probably be separated into new script

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/tree/master/Scripts
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
Initialize-Project -Strict

# User prompt
$ExecuteParams = @{
	Accept = "Deploy firewall to '$PolicyStore' computer"
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
	Force = $Force
}
$SetShortCutParams = @{
}
$SetScreenBufferParams = @{
}
if ($PSBoundParameters.ContainsKey("Confirm"))
{
	$SetScreenBufferParams.Confirm = $PSBoundParameters["Confirm"]
	$GrantLogsParams.Confirm = $PSBoundParameters["Confirm"]
	$SetShortCutParams.Confirm = $PSBoundParameters["Confirm"]
}

# Prompt to set screen buffer to recommended value
Set-ScreenBuffer 3000 @SetScreenBufferParams

# Check all rules which apply to windows services
Build-ServiceList $ProjectRoot\Rules -Log | Test-Service | Out-Null
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

$ScriptParams = @{
	Quiet = $Quiet
	Interactive = $Interactive
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
		& "$Destination\AdditionalNetworking.ps1" -Force:$AllCurrent @ScriptParams
		& "$Destination\Broadcast.ps1" -Force:$AllCurrent
		& "$Destination\CoreNetworking.ps1" -Force:$AllCurrent
		& "$Destination\ICMP.ps1" -Force:$AllCurrent
		& "$Destination\Multicast.ps1" -Force:$AllCurrent
		& "$Destination\NetworkDiscovery.ps1" -Force:$AllCurrent
		& "$Destination\NetworkSharing.ps1" -Force:$AllCurrent
		& "$Destination\RemoteWindows.ps1" -Force:$AllCurrent
		& "$Destination\StoreApps.ps1" -Force:$AllCurrent
		& "$Destination\Temporary.ps1" -Force:$AllCurrent
		& "$Destination\WindowsServices.ps1" -Force:$AllCurrent
		& "$Destination\WirelessNetworking.ps1" -Force:$AllCurrent
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
		& "$Destination\Development\EpicGames.ps1" -Force:$AllCurrent @ScriptParams
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
		# & "$Destination\Games\ScriptName.ps1" -Force:$AllCurrent
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
		& "$Destination\Server\SshServer.ps1" -Force:$AllCurrent @ScriptParams
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
		& "$Destination\Software\FileZilla.ps1" -Force:$AllCurrent @ScriptParams
		& "$Destination\Software\InternetBrowser.ps1" -Force:$AllCurrent @ScriptParams
		& "$Destination\Software\Steam.ps1" -Force:$AllCurrent @ScriptParams
		& "$Destination\Software\TeamViewer.ps1" -Force:$AllCurrent @ScriptParams
		& "$Destination\Software\uTorrent.ps1" -Force:$AllCurrent @ScriptParams
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
		& "$Destination\Software\Microsoft\MicrosoftOffice.ps1" -Force:$AllCurrent @ScriptParams
		& "$Destination\Software\Microsoft\SysInternals.ps1" -Force:$AllCurrent @ScriptParams
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
		& "$Destination\AdditionalNetworking.ps1" -Force:$AllCurrent @ScriptParams
		& "$Destination\Broadcast.ps1" -Force:$AllCurrent
		& "$Destination\CoreNetworking.ps1" -Force:$AllCurrent
		& "$Destination\ICMP.ps1" -Force:$AllCurrent
		& "$Destination\Multicast.ps1" -Force:$AllCurrent
		& "$Destination\NetworkDiscovery.ps1" -Force:$AllCurrent
		& "$Destination\NetworkSharing.ps1" -Force:$AllCurrent
		& "$Destination\RemoteWindows.ps1" -Force:$AllCurrent
		& "$Destination\StoreApps.ps1" -Force:$AllCurrent
		& "$Destination\Temporary.ps1" -Force:$AllCurrent
		& "$Destination\WindowsServices.ps1" -Force:$AllCurrent
		& "$Destination\WindowsSystem.ps1" -Force:$AllCurrent @ScriptParams
		& "$Destination\WirelessNetworking.ps1" -Force:$AllCurrent
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
		& "$Destination\Development\Chocolatey.ps1" -Force:$AllCurrent @ScriptParams
		& "$Destination\Development\CMake.ps1" -Force:$AllCurrent @ScriptParams
		& "$Destination\Development\EpicGames.ps1" -Force:$AllCurrent @ScriptParams
		& "$Destination\Development\GitHub.ps1" -Force:$AllCurrent @ScriptParams
		& "$Destination\Development\Incredibuild.ps1" -Force:$AllCurrent @ScriptParams
		& "$Destination\Development\MSYS2.ps1" -Force:$AllCurrent @ScriptParams
		& "$Destination\Development\RealWorld.ps1" -Force:$AllCurrent @ScriptParams
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
		& "$Destination\Development\Microsoft\dotnet.ps1" -Force:$AllCurrent @ScriptParams
		& "$Destination\Development\Microsoft\HelpViewer.ps1" -Force:$AllCurrent @ScriptParams
		& "$Destination\Development\Microsoft\NuGet.ps1" -Force:$AllCurrent @ScriptParams
		& "$Destination\Development\Microsoft\PowerShell.ps1" -Force:$AllCurrent @ScriptParams
		& "$Destination\Development\Microsoft\vcpkg.ps1" -Force:$AllCurrent @ScriptParams
		& "$Destination\Development\Microsoft\VisualStudio.ps1" -Force:$AllCurrent @ScriptParams
		& "$Destination\Development\Microsoft\VSCode.ps1" -Force:$AllCurrent @ScriptParams
		& "$Destination\Development\Microsoft\WebPlatform.ps1" -Force:$AllCurrent @ScriptParams
		& "$Destination\Development\Microsoft\WindowsSDK.ps1" -Force:$AllCurrent @ScriptParams
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
		& "$Destination\Games\ArenaChess.ps1" -Force:$AllCurrent @ScriptParams
		& "$Destination\Games\CounterStrikeGO.ps1" -Force:$AllCurrent @ScriptParams
		& "$Destination\Games\DemiseOfNations.ps1" -Force:$AllCurrent @ScriptParams
		& "$Destination\Games\EVEOnline.ps1" -Force:$AllCurrent @ScriptParams
		& "$Destination\Games\LeagueOfLegends.ps1" -Force:$AllCurrent @ScriptParams
		& "$Destination\Games\OpenTTD.ps1" -Force:$AllCurrent @ScriptParams
		& "$Destination\Games\PathOfExile.ps1" -Force:$AllCurrent @ScriptParams
		& "$Destination\Games\PinballArcade.ps1" -Force:$AllCurrent @ScriptParams
		& "$Destination\Games\PokerStars.ps1" -Force:$AllCurrent @ScriptParams
		& "$Destination\Games\WarThunder.ps1" -Force:$AllCurrent @ScriptParams
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
		& "$Destination\Server\SQLServer.ps1" -Force:$AllCurrent @ScriptParams
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
		& "$Destination\Software\Adobe.ps1" -Force:$AllCurrent @ScriptParams
		& "$Destination\Software\CPUID.ps1" -Force:$AllCurrent @ScriptParams
		& "$Destination\Software\DnsCrypt.ps1" -Force:$AllCurrent @ScriptParams
		& "$Destination\Software\FileZilla.ps1" -Force:$AllCurrent @ScriptParams
		& "$Destination\Software\Google.ps1" -Force:$AllCurrent @ScriptParams
		& "$Destination\Software\GPG.ps1" -Force:$AllCurrent @ScriptParams
		& "$Destination\Software\Greenshot.ps1" -Force:$AllCurrent @ScriptParams
		& "$Destination\Software\Intel.ps1" -Force:$AllCurrent @ScriptParams
		& "$Destination\Software\InternetBrowser.ps1" -Force:$AllCurrent @ScriptParams
		& "$Destination\Software\Java.ps1" -Force:$AllCurrent @ScriptParams
		& "$Destination\Software\MetaTrader.ps1" -Force:$AllCurrent @ScriptParams
		& "$Destination\Software\MSI.ps1" -Force:$AllCurrent @ScriptParams
		& "$Destination\Software\Nvidia.ps1" -Force:$AllCurrent @ScriptParams
		& "$Destination\Software\OBSStudio.ps1" -Force:$AllCurrent @ScriptParams
		& "$Destination\Software\OpenSSH.ps1" -Force:$AllCurrent @ScriptParams
		& "$Destination\Software\PasswordSafe.ps1" -Force:$AllCurrent @ScriptParams
		& "$Destination\Software\qBittorrent.ps1" -Force:$AllCurrent @ScriptParams
		& "$Destination\Software\RivaTuner.ps1" -Force:$AllCurrent @ScriptParams
		& "$Destination\Software\Steam.ps1" -Force:$AllCurrent @ScriptParams
		& "$Destination\Software\TeamViewer.ps1" -Force:$AllCurrent @ScriptParams
		& "$Destination\Software\Thunderbird.ps1" -Force:$AllCurrent @ScriptParams
		& "$Destination\Software\uTorrent.ps1" -Force:$AllCurrent @ScriptParams
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
		& "$Destination\Software\Microsoft\BingWallpaper.ps1" -Force:$AllCurrent @ScriptParams
		& "$Destination\Software\Microsoft\EdgeChromium.ps1" -Force:$AllCurrent @ScriptParams
		& "$Destination\Software\Microsoft\MicrosoftOffice.ps1" -Force:$AllCurrent @ScriptParams
		& "$Destination\Software\Microsoft\OneDrive.ps1" -Force:$AllCurrent @ScriptParams
		& "$Destination\Software\Microsoft\SysInternals.ps1" -Force:$AllCurrent @ScriptParams
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
		& "$Destination\CoreNetworking.ps1" -Force:$AllCurrent
		& "$Destination\ICMP.ps1" -Force:$AllCurrent
		& "$Destination\Multicast.ps1" -Force:$AllCurrent
		& "$Destination\Temporary.ps1" -Force:$AllCurrent
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
		& "$Destination\CoreNetworking.ps1" -Force:$AllCurrent
		& "$Destination\ICMP.ps1" -Force:$AllCurrent
		& "$Destination\Multicast.ps1" -Force:$AllCurrent
		& "$Destination\Temporary.ps1" -Force:$AllCurrent
		$AllCurrent = $YesToAll
	}
}

Write-Information -Tags $ThisScript -MessageData "INFO: Deployment of firewall rules is complete"

# Set up global firewall setting, network and firewall profile and apply GPO changes
& "$ProjectRoot\Scripts\Complete-Firewall.ps1" -Force:$Force
Set-Variable -Name UpdateGPO -Scope Global -Value $PreviousUpdateGPO

# Verify permissions to write firewall logs if needed
& "$ProjectRoot\Scripts\Grant-Logs.ps1" @GrantLogsParams

# Set desktop shortcut to custom management console
Set-Shortcut -Name "Firewall.lnk" -Path "AllUsersDesktop" -Admin `
	-TargetPath "$ProjectRoot\Config\System\Firewall.msc" `
	-Description "View and modify GPO firewall" -IconIndex -19 `
	-IconLocation "$Env:SystemDrive\Windows\System32\Shell32.dll" @SetShortCutParams

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
	Write-Information -Tags $ThisScript -MessageData "INFO: All operations completed successfully!"
}

Write-Information -MessageData "" -InformationVariable ThrowAway

# Restore changed variables status
Set-Variable -Name ErrorStatus -Scope Global -Value $PreviousErrorStatus
Set-Variable -Name WarningStatus -Scope Global -Value $PreviousWarningStatus
Set-Variable -Name ProjectCheck -Scope Global -Force -Value $PreviousProjectCheck

Disconnect-Computer $Domain
Update-Log
