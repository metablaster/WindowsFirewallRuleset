
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
$Group = "Internet Browser"
$Profile = "Private, Public"

# Chromecast IP
# Adjust to Chromecast IP in your local network
[IPAddress] $CHROMECAST_IP = "192.168.8.50"

# Ask user if he wants to load these rules
Update-Context "IPv$IPVersion" $Direction $Group @Logs
if (!(Approve-Execute @Logs)) { exit }

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore @Logs

#
# Browser installation directories
# TODO: update path for all users?
# TODO: returned path will miss browser updaters
#
$EdgeChromiumRoot = "%ProgramFiles(x86)%\Microsoft\Edge\Application"
$ChromeRoot = "%SystemDrive%\Users\User\AppData\Local\Google"
$FirefoxRoot = "%SystemDrive%\Users\User\AppData\Local\Mozilla Firefox"
$YandexRoot = "%SystemDrive%\Users\User\AppData\Local\Yandex"
$TorRoot = "%SystemDrive%\Users\User\AppData\Local\Tor Browser"

#
# Internet browser rules
#

#
# Microsoft Edge-Chromium
#

# Test if installation exists on system
if ((Test-Installation "EdgeChromium" ([ref] $EdgeChromiumRoot) @Logs) -or $ForceLoad)
{
	$EdgeChromiumApp = "$EdgeChromiumRoot\msedge.exe"
	Test-File $EdgeChromiumApp

	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Edge-Chromium HTTP" -Service Any -Program $EdgeChromiumApp `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80 `
	-LocalUser $UsersGroupSDDL `
	-Description "Hyper text transfer protocol." @Logs | Format-Output @Logs

	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Edge-Chromium HTTPS" -Service Any -Program $EdgeChromiumApp `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
	-LocalUser $UsersGroupSDDL `
	-Description "Hyper text transfer protocol over SSL." @Logs | Format-Output @Logs

	# TODO: we should probably have a function for this?
	$EdgeUpdateRoot = "$(Split-Path -Path $(Split-path -Path $EdgeChromiumRoot -Parent) -Parent)\EdgeUpdate"
	$EdgeChromiumUpdate = "$EdgeUpdateRoot\MicrosoftEdgeUpdate.exe"
	Test-File $EdgeChromiumUpdate

	$UpdateAccounts = Get-SDDL -Domain "NT AUTHORITY" -User "SYSTEM" @Logs
	Merge-SDDL ([ref] $UpdateAccounts) (Get-SDDL -Group "Users") @Logs

	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Edge-Chromium Update" -Service Any -Program $EdgeChromiumUpdate `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
	-LocalUser $UpdateAccounts `
	-Description "Update Microsoft Edge" @Logs | Format-Output @Logs
}

#
# Google Chrome
#

# Test if installation exists on system
if ((Test-Installation "Chrome" ([ref] $ChromeRoot) @Logs) -or $ForceLoad)
{
	$ChromeApp = "$ChromeRoot\Chrome\Application\chrome.exe"
	Test-File $ChromeApp

	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Chrome HTTP" -Service Any -Program $ChromeApp `
	-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80 `
	-LocalUser $UsersGroupSDDL `
	-Description "Hyper text transfer protocol." @Logs | Format-Output @Logs

	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Chrome HTTPS" -Service Any -Program $ChromeApp `
	-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
	-LocalUser $UsersGroupSDDL `
	-Description "Hyper text transfer protocol over SSL." @Logs | Format-Output @Logs

	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Chrome FTP" -Service Any -Program $ChromeApp `
	-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 21 `
	-LocalUser $UsersGroupSDDL `
	-Description "File transfer protocol." @Logs | Format-Output @Logs

	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Chrome GCM" -Service Any -Program $ChromeApp `
	-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 5228 `
	-LocalUser $UsersGroupSDDL `
	-Description "Google cloud messaging, google services use 5228, hangouts, google play, GCP.. etc use 5228." @Logs | Format-Output @Logs

	# TODO: removed port 80, probably not used
	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Chrome QUIC" -Service Any -Program $ChromeApp `
	-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
	-LocalUser $UsersGroupSDDL -LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Quick UDP Internet Connections,
	Experimental transport layer network protocol developed by Google and implemented in 2013." @Logs | Format-Output @Logs

	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Chrome XMPP" -Service Any -Program $ChromeApp `
	-PolicyStore $PolicyStore -Enabled False -Action Block -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 5222 `
	-LocalUser $UsersGroupSDDL `
	-Description "Extensible Messaging and Presence Protocol.
	Google Drive (Talk), Cloud printing, Chrome Remote Desktop, Chrome Sync (with fallback to 443 if 5222 is blocked)." @Logs | Format-Output @Logs

	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Chrome mDNS IPv4" -Service Any -Program $ChromeApp `
	-PolicyStore $PolicyStore -Enabled False -Action Block -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress 224.0.0.251 -LocalPort 5353 -RemotePort 5353 `
	-LocalUser $UsersGroupSDDL -LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "The multicast Domain Name System (mDNS) resolves host names to IP addresses within small networks that do not include a local name server." @Logs | Format-Output @Logs

	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Chrome mDNS IPv6" -Service Any -Program $ChromeApp `
	-PolicyStore $PolicyStore -Enabled False -Action Block -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress ff02::fb -LocalPort 5353 -RemotePort 5353 `
	-LocalUser $UsersGroupSDDL -LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "The multicast Domain Name System (mDNS) resolves host names to IP addresses within small networks that do not include a local name server." @Logs | Format-Output @Logs

	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Chrome Chromecast SSDP" -Service Any -Program $ChromeApp `
	-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress 239.255.255.250 -LocalPort Any -RemotePort 1900 `
	-LocalUser $UsersGroupSDDL -LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Network Discovery to allow use of the Simple Service Discovery Protocol." @Logs | Format-Output @Logs

	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Chrome Chromecast" -Service Any -Program $ChromeApp `
	-PolicyStore $PolicyStore -Enabled False -Action Block -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress $CHROMECAST_IP.IPAddressToString -LocalPort Any -RemotePort 8008, 8009 `
	-LocalUser $UsersGroupSDDL `
	-Description "Allow Chromecast outbound TCP data" @Logs | Format-Output @Logs

	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Chrome Chromecast" -Service Any -Program $ChromeApp `
	-PolicyStore $PolicyStore -Enabled False -Action Block -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress $CHROMECAST_IP.IPAddressToString -LocalPort 32768-61000 -RemotePort 32768-61000 `
	-LocalUser $UsersGroupSDDL -LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Allow Chromecast outbound UDP data" @Logs | Format-Output @Logs

	$ChromeUpdate = "$ChromeRoot\Update\GoogleUpdate.exe"

	Test-File $ChromeUpdate
	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Chrome Update" -Service Any -Program $ChromeUpdate `
	-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
	-LocalUser $UsersGroupSDDL `
	-Description "Update google products" @Logs | Format-Output @Logs
}

#
# Mozilla Firefox
#

# Test if installation exists on system
if ((Test-Installation "Firefox" ([ref] $FirefoxRoot) @Logs) -or $ForceLoad)
{
	$FirefoxApp = "$FirefoxRoot\firefox.exe"
	Test-File $FirefoxApp

	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Firefox HTTP" -Service Any -Program $FirefoxApp `
	-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80 `
	-LocalUser $UsersGroupSDDL `
	-Description "Hyper text transfer protocol." @Logs | Format-Output @Logs

	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Firefox HTTPS" -Service Any -Program $FirefoxApp `
	-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
	-LocalUser $UsersGroupSDDL `
	-Description "Hyper text transfer protocol over SSL." @Logs | Format-Output @Logs

	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Firefox FTP" -Service Any -Program $FirefoxApp `
	-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 21 `
	-LocalUser $UsersGroupSDDL `
	-Description "File transfer protocol." @Logs | Format-Output @Logs
}

