
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

<#
.SYNOPSIS
Outbound firewall rules for EpicGames

.DESCRIPTION

.EXAMPLE
PS> .\EpicGames.ps1

.INPUTS
None. You cannot pipe objects to EpicGames.ps1

.OUTPUTS
None. EpicGames.ps1 does not generate any output

.NOTES
None.
#>

#region Initialization
#Requires -RunAsAdministrator
. $PSScriptRoot\..\..\..\..\Config\ProjectSettings.ps1

# Check requirements
Initialize-Project -Abort

# Imports
. $PSScriptRoot\..\DirectionSetup.ps1
Import-Module -Name Ruleset.Logging
Import-Module -Name Ruleset.UserInfo

# Setup local variables
$Group = "Development - Epic Games"
$LocalProfile = "Any"
$Accept = "Outbound rules for Epic Games launcher and engine will be loaded, recommended if Epic Games launcher and engine is installed to let it access to network"
$Deny = "Skip operation, outbound rules for Epic Games launcher and engine will not be loaded into firewall"

# User prompt
Update-Context "IPv$IPVersion" $Direction $Group
if (!(Approve-Execute -Accept $Accept -Deny $Deny)) { exit }
#endregion

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore

#
# Epic games installation directories
#
$EngineRoot = "%SystemDrive%\Users\$DefaultUser\GitHub\UnrealEngine\Engine"
$LauncherRoot = "%ProgramFiles(x86)%\Epic Games"

#
# Rules Epic games engine
# NOTE: first launch of engine must be done with launcher ran as Administrator
#

