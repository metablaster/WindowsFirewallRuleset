
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

. $PSScriptRoot\..\..\..\..\Config\ProjectSettings.ps1

# Check requirements
Initialize-Project

# Imports
. $PSScriptRoot\..\DirectionSetup.ps1
. $PSScriptRoot\..\..\IPSetup.ps1
Import-Module -Name Project.AllPlatforms.Logging
Import-Module -Name Project.Windows.UserInfo

#
# Setup local variables
#
$Group = "Development - Epic Games"
$FirewallProfile = "Any"

# User prompt
Update-Context "IPv$IPVersion" $Direction $Group @Logs
if (!(Approve-Execute @Logs)) { exit }

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore @Logs

#
# Epic games installation directories
#
$EngineRoot = "%SystemDrive%\Users\User\source\repos\UnrealEngine\Engine"

# TODO: need to see listening ports

#
# Rules Epic games engine
#

# NOTE: default rule for crash report and swarm is edge traversal: defer to user
# for defer to user, interface and address (and probably ports too) must not be specified, platform must not be defined
# this does not suit our interests so removed

# Test if installation exists on system
if ((Test-Installation "UnrealEngine" ([ref] $EngineRoot) @Logs) -or $ForceLoad)
{
	$Program = "$EngineRoot\Binaries\Win64\CrashReportClientEditor-Win64-Development.exe"
	Test-File $Program @Logs
	New-NetFirewallRule -Platform $Platform `
		-DisplayName "Unreal Engine - CrashReportClientEditor" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $FirewallProfile -InterfaceType Any `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Any -LocalPort Any -RemotePort Any `
		-EdgeTraversalPolicy Block -LocalUser $UsersGroupSDDL `
		-Description "" @Logs | Format-Output @Logs

	New-NetFirewallRule -Platform $Platform `
		-DisplayName "Unreal Engine - CrashReportClientEditor" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $FirewallProfile -InterfaceType Any `
		-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress Any -LocalPort Any -RemotePort Any `
		-EdgeTraversalPolicy Block -LocalUser $UsersGroupSDDL -LocalOnlyMapping $false -LooseSourceMapping $false `
		-Description "" @Logs | Format-Output @Logs

	$Program = "$EngineRoot\Binaries\DotNET\SwarmAgent.exe"
	Test-File $Program @Logs
	New-NetFirewallRule -Platform $Platform `
		-DisplayName "Unreal Engine - SwarmAgent" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $FirewallProfile -InterfaceType Any `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress LocalSubnet4 -LocalPort Any -RemotePort Any `
		-EdgeTraversalPolicy Block -LocalUser $UsersGroupSDDL `
		-Description "Swarm agent is used for build farm." @Logs | Format-Output @Logs

	New-NetFirewallRule -Platform $Platform `
		-DisplayName "Unreal Engine - SwarmAgent" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $FirewallProfile -InterfaceType Any `
		-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress LocalSubnet4 -LocalPort Any -RemotePort Any `
		-EdgeTraversalPolicy Block -LocalUser $UsersGroupSDDL -LocalOnlyMapping $false -LooseSourceMapping $false `
		-Description "Swarm agent is used for build farm." @Logs | Format-Output @Logs

	$Program = "$EngineRoot\Binaries\Win64\UnrealInsights.exe"
	Test-File $Program @Logs
	New-NetFirewallRule -Platform $Platform `
		-DisplayName "Unreal Engine - UnrealInsights" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $FirewallProfile -InterfaceType $Interface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress LocalSubnet4 -LocalPort Any -RemotePort Any `
		-EdgeTraversalPolicy Block -LocalUser $UsersGroupSDDL `
		-Description "" @Logs | Format-Output @Logs

	New-NetFirewallRule -Platform $Platform `
		-DisplayName "Unreal Engine - UnrealInsights" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $FirewallProfile -InterfaceType $Interface `
		-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress LocalSubnet4 -LocalPort Any -RemotePort Any `
		-EdgeTraversalPolicy Block -LocalUser $UsersGroupSDDL -LocalOnlyMapping $false -LooseSourceMapping $false `
		-Description "" @Logs | Format-Output @Logs
}

Update-Log