#
# Yandex
#

# Test if installation exists on system
if ((Test-Installation "Yandex" ([ref] $YandexRoot) @Logs) -or $ForceLoad)
{
	$YandexApp = "$YandexRoot\YandexBrowser\Application\browser.exe"
	Test-File $YandexApp

	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Yandex HTTP" -Service Any -Program $YandexApp `
	-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80 `
	-LocalUser $UsersGroupSDDL `
	-Description "Hyper text transfer protocol." @Logs | Format-Output @Logs

	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Yandex HTTPS" -Service Any -Program $YandexApp `
	-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
	-LocalUser $UsersGroupSDDL `
	-Description "Hyper text transfer protocol over SSL." @Logs | Format-Output @Logs

	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Yandex FTP" -Service Any -Program $YandexApp `
	-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 21 `
	-LocalUser $UsersGroupSDDL `
	-Description "File transfer protocol." @Logs | Format-Output @Logs
}

#
# Tor
#

# Test if installation exists on system
# TODO: this will be true even if $false for both!
if ((Test-Installation "Tor" ([ref] $TorRoot) @Logs) -or $ForceLoad)
{
	$TorApp = "$TorRoot\Browser\TorBrowser\Tor\tor.exe"
	Test-File $TorApp

	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Tor HTTP" -Service Any -Program $TorApp `
	-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80 `
	-LocalUser $UsersGroupSDDL `
	-Description "Hyper text transfer protocol." @Logs | Format-Output @Logs

	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Tor HTTPS" -Service Any -Program $TorApp `
	-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
	-LocalUser $UsersGroupSDDL `
	-Description "Hyper text transfer protocol over SSL." @Logs | Format-Output @Logs

	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Tor DNS" -Service Any -Program $TorApp `
	-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 53 `
	-LocalUser $UsersGroupSDDL `
	-Description "DNS requests to exit relay over Tor network." @Logs | Format-Output @Logs

	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Tor Network" -Service Any -Program $TorApp `
	-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 9001, 9030, 9050, 9051, 9101, 9150 `
	-LocalUser $UsersGroupSDDL `
	-Description "Tor network specific ports" @Logs | Format-Output @Logs

	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Tor IMAP" -Service Any -Program $TorApp `
	-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 143 `
	-LocalUser $UsersGroupSDDL `
	-Description "" @Logs | Format-Output @Logs

	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Tor IMAP SSL/TLS" -Service Any -Program $TorApp `
	-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 993 `
	-LocalUser $UsersGroupSDDL `
	-Description "" @Logs | Format-Output @Logs

	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Tor POP3" -Service Any -Program $TorApp `
	-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 110 `
	-LocalUser $UsersGroupSDDL `
	-Description "" @Logs | Format-Output @Logs

	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Tor POP3 SSL/TLS" -Service Any -Program $TorApp `
	-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 995 `
	-LocalUser $UsersGroupSDDL `
	-Description "" @Logs | Format-Output @Logs

	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Tor SMTP" -Service Any -Program $TorApp `
	-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 25 `
	-LocalUser $UsersGroupSDDL `
	-Description "" @Logs | Format-Output @Logs

	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Tor SMTP SSL/TLS" -Service Any -Program $TorApp `
	-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 465 `
	-LocalUser $UsersGroupSDDL `
	-Description "" @Logs | Format-Output @Logs
}

Update-Logs
