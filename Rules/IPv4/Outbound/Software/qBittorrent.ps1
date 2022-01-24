
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
Outbound firewall rules for qBitTorrent

.DESCRIPTION
Outbound firewall rules for qBitTorrent torrent client

.PARAMETER Force
If specified, no prompt to run script is shown

.PARAMETER Trusted
If specified, rules will be loaded for executables with missing or invalid digital signature.
By default an error is generated and rule isn't loaded.

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
	[switch] $Trusted,

	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\..\..\..\Config\ProjectSettings.ps1 $PSCmdlet
. $PSScriptRoot\..\DirectionSetup.ps1

Initialize-Project -Strict
Import-Module -Name Ruleset.UserInfo

# Setup local variables
$Group = "Software - qBittorrent"
$Accept = "Outbound rules for qBittorrent software will be loaded, recommended if qBittorrent software is installed to let it access to network"
$Deny = "Skip operation, outbound rules for qBittorrent software will not be loaded into firewall"

if (!(Approve-Execute -Accept $Accept -Deny $Deny -ContextLeaf $Group -Force:$Force)) { exit }
$PSDefaultParameterValues["Test-ExecutableFile:Force"] = $Trusted -or $SkipSignatureCheck
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
	# TODO: some apps such as this one let user to configure ports, in all cases where this is true
	# we should either use default port or let user specify port.
	# TODO: the client also listens on IPv6, not all rules are hybrid, ie. local peer discovery
	# is known to search peers on local IPv6
	$Program = "$qBittorrentRoot\qbittorrent.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "qBittorrent - HTTP/S" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 80, 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "HTTP check for updates, HTTPS for client unknown" |
		Format-RuleOutput

		# NOTE: local port can be other than 6771, client will fall back to 6771
		New-NetFirewallRule -DisplayName "qbittorrent - Local Peer Discovery" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile Private `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
			-LocalAddress Any -RemoteAddress 224.0.0.0-239.255.255.255 `
			-LocalPort Any -RemotePort 6771 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-LocalOnlyMapping $false -LooseSourceMapping $false `
			-Description "UDP multicast search to identify other peers in your subnet that are also on
torrents you are on." |
		Format-RuleOutput

		New-NetFirewallRule -DisplayName "qbittorrent - SSDP" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile Private `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
			-LocalAddress Any -RemoteAddress 239.255.255.250 `
			-LocalPort Any -RemotePort 1900 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-LocalOnlyMapping $false -LooseSourceMapping $false `
			-Description "" |
		Format-RuleOutput

		# NOTE: We start from port 1024 which is most widely used, but some peers may set it to lower
		New-NetFirewallRule -DisplayName "qbittorrent - DHT" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort 1161 -RemotePort 1024-65535 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-LocalOnlyMapping $false -LooseSourceMapping $false `
			-Description "DHT (Distributed Hash Table, technical explanation) is a decentralized network
that qbittorrent can use to find more peers without a tracker.
What this means is that your client will be able to find peers even when the tracker is down,
or doesn't even exist anymore.
You can also download .torrent files through DHT if you have a magnet link, which can be obtained
from various sources." |
		Format-RuleOutput

		# NOTE: We use any local port instead of LocalPort 1161,
		# but otherwise the rule overlaps with DHT rule
		New-NetFirewallRule -DisplayName "qbittorrent - part of full range of ports used most often" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 6881-6968, 6970-6999 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-LocalOnlyMapping $false -LooseSourceMapping $false `
			-Description "BitTorrent part of full range of ports used most often (Trackers)	" |
		Format-RuleOutput

		New-NetFirewallRule -DisplayName "qbittorrent - NAT Port mapping protocol" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
			-LocalAddress Any -RemoteAddress DefaultGateway4 `
			-LocalPort Any -RemotePort 5351 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-LocalOnlyMapping $false -LooseSourceMapping $false `
			-Description "The NAT Port Mapping Protocol (NAT-PMP) is a network protocol for establishing
network address translation (NAT) settings and port forwarding configurations automatically without
user effort." |
		Format-RuleOutput

		# NOTE: We start from port 1024 which is most widely used, but some peers may set it to lower
		New-NetFirewallRule -DisplayName "qBittorrent - Client to peers" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 1024-65535 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "Torrent client" |
		Format-RuleOutput
	}
}

if ($UpdateGPO)
{
	Invoke-Process gpupdate.exe -NoNewWindow -ArgumentList "/target:computer"
}

Update-Log
