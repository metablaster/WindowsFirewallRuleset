
<#
MIT License

Project: "Windows Firewall Ruleset" serves to manage firewall on Windows systems,
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (c) 2019, 2020 metablaster zebal@protonmail.ch

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

# Check requirements for this project
Import-Module -Name $RepoDir\Modules\System
Test-SystemRequirements

# Includes
. $PSScriptRoot\..\DirectionSetup.ps1
. $PSScriptRoot\..\..\IPSetup.ps1
Import-Module -Name $RepoDir\Modules\UserInfo
Import-Module -Name $RepoDir\Modules\ProgramInfo
Import-Module -Name $RepoDir\Modules\FirewallModule

#
# Setup local variables:
#
$Group = "Development - Epic Games"
$Profile = "Any"

# Ask user if he wants to load these rules
Update-Context "IPv$IPVersion" $Direction $Group
if (!(Approve-Execute)) { exit }

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction SilentlyContinue

#
# Epic games installation directories
#
$EngineRoot = "%SystemDrive%\Users\User\source\repos\UnrealEngine\Engine"
$LauncherRoot = "%ProgramFiles(x86)%\Epic Games\Launcher"

#
# Rules Epic games engine
#

# Test if installation exists on system
if ((Test-Installation "UnrealEngine" ([ref] $EngineRoot)) -or $Force)
{
	$Program = "$EngineRoot\Binaries\Win64\CrashReportClientEditor-Win64-Development.exe"
	Test-File $Program
	New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
	-DisplayName "Unreal Engine - CrashReportClientEditor" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
	-LocalUser $UserAccountsSDDL `
	-Description "Used to send crash report to epic games." | Format-Output

	$Program = "$EngineRoot\Binaries\DotNET\GitDependencies.exe"
	Test-File $Program
	New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
	-DisplayName "Unreal Engine - GitDependencies" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80 `
	-LocalUser $UserAccountsSDDL `
	-Description "Engine repo source tool to dowload binaries." | Format-Output

	$Program = "$EngineRoot\Binaries\DotNET\SwarmAgent.exe"
	Test-File $Program
	New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
	-DisplayName "Unreal Engine - SwarmAgent" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress LocalSubnet4 -LocalPort Any -RemotePort 80 `
	-LocalUser $UserAccountsSDDL `
	-Description "Swarm agent is used for build farm." | Format-Output

	$Program = "$EngineRoot\Binaries\Win64\UE4Editor.exe"
	Test-File $Program
	New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
	-DisplayName "Unreal Engine - Editor x64" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort Any `
	-LocalUser $UserAccountsSDDL -LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "" | Format-Output

	$Program = "$EngineRoot\Binaries\Win64\UE4Editor.exe"
	Test-File $Program
	New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
	-DisplayName "Unreal Engine - Editor x64" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
	-LocalUser $UserAccountsSDDL `
	-Description "" | Format-Output

	$Program = "$EngineRoot\Binaries\DotNET\UnrealBuildTool.exe"
	Test-File $Program
	New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
	-DisplayName "Unreal Engine - UnrealBuildTool" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80 `
	-LocalUser $UserAccountsSDDL `
	-Description "" | Format-Output
}

#
# Rules Epic games launcher
#

# Test if installation exists on system
if ((Test-Installation "EpicGames" ([ref] $LauncherRoot)) -or $Force)
{
	$Program = "$LauncherRoot\Portal\Binaries\Win32\EpicGamesLauncher.exe"
	Test-File $Program
	New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
	-DisplayName "Epic Games - Launcher x32" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
	-LocalUser $UserAccountsSDDL `
	-Description "Used for initial setup only" | Format-Output

	$Program = "$LauncherRoot\Portal\Binaries\Win64\EpicGamesLauncher.exe"
	Test-File $Program
	New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
	-DisplayName "Epic Games - Launcher x64" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443, 5222 `
	-LocalUser $UserAccountsSDDL `
	-Description "" | Format-Output

	$Program = "$LauncherRoot\Portal\Binaries\Win64\EpicGamesLauncher.exe"
	Test-File $Program
	New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
	-DisplayName "Epic Games - Launcher x64" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort Any `
	-LocalUser $UserAccountsSDDL -LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "" | Format-Output
}
