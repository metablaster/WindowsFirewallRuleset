
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
Outbound firewall rules for InternetBrowser

.DESCRIPTION
Outbound firewall rules for 3rd party internet browsers

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
$Group = "Internet Browser"
$Accept = "Outbound rules for 3rd party internet browsers will be loaded, recommended if such browsers are installed to let them access to network"
$Deny = "Skip operation, outbound rules for internet browsers will not be loaded into firewall"

# Chromecast IP
# Adjust to Chromecast IP in your local network
[IPAddress] $CHROMECAST_IP = "192.168.8.50"

if (!(Approve-Execute -Accept $Accept -Deny $Deny -ContextLeaf $Group -Force:$Force)) { exit }
$PSDefaultParameterValues = @{
	"Confirm-Installation:Quiet" = $Quiet
	"Confirm-Installation:Interactive" = $Interactive
	"Confirm-Installation:Session" = $SessionInstance
	"Confirm-Installation:CimSession" = $CimServer
	"Test-ExecutableFile:Quiet" = $Quiet
	"Test-ExecutableFile:Force" = $Trusted -or $SkipSignatureCheck
	"Test-ExecutableFile:Session" = $SessionInstance
}
#endregion

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore

#
# Browser installation directories
# TODO: update path for all users?
# TODO: returned path will miss browser updaters
#
$ChromeRoot = "%SystemDrive%\Users\$DefaultUser\AppData\Local\Google"
$FirefoxRoot = "%SystemDrive%\Users\$DefaultUser\AppData\Local\Mozilla Firefox"
$YandexRoot = "%SystemDrive%\Users\$DefaultUser\AppData\Local\Yandex"
$TorRoot = "%SystemDrive%\Users\$DefaultUser\AppData\Local\Tor Browser"

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
		New-NetFirewallRule -DisplayName "Chrome HTTP" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 80 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "Hyper text transfer protocol." | Format-RuleOutput

		New-NetFirewallRule -DisplayName "Chrome HTTPS" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "Hyper text transfer protocol over SSL." | Format-RuleOutput

		New-NetFirewallRule -DisplayName "Chrome FTP" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 21 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "File transfer protocol." | Format-RuleOutput

		New-NetFirewallRule -DisplayName "Chrome GCM" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 5228 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "Google cloud messaging, google services use 5228, hangouts, google play,
GCP.. etc use 5228." | Format-RuleOutput

		# TODO: removed port 80, probably not used
		New-NetFirewallRule -DisplayName "Chrome QUIC" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-LocalOnlyMapping $false -LooseSourceMapping $false `
			-Description "Quick UDP Internet Connections,
Experimental transport layer network protocol developed by Google and implemented in 2013." | Format-RuleOutput

		New-NetFirewallRule -DisplayName "Chrome XMPP" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Block -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 5222 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "Extensible Messaging and Presence Protocol.
Google Drive (Talk), Cloud printing, Chrome Remote Desktop, Chrome Sync
(with fallback to 443 if 5222 is blocked)." | Format-RuleOutput

		New-NetFirewallRule -DisplayName "Chrome mDNS IPv4" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Block -Direction $Direction -Protocol UDP `
			-LocalAddress Any -RemoteAddress 224.0.0.251 `
			-LocalPort 5353 -RemotePort 5353 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-LocalOnlyMapping $false -LooseSourceMapping $false `
			-Description "The multicast Domain Name System (mDNS) resolves host names to IP addresses
