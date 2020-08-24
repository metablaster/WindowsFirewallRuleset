
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
$Group = "Software - uTorrent"
$FirewallProfile = "Private, Public"

# User prompt
Update-Context "IPv$IPVersion" $Direction $Group @Logs
if (!(Approve-Execute @Logs)) { exit }

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore @Logs

#
# Steam installation directories
#
$uTorrentRoot = "%SystemDrive%\Users\User\AppData\Local\uTorrent"

#
# Rules for uTorrent client
#

# Test if installation exists on system
if ((Test-Installation "uTorrent" ([ref] $uTorrentRoot) @Logs) -or $ForceLoad)
{
	$Program = "$uTorrentRoot\uTorrent.exe"
	Test-File $Program @Logs

	# NOTE: We start from port 1024 which is most widely used, but some peers may set it to lower
	New-NetFirewallRule -Platform $Platform `
		-DisplayName "uTorrent - Client to peers" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $FirewallProfile -InterfaceType $Interface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 1024-65535 `
		-LocalUser $UsersGroupSDDL `
		-Description "Torrent client" @Logs | Format-Output @Logs

	New-NetFirewallRule -Platform $Platform `
		-DisplayName "uTorrent - DNS" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $FirewallProfile -InterfaceType $Interface `
		-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress DNS4, 208.67.222.222, 208.67.220.220 -LocalPort Any -RemotePort 53 `
		-LocalUser $UsersGroupSDDL -LocalOnlyMapping $false -LooseSourceMapping $false `
		-Description "Unknown why uTorrent needs DNS to OpenDNS, it also uses system DNS." @Logs | Format-Output @Logs

	New-NetFirewallRule -Platform $Platform `
		-DisplayName "uTorrent - NAT Port mapping protocol" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $FirewallProfile -InterfaceType $Interface `
		-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress DefaultGateway4 -LocalPort 5351 -RemotePort 5351 `
		-LocalUser $UsersGroupSDDL -LocalOnlyMapping $false -LooseSourceMapping $false `
		-Description "The NAT Port Mapping Protocol (NAT-PMP) is a network protocol for establishing network address translation (NAT) settings
	and port forwarding configurations automatically without user effort." @Logs | Format-Output @Logs

	New-NetFirewallRule -Platform $Platform `
		-DisplayName "uTorrent - part of full range of ports used most often" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $FirewallProfile -InterfaceType $Interface `
		-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 6881-6968, 6970-6999 `
		-LocalUser $UsersGroupSDDL -LocalOnlyMapping $false -LooseSourceMapping $false `
		-Description "BitTorrent part of full range of ports used most often (Trackers)	" @Logs | Format-Output @Logs

	# TODO: description doesn't seem ok? "All interface types for IPv6 to teredo"
	# NOTE: We start from port 1024 which is most widely used, but some peers may set it to lower
	New-NetFirewallRule -Platform $Platform `
		-DisplayName "uTorrent - DHT" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $FirewallProfile -InterfaceType $Interface `
		-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress Internet4 -LocalPort 1161 -RemotePort 1024-65535 `
		-LocalUser $UsersGroupSDDL -LocalOnlyMapping $false -LooseSourceMapping $false `
		-Description "DHT (Distributed Hash Table, technical explanation) is a decentralized network that uTorrent can use to find more peers without a tracker. What this means is that your client will be able to find peers even when the tracker is down, or doesn't even exist anymore.
	You can also download .torrent files through DHT if you have a magnet link, which can be obtained from various sources.
	All interface types for IPv6 to teredo" @Logs | Format-Output @Logs

	New-NetFirewallRule -Platform $Platform `
		-DisplayName "uTorrent - HTTP/HTTPS" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $FirewallProfile -InterfaceType $Interface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
		-LocalUser $UsersGroupSDDL `
		-Description "HTTP/HTTPS for browsing, adds and client content" @Logs | Format-Output @Logs

	New-NetFirewallRule -Platform $Platform `
		-DisplayName "uTorrent - Local Peer Discovery" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile Private -InterfaceType $Interface `
		-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress 224.0.0.0-239.255.255.255 -LocalPort 6771 -RemotePort 6771 `
		-LocalUser $UsersGroupSDDL -LocalOnlyMapping $false -LooseSourceMapping $false `
		-Description "UDP multicast search to identify other peers in your subnet that are also on torrents you are on." @Logs | Format-Output @Logs

	New-NetFirewallRule -Platform $Platform `
		-DisplayName "uTorrent - SSDP" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile Private -InterfaceType $Interface `
		-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress 239.255.255.250 -LocalPort Any -RemotePort 1900 `
		-LocalUser $UsersGroupSDDL -LocalOnlyMapping $false -LooseSourceMapping $false `
		-Description "" @Logs | Format-Output @Logs

	New-NetFirewallRule -Platform $Platform `
		-DisplayName "uTorrentie - WebHelper - HTTP" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $FirewallProfile -InterfaceType $Interface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80 `
		-LocalUser $UsersGroupSDDL `
		-Description "HTTP probably for adds and client content" @Logs | Format-Output @Logs
}

Update-Log