# Test if installation exists on system
if ((Test-Installation "UnrealEngine" ([ref] $EngineRoot)) -or $ForceLoad)
{
	# TODO: this executable name depends on if the engine was built from source
	# $Program = "$EngineRoot\Binaries\Win64\CrashReportClientEditor-Win64-Development.exe"
	$Program = "$EngineRoot\Binaries\Win64\CrashReportClientEditor.exe"
	Test-File $Program

	New-NetFirewallRule -Platform $Platform `
		-DisplayName "Unreal Engine - CrashReportClientEditor" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $LocalProfile -InterfaceType $DefaultInterface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
		-LocalUser $UsersGroupSDDL `
		-Description "Used to send crash report to epic games." | Format-Output

	# NOTE: port 6666
	New-NetFirewallRule -Platform $Platform `
		-DisplayName "Unreal Engine - Invalid traffic" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile $LocalProfile -InterfaceType $DefaultInterface `
		-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress 230.0.0.1 -LocalPort Any -RemotePort Any `
		-LocalUser Any -LocalOnlyMapping $false -LooseSourceMapping $false `
		-Description "This address is reserved, Epic Games company doesn't respect IANA rules,
For more info see 'Readme\ProblematicTraffic.md' Case 9" | Format-Output

	# TODO: this executable exists only if the engine was built from source
	$Program = "$EngineRoot\Binaries\DotNET\GitDependencies.exe"
	Test-File $Program

	New-NetFirewallRule -Platform $Platform `
		-DisplayName "Unreal Engine - GitDependencies" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $LocalProfile -InterfaceType $DefaultInterface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80 `
		-LocalUser $UsersGroupSDDL `
		-Description "Engine repo source tool to download binaries." | Format-Output

	$Program = "$EngineRoot\Binaries\DotNET\SwarmAgent.exe"
	Test-File $Program

	New-NetFirewallRule -Platform $Platform `
		-DisplayName "Unreal Engine - SwarmAgent" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $LocalProfile -InterfaceType $DefaultInterface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress LocalSubnet4 -LocalPort Any -RemotePort 80 `
		-LocalUser $UsersGroupSDDL `
		-Description "Swarm agent is used for build farm." | Format-Output

	$Program = "$EngineRoot\Binaries\Win64\UE4Editor.exe"
	Test-File $Program

	New-NetFirewallRule -Platform $Platform `
		-DisplayName "Unreal Engine - Editor x64" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $LocalProfile -InterfaceType $DefaultInterface `
		-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort Any `
		-LocalUser $UsersGroupSDDL -LocalOnlyMapping $false -LooseSourceMapping $false `
		-Description "" | Format-Output

	# NOTE: port 6666
	New-NetFirewallRule -Platform $Platform `
		-DisplayName "Unreal Engine - Invalid traffic" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile $LocalProfile -InterfaceType $DefaultInterface `
		-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress 230.0.0.1 -LocalPort Any -RemotePort Any `
		-LocalUser Any -LocalOnlyMapping $false -LooseSourceMapping $false `
		-Description "This address is reserved, Epic Games company doesn't respect IANA rules,
For more info see 'Readme\ProblematicTraffic.md' Case 9" | Format-Output

	New-NetFirewallRule -Platform $Platform `
		-DisplayName "Unreal Engine - Editor x64" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $LocalProfile -InterfaceType $DefaultInterface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
		-LocalUser $UsersGroupSDDL `
		-Description "" | Format-Output

	$Program = "$EngineRoot\Binaries\DotNET\UnrealBuildTool.exe"
	Test-File $Program

	New-NetFirewallRule -Platform $Platform `
		-DisplayName "Unreal Engine - UnrealBuildTool" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $LocalProfile -InterfaceType $DefaultInterface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80 `
		-LocalUser $UsersGroupSDDL `
		-Description "" | Format-Output
}

#
# Rules Epic games launcher
#

# Test if installation exists on system
if ((Test-Installation "EpicGames" ([ref] $LauncherRoot)) -or $ForceLoad)
{
	# Find-Installation will omit "Launcher" directory
	$LauncherRoot += "\Launcher\Portal\Binaries"

	$Program = "$LauncherRoot\Win32\EpicGamesLauncher.exe"
	Test-File $Program

	New-NetFirewallRule -Platform $Platform `
		-DisplayName "Epic Games - Launcher x32" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $LocalProfile -InterfaceType $DefaultInterface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
		-LocalUser $UsersGroupSDDL `
		-Description "Used for initial setup only - Installation of launcher" | Format-Output

	# TODO: launcher will install engine only as Administrator, and it will work even though we
	# don't have a rule for Administrators group.
	# It looks like BUILTIN\Users allows also Administrators?
	$Program = "$LauncherRoot\Win64\EpicGamesLauncher.exe"
	Test-File $Program

	New-NetFirewallRule -Platform $Platform `
		-DisplayName "Epic Games - Launcher x64" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $LocalProfile -InterfaceType $DefaultInterface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443, 5222 `
		-LocalUser $UsersGroupSDDL `
		-Description "Storefront and software. The Epic Games Store is a storefront for games
available via the web and built into Epic Games' launcher application.
Both web and application allow players to purchase games, while through the launcher the player
can install and keep their games up to date" |
	Format-Output

	# NOTE: port 6666
	New-NetFirewallRule -Platform $Platform `
		-DisplayName "Epic Games - Invalid traffic" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile $LocalProfile -InterfaceType $DefaultInterface `
		-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress 230.0.0.1 -LocalPort Any -RemotePort Any `
		-LocalUser Any -LocalOnlyMapping $false -LooseSourceMapping $false `
		-Description "This address is reserved, Epic Games company doesn't respect IANA rules,
For more info see 'Readme\ProblematicTraffic.md' Case 9" | Format-Output

	New-NetFirewallRule -Platform $Platform `
		-DisplayName "Epic Games - Launcher x64" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $LocalProfile -InterfaceType $DefaultInterface `
		-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort Any `
		-LocalUser $UsersGroupSDDL -LocalOnlyMapping $false -LooseSourceMapping $false `
		-Description "Storefront and software. The Epic Games Store is a storefront for games
available via the web and built into Epic Games' launcher application.
Both web and application allow players to purchase games, while through the launcher the player
can install and keep their games up to date." |
	Format-Output
}

Update-Log
