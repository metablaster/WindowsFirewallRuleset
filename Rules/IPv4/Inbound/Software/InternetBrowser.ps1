
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
Inbound firewall rules for InternetBrowser

.DESCRIPTION
Inbound firewall rules for 3rd party internet browsers

.PARAMETER Force
If specified, no prompt to run script is shown

.PARAMETER Trusted
If specified, rules will be loaded for executables with missing or invalid digital signature.
By default an error is generated and rule isn't loaded.

.EXAMPLE
PS> .\InternetBrowser.ps1

.INPUTS
None. You cannot pipe objects to InternetBrowser.ps1

.OUTPUTS
None. InternetBrowser.ps1 does not generate any output

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
$Group = "Internet Browser"

# Chromecast IP
# Adjust to the Chromecast IP in your local network
[IPAddress] $CHROMECAST_IP = "192.168.8.50"
$Accept = "Inbound rules for 3rd party internet browsers will be loaded, recommended if such browsers are installed to let them access to network"
$Deny = "Skip operation, inbound rules for internet browsers will not be loaded into firewall"

if (!(Approve-Execute -Accept $Accept -Deny $Deny -ContextLeaf $Group -Force:$Force)) { exit }
$PSDefaultParameterValues["Test-ExecutableFile:Force"] = $Trusted -or $SkipSignatureCheck
#endregion

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore

#
# Browser installation directories
#
$ChromeRoot = "%SystemDrive%\Users\$DefaultUser\AppData\Local\Google"

#
# Internet browser rules
#

#
# Google Chrome
#

# Test if installation exists on system
if ((Confirm-Installation "Chrome" ([ref] $ChromeRoot)) -or $ForceLoad)
{
	$Program = "$ChromeRoot\Chrome\Application\chrome.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "Google Chrome mDNS IPv4" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Block -Direction $Direction -Protocol UDP `
			-LocalAddress Any -RemoteAddress 224.0.0.251 `
			-LocalPort 5353 -RemotePort 5353 `
			-LocalUser $UsersGroupSDDL -EdgeTraversalPolicy Block `
			-InterfaceType $DefaultInterface `
			-LocalOnlyMapping $false -LooseSourceMapping $false `
			-Description "The multicast Domain Name System (mDNS) resolves host names to IP
addresses within small networks that do not include a local name server." |
		Format-RuleOutput

		New-NetFirewallRule -DisplayName "Google Chrome mDNS IPv6" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Block -Direction $Direction -Protocol UDP `
			-LocalAddress Any -RemoteAddress ff02::fb `
			-LocalPort 5353 -RemotePort 5353 `
			-LocalUser $UsersGroupSDDL -EdgeTraversalPolicy Block `
			-InterfaceType $DefaultInterface `
			-LocalOnlyMapping $false -LooseSourceMapping $false `
			-Description "The multicast Domain Name System (mDNS) resolves host names to IP
addresses within small networks that do not include a local name server." |
		Format-RuleOutput

		New-NetFirewallRule -DisplayName "Google Chrome Chromecast" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Block -Direction $Direction -Protocol UDP `
			-LocalAddress Any -RemoteAddress $CHROMECAST_IP.IPAddressToString `
			-LocalPort 32768-61000 -RemotePort 32768-61000 `
			-LocalUser $UsersGroupSDDL -EdgeTraversalPolicy Block `
			-InterfaceType $DefaultInterface `
			-LocalOnlyMapping $false -LooseSourceMapping $false `
			-Description "Allow Chromecast Inbound UDP data" |
		Format-RuleOutput

		New-NetFirewallRule -DisplayName "Chrome QUIC" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort 443 -RemotePort Any `
			-LocalUser $UsersGroupSDDL -EdgeTraversalPolicy Block `
			-InterfaceType $DefaultInterface `
			-LocalOnlyMapping $false -LooseSourceMapping $false `
			-Description "Quick UDP Internet Connections,
	Experimental transport layer network protocol developed by Google and implemented in 2013." |
		Format-RuleOutput
	}
}

if ($UpdateGPO)
{
	Invoke-Process gpupdate.exe -NoNewWindow -ArgumentList "/target:computer"
}

Update-Log
