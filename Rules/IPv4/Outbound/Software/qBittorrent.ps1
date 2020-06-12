
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
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.System
Test-SystemRequirements

# Includes
. $PSScriptRoot\..\DirectionSetup.ps1
. $PSScriptRoot\..\..\IPSetup.ps1
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Logging
Import-Module -Name $ProjectRoot\Modules\Project.Windows.UserInfo @Logs
Import-Module -Name $ProjectRoot\Modules\Project.Windows.ProgramInfo @Logs
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Utility @Logs

#
# Setup local variables:
#
$Group = "Software - qBittorrent"
$FirewallProfile = "Private, Public"

# Ask user if he wants to load these rules
Update-Context "IPv$IPVersion" $Direction $Group @Logs
if (!(Approve-Execute @Logs)) { exit }

#
# qBittorrent installation directories
#
$qBittorrentRoot = "%ProgramFiles%\qBittorrent"

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore @Logs

#
# Rules for qBittorrent
# TODO: ports need to be updated
#

# Test if installation exists on system
if ((Test-Installation "qBittorrent" ([ref] $qBittorrentRoot) @Logs) -or $ForceLoad)
{
	# TODO: some apps such as this one let user to configure ports, in all cases where this is true
	# we should either use default port or let user specify port.
	# TODO: the client also listens on IPv6, not all rules are hybrid, ie. local peer discovery
	# is known to search peers on local IPv6
	$Program = "$qBittorrentRoot\qbittorrent.exe"
	Test-File $Program @Logs
	New-NetFirewallRule -DisplayName "qBittorrent - HTTP/S" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 80, 443 `
		-LocalUser $UsersGroupSDDL `
		-InterfaceType $Interface `
		-Description "HTTP check for updates, HTTPS for client unknown" `
		@Logs | Format-Output @Logs

	# NOTE: local port can be other than 6771, client will fall back to 6771
	New-NetFirewallRule -DisplayName "qbittorrent - Local Peer Discovery" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile Private `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
		-LocalAddress Any -RemoteAddress 224.0.0.0-239.255.255.255 `
		-LocalPort Any -RemotePort 6771 `
		-LocalUser $UsersGroupSDDL `
		-InterfaceType $Interface `
		-LocalOnlyMapping $false -LooseSourceMapping $false `
		-Description "UDP multicast search to identify other peers in your subnet that are also on
torrents you are on." `
		@Logs | Format-Output @Logs

	New-NetFirewallRule -DisplayName "qbittorrent - SSDP" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile Private `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
		-LocalAddress Any -RemoteAddress 239.255.255.250 `
		-LocalPort Any -RemotePort 1900 `
		-LocalUser $UsersGroupSDDL `
		-InterfaceType $Interface `
		-LocalOnlyMapping $false -LooseSourceMapping $false `
		-Description "" `
		@Logs | Format-Output @Logs

	# NOTE: We start from port 1024 which is most widely used, but some peers may set it to lower
	New-NetFirewallRule -DisplayName "qbittorrent - DHT" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort 1161 -RemotePort 1024-65535 `
		-LocalUser $UsersGroupSDDL `
		-InterfaceType $Interface `
		-LocalOnlyMapping $false -LooseSourceMapping $false `
		-Description "DHT (Distributed Hash Table, technical explanation) is a decentralized network
that qbittorrent can use to find more peers without a tracker.
What this means is that your client will be able to find peers even when the tracker is down,
or doesn't even exist anymore.
You can also download .torrent files through DHT if you have a magnet link, which can be obtained
from various sources." `
	 @Logs | Format-Output @Logs

	# NOTE: We use any local port instead of LocalPort 1161,
	# but otherwise the rule overlaps with DHT rule
	New-NetFirewallRule -DisplayName "qbittorrent - part of full range of ports used most often" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 6881-6968, 6970-6999 `
		-LocalUser $UsersGroupSDDL `
		-InterfaceType $Interface `
		-LocalOnlyMapping $false -LooseSourceMapping $false `
		-Description "BitTorrent part of full range of ports used most often (Trackers)	" `
		@Logs | Format-Output @Logs

	New-NetFirewallRule -DisplayName "qbittorrent - NAT Port mapping protocol" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
		-LocalAddress Any -RemoteAddress DefaultGateway4 `
		-LocalPort Any -RemotePort 5351 `
		-LocalUser $UsersGroupSDDL `
		-InterfaceType $Interface `
		-LocalOnlyMapping $false -LooseSourceMapping $false `
		-Description "The NAT Port Mapping Protocol (NAT-PMP) is a network protocol for establishing
network address translation (NAT) settings and port forwarding configurations automatically without
user effort." `
	 @Logs | Format-Output @Logs

	# NOTE: We start from port 1024 which is most widely used, but some peers may set it to lower
	New-NetFirewallRule -DisplayName "qBittorrent - Client to peers" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 1024-65535 `
		-LocalUser $UsersGroupSDDL `
		-InterfaceType $Interface `
		-Description "Torrent client" `
		@Logs | Format-Output @Logs
}

Update-Logs
