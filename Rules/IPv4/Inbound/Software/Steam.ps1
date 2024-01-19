
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2024 metablaster zebal@protonmail.ch

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
Inbound firewall rules for Steam

.DESCRIPTION
Inbound firewall rules for Steam client

.PARAMETER Domain
Computer name onto which to deploy rules

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
	[Alias("ComputerName", "CN")]
	[string] $Domain = [System.Environment]::MachineName,

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
. $PSScriptRoot\..\..\..\..\Config\ProjectSettings.ps1 $PSCmdlet -Domain $Domain
Initialize-Project
. $PSScriptRoot\..\DirectionSetup.ps1

Import-Module -Name Ruleset.UserInfo

# Setup local variables
$Group = "Software - Steam"
$Accept = "Inbound rules for Steam client will be loaded, recommended if Steam client is installed to let it access to network"
$Deny = "Skip operation, inbound rules for Steam client will not be loaded into firewall"
if (!(Approve-Execute -Accept $Accept -Deny $Deny -ContextLeaf $Group -Force:$Force)) { exit }

$PSDefaultParameterValues["Confirm-Installation:Quiet"] = $Quiet
$PSDefaultParameterValues["Confirm-Installation:Interactive"] = $Interactive
$PSDefaultParameterValues["Test-ExecutableFile:Quiet"] = $Quiet
$PSDefaultParameterValues["Test-ExecutableFile:Force"] = $Trusted -or $SkipSignatureCheck
#endregion

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore

#
# Steam installation directories
#
$SteamRoot = "%ProgramFiles(x86)%\Steam"

#
# Rules for Steam client
#

# Test if installation exists on system
if ((Confirm-Installation "Steam" ([ref] $SteamRoot)) -or $ForceLoad)
{
	$Program = "$SteamRoot\Steam.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "Steam Dedicated or Listen Servers" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort 27015 -RemotePort Any `
			-LocalUser $UsersGroupSDDL -EdgeTraversalPolicy Block `
			-InterfaceType $DefaultInterface `
			-Description "SRCDS Rcon port" | Format-RuleOutput

		# TODO: Inbound In-Home streaming ports are not tested, but surely needed as outbound, see also:
		# https://support.steampowered.com/kb_article.php?ref=8571-GLVN-8711
		New-NetFirewallRule -DisplayName "Steam In-Home Streaming" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile Private `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
			-LocalAddress Any -RemoteAddress LocalSubnet4 `
			-LocalPort 27031, 27036 -RemotePort 27031, 27036 `
			-LocalUser $UsersGroupSDDL -EdgeTraversalPolicy Block `
			-InterfaceType $DefaultInterface `
			-LocalOnlyMapping $false -LooseSourceMapping $false `
			-Description "Steam In-Home streaming, one PC sends its video and audio to another PC.
The other PC views the video and audio like it's watching a movie, sending back mouse, keyboard,
and controller input to the other PC." | Format-RuleOutput

		New-NetFirewallRule -DisplayName "Steam In-Home Streaming" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile Private `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress LocalSubnet4 `
			-LocalPort 27036, 27037 -RemotePort 27036, 27037 `
			-LocalUser $UsersGroupSDDL -EdgeTraversalPolicy Block `
			-InterfaceType $DefaultInterface `
			-Description "Steam In-Home streaming, one PC sends its video and audio to another PC.
The other PC views the video and audio like it's watching a movie, sending back mouse, keyboard,
and controller input to the other PC." | Format-RuleOutput
	}
}

if ($UpdateGPO)
{
	Invoke-Process gpupdate.exe
	Disconnect-Computer -Domain $Domain
}

Update-Log
