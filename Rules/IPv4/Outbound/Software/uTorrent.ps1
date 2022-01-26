
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
Outbound firewall rules for uTorrent

.DESCRIPTION
Outbound firewall rules for uTorrent torrent client

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
PS> .\uTorrent.ps1

.INPUTS
None. You cannot pipe objects to uTorrent.ps1

.OUTPUTS
None. uTorrent.ps1 does not generate any output

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
$Group = "Software - uTorrent"
$Accept = "Outbound rules for uTorrent software will be loaded, recommended if uTorrent software is installed to let it access to network"
$Deny = "Skip operation, outbound rules for uTorrent software will not be loaded into firewall"

if (!(Approve-Execute -Accept $Accept -Deny $Deny -ContextLeaf $Group -Force:$Force)) { exit }
$PSDefaultParameterValues["Confirm-Installation:Quiet"] = $Quiet
$PSDefaultParameterValues["Confirm-Installation:Interactive"] = $Interactive
$PSDefaultParameterValues["Test-ExecutableFile:Quiet"] = $Quiet
$PSDefaultParameterValues["Test-ExecutableFile:Force"] = $Trusted -or $SkipSignatureCheck
#endregion

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore

#
# Steam installation directories
#
$uTorrentRoot = "%SystemDrive%\Users\$DefaultUser\AppData\Local\uTorrent"

#
# Rules for uTorrent client
#

# Test if installation exists on system
if ((Confirm-Installation "uTorrent" ([ref] $uTorrentRoot)) -or $ForceLoad)
{
	$Program = "$uTorrentRoot\uTorrent.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		# NOTE: We start from port 1024 which is most widely used, but some peers may set it to lower
		New-NetFirewallRule -DisplayName "uTorrent - Client to peers" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 1024-65535 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "Torrent client" | Format-RuleOutput

		New-NetFirewallRule -DisplayName "uTorrent - DNS" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
			-LocalAddress Any -RemoteAddress DNS4, 208.67.222.222, 208.67.220.220 `
			-LocalPort Any -RemotePort 53 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-LocalOnlyMapping $false -LooseSourceMapping $false `
			-Description "Unknown why uTorrent needs DNS to OpenDNS, it also uses system DNS." |
		Format-RuleOutput

		New-NetFirewallRule -DisplayName "uTorrent - NAT Port mapping protocol" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
			-LocalAddress Any -RemoteAddress DefaultGateway4 `
			-LocalPort 5351 -RemotePort 5351 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-LocalOnlyMapping $false -LooseSourceMapping $false `
			-Description "The NAT Port Mapping Protocol (NAT-PMP) is a network protocol for
establishing network address translation (NAT) settings and port forwarding configurations
automatically without user effort." | Format-RuleOutput

		New-NetFirewallRule -DisplayName "uTorrent - part of full range of ports used most often" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 6881-6968, 6970-6999 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-LocalOnlyMapping $false -LooseSourceMapping $false `
			-Description "BitTorrent part of full range of ports used most often (Trackers)	" |
		Format-RuleOutput

		# TODO: description doesn't seem ok? "All interface types for IPv6 to teredo"
		# NOTE: We start from port 1024 which is most widely used, but some peers may set it to lower
		New-NetFirewallRule -DisplayName "uTorrent - DHT" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort 1161 -RemotePort 1024-65535 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-LocalOnlyMapping $false -LooseSourceMapping $false `
			-Description "DHT (Distributed Hash Table, technical explanation) is a decentralized
network that uTorrent can use to find more peers without a tracker. What this means is that your
client will be able to find peers even when the tracker is down, or doesn't even exist anymore.
You can also download .torrent files through DHT if you have a magnet link, which can be obtained
from various sources. All interface types for IPv6 to teredo" | Format-RuleOutput

		New-NetFirewallRule -DisplayName "uTorrent - HTTP/HTTPS" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 80, 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "HTTP/HTTPS for browsing, adds and client content" | Format-RuleOutput

		New-NetFirewallRule -DisplayName "uTorrent - Local Peer Discovery" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile Private `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
			-LocalAddress Any -RemoteAddress 224.0.0.0-239.255.255.255 `
			-LocalPort 6771 -RemotePort 6771 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-LocalOnlyMapping $false -LooseSourceMapping $false `
			-Description "UDP multicast search to identify other peers in your subnet that
are also on torrents you are on." | Format-RuleOutput

		New-NetFirewallRule -DisplayName "uTorrent - SSDP" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile Private `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
			-LocalAddress Any -RemoteAddress 239.255.255.250 `
			-LocalPort Any -RemotePort 1900 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-LocalOnlyMapping $false -LooseSourceMapping $false `
			-Description "" | Format-RuleOutput

		New-NetFirewallRule -DisplayName "uTorrentie - WebHelper - HTTP" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 80 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "HTTP probably for adds and client content" | Format-RuleOutput
	}
}

if ($UpdateGPO)
{
	Invoke-Process gpupdate.exe -NoNewWindow -ArgumentList "/target:computer"
}

Update-Log