within small networks that do not include a local name server." | Format-RuleOutput

		New-NetFirewallRule -DisplayName "Chrome mDNS IPv6" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Block -Direction $Direction -Protocol UDP `
			-LocalAddress Any -RemoteAddress ff02::fb `
			-LocalPort 5353 -RemotePort 5353 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-LocalOnlyMapping $false -LooseSourceMapping $false `
			-Description "The multicast Domain Name System (mDNS) resolves host names to IP addresses
within small networks that do not include a local name server." | Format-RuleOutput

		New-NetFirewallRule -DisplayName "Chrome Chromecast SSDP" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
			-LocalAddress Any -RemoteAddress 239.255.255.250 `
			-LocalPort Any -RemotePort 1900 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-LocalOnlyMapping $false -LooseSourceMapping $false `
			-Description "Network Discovery to allow use of the Simple Service Discovery Protocol." |
		Format-RuleOutput

		New-NetFirewallRule -DisplayName "Chrome Chromecast" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Block -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress $CHROMECAST_IP.IPAddressToString `
			-LocalPort Any -RemotePort 8008, 8009 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "Allow Chromecast outbound TCP data" | Format-RuleOutput

		New-NetFirewallRule -DisplayName "Chrome Chromecast" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Block -Direction $Direction -Protocol UDP `
			-LocalAddress Any -RemoteAddress $CHROMECAST_IP.IPAddressToString `
			-LocalPort 32768-61000 -RemotePort 32768-61000 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-LocalOnlyMapping $false -LooseSourceMapping $false `
			-Description "Allow Chromecast outbound UDP data" | Format-RuleOutput
	}

	$Program = "$ChromeRoot\Update\GoogleUpdate.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "Chrome Update" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 80, 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "Update google products" | Format-RuleOutput
	}
}

#
# Mozilla Firefox
#

# Test if installation exists on system
if ((Confirm-Installation "Firefox" ([ref] $FirefoxRoot)) -or $ForceLoad)
{
	$Program = "$FirefoxRoot\firefox.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "Firefox HTTP" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 80 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "Hyper text transfer protocol." | Format-RuleOutput

		New-NetFirewallRule -DisplayName "Firefox HTTPS" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "Hyper text transfer protocol over SSL." | Format-RuleOutput

		New-NetFirewallRule -DisplayName "Firefox FTP" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 21 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "File transfer protocol." | Format-RuleOutput
	}

	$Program = "$FirefoxRoot\pingsender.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "Firefox Telemetry" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "Pingsender ensures shutdown telemetry data is sent to mozilla after shutdown,
instead of waiting next firefox start which could take hours, days or even more." |
		Format-RuleOutput
	}
}

#
# Yandex
#

# Test if installation exists on system
if ((Confirm-Installation "Yandex" ([ref] $YandexRoot)) -or $ForceLoad)
{
	$Program = "$YandexRoot\YandexBrowser\Application\browser.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "Yandex HTTP" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 80 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "Hyper text transfer protocol." | Format-RuleOutput

		New-NetFirewallRule -DisplayName "Yandex HTTPS" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "Hyper text transfer protocol over SSL." | Format-RuleOutput

		New-NetFirewallRule -DisplayName "Yandex FTP" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 21 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "File transfer protocol." | Format-RuleOutput
	}
}

#
# Tor
#

# Test if installation exists on system
# TODO: this will be true even if $false for both!
if ((Confirm-Installation "Tor" ([ref] $TorRoot)) -or $ForceLoad)
{
	$Program = "$TorRoot\Browser\TorBrowser\Tor\tor.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "Tor HTTP" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 80 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "Hyper text transfer protocol." | Format-RuleOutput

		New-NetFirewallRule -DisplayName "Tor HTTPS" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 443 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "Hyper text transfer protocol over SSL." | Format-RuleOutput

		New-NetFirewallRule -DisplayName "Tor DNS" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 53 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "DNS requests to exit relay over Tor network." | Format-RuleOutput

		# OLD: -RemotePort 9001, 9030, 9050, 9051, 9101, 9150
		New-NetFirewallRule -DisplayName "Tor Network" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 8080, 8443, 9001-9003, 9010, 9101 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "Tor network specific ports" | Format-RuleOutput

		New-NetFirewallRule -DisplayName "Tor IMAP" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 143 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "" | Format-RuleOutput

		New-NetFirewallRule -DisplayName "Tor IMAP SSL/TLS" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 993 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "" | Format-RuleOutput

		New-NetFirewallRule -DisplayName "Tor POP3" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 110 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "" | Format-RuleOutput

		New-NetFirewallRule -DisplayName "Tor POP3 SSL/TLS" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 995 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "" | Format-RuleOutput

		New-NetFirewallRule -DisplayName "Tor SMTP" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 25 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "" | Format-RuleOutput

		New-NetFirewallRule -DisplayName "Tor SMTP SSL/TLS" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Internet4 `
			-LocalPort Any -RemotePort 465 `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "" | Format-RuleOutput
	}
}

if ($UpdateGPO)
{
	Invoke-Process gpupdate.exe -NoNewWindow -ArgumentList "/target:computer"
}

Update-Log
