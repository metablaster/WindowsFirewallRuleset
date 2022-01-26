
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
Inbound firewall rules for EpicGames

.DESCRIPTION
Inbound firewall rules for Epic Games game engine

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
PS> .\EpicGames.ps1

.INPUTS
None. You cannot pipe objects to EpicGames.ps1

.OUTPUTS
None. EpicGames.ps1 does not generate any output

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
$Group = "Development - Epic Games"
$LocalProfile = "Any"
$Accept = "Inbound rules for Epic Games launcher and engine will be loaded, recommended if Epic Games launcher and engine is installed to let it access to network"
$Deny = "Skip operation, inbound rules for Epic Games launcher and engine will not be loaded into firewall"

if (!(Approve-Execute -Accept $Accept -Deny $Deny -ContextLeaf $Group -Force:$Force)) { exit }
$PSDefaultParameterValues["Confirm-Installation:Quiet"] = $Quiet
$PSDefaultParameterValues["Confirm-Installation:Interactive"] = $Interactive
$PSDefaultParameterValues["Test-ExecutableFile:Quiet"] = $Quiet
$PSDefaultParameterValues["Test-ExecutableFile:Force"] = $Trusted -or $SkipSignatureCheck
#endregion

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore

#
# Epic games installation directories
#
$EngineRoot = "%SystemDrive%\Users\$DefaultUser\source\repos\UnrealEngine\Engine"

# TODO: need to see listening ports

#
# Rules unreal engine
#

# NOTE: default rule for crash report and swarm is edge traversal: defer to user
# for defer to user, interface and address (and probably ports too) must not be specified, platform must not be defined
# this does not suit our interests so removed

# Test if installation exists on system
if ((Confirm-Installation "UnrealEngine" ([ref] $EngineRoot)) -or $ForceLoad)
{
	$Program = "$EngineRoot\Binaries\Win64\CrashReportClientEditor-Win64-Development.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "Unreal Engine - CrashReportClientEditor" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Any `
			-LocalPort Any -RemotePort Any `
			-LocalUser $UsersGroupSDDL -EdgeTraversalPolicy Block `
			-InterfaceType Any `
			-Description "" | Format-RuleOutput

		New-NetFirewallRule -DisplayName "Unreal Engine - CrashReportClientEditor" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
			-LocalAddress Any -RemoteAddress Any `
			-LocalPort Any -RemotePort Any `
			-LocalUser $UsersGroupSDDL -EdgeTraversalPolicy Block `
			-InterfaceType Any `
			-LocalOnlyMapping $false -LooseSourceMapping $false `
			-Description "" | Format-RuleOutput
	}

	$Program = "$EngineRoot\Binaries\DotNET\SwarmAgent.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "Unreal Engine - SwarmAgent" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress LocalSubnet4 `
			-LocalPort Any -RemotePort Any `
			-LocalUser $UsersGroupSDDL -EdgeTraversalPolicy Block `
			-InterfaceType Any `
			-Description "Swarm agent is used for build farm." | Format-RuleOutput

		New-NetFirewallRule -DisplayName "Unreal Engine - SwarmAgent" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
			-LocalAddress Any -RemoteAddress LocalSubnet4 `
			-LocalPort Any -RemotePort Any `
			-LocalUser $UsersGroupSDDL -EdgeTraversalPolicy Block `
			-InterfaceType Any `
			-LocalOnlyMapping $false -LooseSourceMapping $false `
			-Description "Swarm agent is used for build farm." | Format-RuleOutput
	}

	$Program = "$EngineRoot\Binaries\Win64\UnrealInsights.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "Unreal Engine - UnrealInsights" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress LocalSubnet4 `
			-LocalPort Any -RemotePort Any `
			-LocalUser $UsersGroupSDDL -EdgeTraversalPolicy Block `
			-InterfaceType $DefaultInterface `
			-Description "" | Format-RuleOutput

		New-NetFirewallRule -DisplayName "Unreal Engine - UnrealInsights" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
			-LocalAddress Any -RemoteAddress LocalSubnet4 `
			-LocalPort Any -RemotePort Any `
			-LocalUser $UsersGroupSDDL -EdgeTraversalPolicy Block `
			-InterfaceType $DefaultInterface `
			-LocalOnlyMapping $false -LooseSourceMapping $false `
			-Description "" | Format-RuleOutput
	}
}

if ($UpdateGPO)
{
	Invoke-Process gpupdate.exe -NoNewWindow -ArgumentList "/target:computer"
}

Update-Log
