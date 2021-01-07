
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

<#
.SYNOPSIS
Inbound firewall rules for qBittorrent

.DESCRIPTION
Inbound firewall rules for qBitTorrent torrent client

.EXAMPLE
PS> .\qBittorrent.ps1

.INPUTS
None. You cannot pipe objects to qBittorrent.ps1

.OUTPUTS
None. qBittorrent.ps1 does not generate any output

.NOTES
None.
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding()]
param (
	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\..\..\..\Config\ProjectSettings.ps1

# Check requirements
Initialize-Project -Abort

# Imports
. $PSScriptRoot\..\DirectionSetup.ps1
Import-Module -Name Ruleset.UserInfo

# Setup local variables
$Group = "Software - qBittorrent"
$Accept = "Inbound rules for qBittorrent software will be loaded, recommended if qBittorrent software is installed to let it access to network"
$Deny = "Skip operation, inbound rules for qBittorrent software will not be loaded into firewall"

# User prompt
Update-Context "IPv$IPVersion" $Direction $Group
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#endregion

#
# qBittorrent installation directories
#
$qBittorrentRoot = "%ProgramFiles%\qBittorrent"

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore

#
# Rules for qBittorrent
# TODO: ports need to be updated
#

# Test if installation exists on system
if ((Confirm-Installation "qBittorrent" ([ref] $qBittorrentRoot)) -or $ForceLoad)
{
	$Program = "$qBittorrentRoot\qbittorrent.exe"
	if (Test-ExecutableFile $Program)
	{
		# TODO: requires uTP protocol?
		New-NetFirewallRule -DisplayName "qBittorrent - DHT" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
			-LocalAddress Any -RemoteAddress Any `
			-LocalPort 1161 -RemotePort 1024-65535 `
			-LocalUser $UsersGroupSDDL -EdgeTraversalPolicy DeferToApp `
			-InterfaceType $DefaultInterface `
			-LocalOnlyMapping $false -LooseSourceMapping $false `
			-Description "qBittorrent UDP listener, usually for DHT." |
		Format-Output

		New-NetFirewallRule -DisplayName "qBittorrent - Listening port" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Any `
			-LocalPort 1161 -RemotePort 1024-65535 `
			-LocalUser $UsersGroupSDDL -EdgeTraversalPolicy DeferToApp `
			-InterfaceType $DefaultInterface `
			-Description "qBittorrent TCP listener." |
		Format-Output

		New-NetFirewallRule -DisplayName "qBittorrent - Embedded tracker port" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Any `
			-LocalPort 9000 -RemotePort 1024-65535 `
			-LocalUser $UsersGroupSDDL -EdgeTraversalPolicy DeferToApp `
			-InterfaceType $DefaultInterface `
			-Description "qBittorrent Embedded tracker port." |
		Format-Output

		# NOTE: remote port can be other than 6771, remote client will fall back to 6771
		New-NetFirewallRule -DisplayName "qBittorrent - Local Peer discovery" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile Private `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
			-LocalAddress 224.0.0.0-239.255.255.255 -RemoteAddress LocalSubnet4 `
			-LocalPort 6771 -RemotePort 6771 `
			-LocalUser $UsersGroupSDDL -EdgeTraversalPolicy DeferToApp `
			-InterfaceType $DefaultInterface `
			-LocalOnlyMapping $false -LooseSourceMapping $false `
			-Description "UDP multicast search to identify other peers in your subnet that are also on
torrents you are on." |
		Format-Output

		New-NetFirewallRule -DisplayName "qBittorrent - Web UI" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Any `
			-LocalPort 8080 -RemotePort Any `
			-LocalUser $UsersGroupSDDL -EdgeTraversalPolicy Allow `
			-InterfaceType $DefaultInterface `
			-Description "qBittorrent Remote control from browser." |
		Format-Output
	}
}

Update-Log
