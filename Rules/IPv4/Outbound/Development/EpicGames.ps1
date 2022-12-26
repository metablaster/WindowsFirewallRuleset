
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
Outbound firewall rules for EpicGames

.DESCRIPTION
Outbound firewall rules for Epic Games game engine

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
. $PSScriptRoot\..\..\..\..\Config\ProjectSettings.ps1 $PSCmdlet -Domain $Domain
Initialize-Project
. $PSScriptRoot\..\DirectionSetup.ps1

Import-Module -Name Ruleset.UserInfo

# Setup local variables
$Group = "Development - Epic Games"
$LocalProfile = "Any"
$Accept = "Outbound rules for Epic Games launcher and engine will be loaded, recommended if Epic Games launcher and engine is installed to let it access to network"
$Deny = "Skip operation, outbound rules for Epic Games launcher and engine will not be loaded into firewall"
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
$EngineRoot = "%SystemDrive%\Users\$DefaultUser\GitHub\UnrealEngine\Engine"
$LauncherRoot = "%ProgramFiles(x86)%\Epic Games"

#
# Rules unreal engine
# NOTE: first launch of engine must be done with launcher ran as Administrator
#

# Test if installation exists on system
if ((Confirm-Installation "UnrealEngine" ([ref] $EngineRoot)) -or $ForceLoad)
{
	# TODO: this executable name depends on if the engine was built from source
	# $Program = "$EngineRoot\Binaries\Win64\CrashReportClientEditor-Win64-Development.exe"
	$Program = "$EngineRoot\Binaries\Win64\CrashReportClientEditor.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "Unreal Engine - CrashReportClientEditor" `
		 -Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "Used to send crash report to epic games." | Format-RuleOutput

		# NOTE: port 6666
		New-NetFirewallRule -DisplayName "Unreal Engine - Invalid traffic" `
		 -Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Block -Direction $Direction -Protocol UDP `
			-LocalAddress Any -RemoteAddress 230.0.0.1 `
			-LocalPort Any -RemotePort Any `
			-LocalUser Any `
			-InterfaceType $DefaultInterface `
			-LocalOnlyMapping $false -LooseSourceMapping $false `
			-Description "This address is reserved, Epic Games company doesn't respect IANA rules,
For more info see 'Readme\ProblematicTraffic.md' Case 9" | Format-RuleOutput
	}

	# TODO: this executable exists only if the engine was built from source
	$Program = "$EngineRoot\Binaries\DotNET\GitDependencies.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "Unreal Engine - GitDependencies" `
		 -Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 80 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "Engine repo source tool to download binaries." | Format-RuleOutput
	}

	$Program = "$EngineRoot\Binaries\DotNET\SwarmAgent.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "Unreal Engine - SwarmAgent" `
		 -Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress LocalSubnet4 `
			-LocalPort Any -RemotePort 80 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "Swarm agent is used for build farm." | Format-RuleOutput
	}

	$Program = "$EngineRoot\Binaries\Win64\UE4Editor.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "Unreal Engine - Editor x64" `
		 -Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort Any `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-LocalOnlyMapping $false -LooseSourceMapping $false `
			-Description "" | Format-RuleOutput

		# NOTE: port 6666
		New-NetFirewallRule -DisplayName "Unreal Engine - Invalid traffic" `
		 -Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Block -Direction $Direction -Protocol UDP `
			-LocalAddress Any -RemoteAddress 230.0.0.1 `
			-LocalPort Any -RemotePort Any `
			-LocalUser Any `
			-InterfaceType $DefaultInterface `
			-LocalOnlyMapping $false -LooseSourceMapping $false `
			-Description "This address is reserved, Epic Games company doesn't respect IANA rules,
For more info see 'Readme\ProblematicTraffic.md' Case 9" | Format-RuleOutput

		New-NetFirewallRule -DisplayName "Unreal Engine - Editor x64" `
		 -Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "" | Format-RuleOutput
	}

	$Program = "$EngineRoot\Binaries\DotNET\UnrealBuildTool.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "Unreal Engine - UnrealBuildTool" `
		 -Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 80 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "" | Format-RuleOutput
	}
}

#
# Rules Epic games launcher
#

# Test if installation exists on system
if ((Confirm-Installation "EpicGames" ([ref] $LauncherRoot)) -or $ForceLoad)
{
	# NOTE: launcher will install engine only as Administrator, and it will work even if rule
	# doesn't apply for Administrators group, however it won't work later for some tasks.
	$EpicUsers = Get-SDDL -Group "Users", "Administrators" -Merge

	# Search-Installation will omit "Launcher" directory
	$LauncherRoot += "\Launcher"

	$Program = "$LauncherRoot\Portal\Binaries\Win32\EpicGamesLauncher.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "Epic Games - Launcher x32" `
		 -Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 80, 443 `
			-LocalUser $EpicUsers `
			-InterfaceType $DefaultInterface `
			-Description "Used for initial setup only - Installation of launcher" | Format-RuleOutput
	}

	$Program = "$LauncherRoot\Portal\Binaries\Win64\EpicGamesLauncher.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "Epic Games - Launcher x64" `
		 -Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 80, 443, 5222 `
			-LocalUser $EpicUsers `
			-InterfaceType $DefaultInterface `
			-Description "Storefront and software. The Epic Games Store is a storefront for games
available via the web and built into Epic Games' launcher application.
Both web and application allow players to purchase games, while through the launcher the player
can install and keep their games up to date" |
		Format-RuleOutput

		# NOTE: port 6666
		New-NetFirewallRule -DisplayName "Epic Games - Invalid traffic" `
		 -Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Block -Direction $Direction -Protocol UDP `
			-LocalAddress Any -RemoteAddress 230.0.0.1 `
			-LocalPort Any -RemotePort Any `
			-LocalUser Any `
			-InterfaceType $DefaultInterface `
			-LocalOnlyMapping $false -LooseSourceMapping $false `
			-Description "This address is reserved, Epic Games company doesn't respect IANA rules,
For more info see 'Readme\ProblematicTraffic.md' Case 9" | Format-RuleOutput

		New-NetFirewallRule -DisplayName "Epic Games - Launcher x64" `
		 -Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort Any `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-LocalOnlyMapping $false -LooseSourceMapping $false `
			-Description "Storefront and software. The Epic Games Store is a storefront for games
available via the web and built into Epic Games' launcher application.
Both web and application allow players to purchase games, while through the launcher the player
can install and keep their games up to date." |
		Format-RuleOutput
	}

	$Program = "$LauncherRoot\Engine\Binaries\Win64\EpicWebHelper.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "Epic Games - web helper" `
		 -Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $EpicUsers `
			-InterfaceType $DefaultInterface `
			-Description "" | Format-RuleOutput
	}
}

if ($UpdateGPO)
{
	Invoke-Process gpupdate.exe
	Disconnect-Computer -Domain $Domain
}

Update-Log
