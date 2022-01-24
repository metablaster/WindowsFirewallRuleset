
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
Inbound firewall rules for uTorrent

.DESCRIPTION
Inbound firewall rules for uTorrent torrent client

.PARAMETER Force
If specified, no prompt to run script is shown

.PARAMETER Trusted
If specified, rules will be loaded for executables with missing or invalid digital signature.
By default an error is generated and rule isn't loaded.

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
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\..\..\..\Config\ProjectSettings.ps1 $PSCmdlet
. $PSScriptRoot\..\DirectionSetup.ps1

Initialize-Project -Strict
Import-Module -Name Ruleset.UserInfo

# Setup local variables
$Group = "Software - uTorrent"
$Accept = "Inbound rules for uTorrent software will be loaded, recommended if uTorrent software is installed to let it access to network"
$Deny = "Skip operation, inbound rules for uTorrent software will not be loaded into firewall"

if (!(Approve-Execute -Accept $Accept -Deny $Deny -ContextLeaf $Group -Force:$Force)) { exit }
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
		New-NetFirewallRule -Platform $Platform `
			-DisplayName "uTorrent - DHT" -Service Any -Program $Program `
			-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
			-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress Any -LocalPort 1161 -RemotePort 1024-65535 `
			-EdgeTraversalPolicy DeferToApp -LocalUser $UsersGroupSDDL -LocalOnlyMapping $false -LooseSourceMapping $false `
			-Description "BitTorrent UDP listener, usually for DHT." | Format-RuleOutput

		New-NetFirewallRule -Platform $Platform `
			-DisplayName "uTorrent - Listening port" -Service Any -Program $Program `
			-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
			-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Any -LocalPort 1161 -RemotePort 1024-65535 `
			-EdgeTraversalPolicy DeferToApp -LocalUser $UsersGroupSDDL `
			-Description "BitTorrent TCP listener." | Format-RuleOutput

		New-NetFirewallRule -Platform $Platform `
			-DisplayName "uTorrent - Local Peer discovery" -Service Any -Program $Program `
			-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile Private -InterfaceType $DefaultInterface `
			-Direction $Direction -Protocol UDP -LocalAddress 224.0.0.0-239.255.255.255 -RemoteAddress LocalSubnet4 -LocalPort 6771 -RemotePort 6771 `
			-EdgeTraversalPolicy DeferToApp -LocalUser $UsersGroupSDDL -LocalOnlyMapping $false -LooseSourceMapping $false `
			-Description "UDP multicast search to identify other peers in your subnet that are also on torrents you are on." | Format-RuleOutput

		New-NetFirewallRule -Platform $Platform `
			-DisplayName "uTorrent - Web UI" -Service Any -Program $Program `
			-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
			-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Any -LocalPort 8080, 10000 -RemotePort Any `
			-EdgeTraversalPolicy Allow -LocalUser $UsersGroupSDDL `
			-Description "BitTorrent Remote control from browser." | Format-RuleOutput
	}
}

if ($UpdateGPO)
{
	Invoke-Process gpupdate.exe -NoNewWindow -ArgumentList "/target:computer"
}

Update-Log
