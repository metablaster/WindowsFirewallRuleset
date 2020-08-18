
<#
MIT License

Project: "Windows Firewall Ruleset" serves to manage firewall on Windows systems
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

# Check requirements for this project
Import-Module -Name Project.AllPlatforms.System
Test-SystemRequirements

# Imports
. $PSScriptRoot\..\DirectionSetup.ps1
. $PSScriptRoot\..\..\IPSetup.ps1
Import-Module -Name Project.AllPlatforms.Logging
Import-Module -Name Project.Windows.UserInfo @Logs
Import-Module -Name Project.Windows.ProgramInfo @Logs
Import-Module -Name Project.AllPlatforms.Utility @Logs

#
# Setup local variables:
#
$Group = "Software - Steam"
$FirewallProfile = "Private, Public"

# Ask user if he wants to load these rules
Update-Context "IPv$IPVersion" $Direction $Group @Logs
if (!(Approve-Execute @Logs)) { exit }

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore @Logs

#
# Steam installation directories
#
$SteamRoot = "%ProgramFiles(x86)%\Steam"

#
# Rules for Steam client
#

# Test if installation exists on system
if ((Test-Installation "Steam" ([ref] $SteamRoot) @Logs) -or $ForceLoad)
{
	$Program = "$SteamRoot\Steam.exe"
	Test-File $Program @Logs
	New-NetFirewallRule -Platform $Platform `
		-DisplayName "Steam Dedicated or Listen Servers" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $FirewallProfile -InterfaceType $Interface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort 27015 -RemotePort Any `
		-EdgeTraversalPolicy Block -LocalUser $UsersGroupSDDL `
		-Description "SRCDS Rcon port" @Logs | Format-Output @Logs

	# TODO: Inbound In-Home streaming ports are not tested, but surely needed as outbound, see also:
	# https://support.steampowered.com/kb_article.php?ref=8571-GLVN-8711
	New-NetFirewallRule -Platform $Platform `
		-DisplayName "Steam In-Home Streaming" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile Private -InterfaceType $Interface `
		-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress LocalSubnet4 -LocalPort 27031, 27036 -RemotePort 27031, 27036 `
		-EdgeTraversalPolicy Block -LocalUser $UsersGroupSDDL -LocalOnlyMapping $false -LooseSourceMapping $false `
		-Description "Steam In-Home streaming, one PC sends its video and audio to another PC.
	The other PC views the video and audio like it's watching a movie, sending back mouse, keyboard, and controller input to the other PC." @Logs | Format-Output @Logs

	New-NetFirewallRule -Platform $Platform `
		-DisplayName "Steam In-Home Streaming" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile Private -InterfaceType $Interface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress LocalSubnet4 -LocalPort 27036, 27037 -RemotePort 27036, 27037 `
		-EdgeTraversalPolicy Block -LocalUser $UsersGroupSDDL `
		-Description "Steam In-Home streaming, one PC sends its video and audio to another PC.
	The other PC views the video and audio like it's watching a movie, sending back mouse, keyboard, and controller input to the other PC." @Logs | Format-Output @Logs
}

Update-Log
