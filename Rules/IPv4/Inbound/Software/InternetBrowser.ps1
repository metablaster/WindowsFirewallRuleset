
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
$FirewallProfile = "Private, Public"

# Chromecast IP
# Adjust to the Chromecast IP in your local network
[IPAddress] $CHROMECAST_IP = "192.168.8.50"

# Ask user if he wants to load these rules
Update-Context "IPv$IPVersion" $Direction $Group @Logs
if (!(Approve-Execute @Logs)) { exit }

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore @Logs

#
# Browser installation directories
#
$ChromeRoot = "%SystemDrive%\Users\User\AppData\Local\Google"

#
# Internet browser rules
#

#
# Google Chrome
#

# Test if installation exists on system
if ((Test-Installation "Chrome" ([ref] $ChromeRoot) @Logs) -or $ForceLoad)
{
	$ChromeApp = "$ChromeRoot\Chrome\Application\chrome.exe"
	Test-File $ChromeApp

	New-NetFirewallRule -Platform $Platform `
		-DisplayName "Google Chrome mDNS IPv4" -Service Any -Program $ChromeApp `
		-PolicyStore $PolicyStore -Enabled False -Action Block -Group $Group -Profile $FirewallProfile -InterfaceType $Interface `
		-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress 224.0.0.251 -LocalPort 5353 -RemotePort 5353 `
		-EdgeTraversalPolicy Block -LocalUser $UsersGroupSDDL -LocalOnlyMapping $false -LooseSourceMapping $false `
		-Description "The multicast Domain Name System (mDNS) resolves host names to IP addresses within small networks that do not include a local name server." @Logs | Format-Output @Logs

	New-NetFirewallRule -Platform $Platform `
		-DisplayName "Google Chrome mDNS IPv6" -Service Any -Program $ChromeApp `
		-PolicyStore $PolicyStore -Enabled False -Action Block -Group $Group -Profile $FirewallProfile -InterfaceType $Interface `
		-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress ff02::fb -LocalPort 5353 -RemotePort 5353 `
		-EdgeTraversalPolicy Block -LocalUser $UsersGroupSDDL -LocalOnlyMapping $false -LooseSourceMapping $false `
		-Description "The multicast Domain Name System (mDNS) resolves host names to IP addresses within small networks that do not include a local name server." @Logs | Format-Output @Logs

	New-NetFirewallRule -Platform $Platform `
		-DisplayName "Google Chrome Chromecast" -Service Any -Program $ChromeApp `
		-PolicyStore $PolicyStore -Enabled False -Action Block -Group $Group -Profile $FirewallProfile -InterfaceType $Interface `
		-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress $CHROMECAST_IP.IPAddressToString -LocalPort 32768-61000 -RemotePort 32768-61000 `
		-EdgeTraversalPolicy Block -LocalUser $UsersGroupSDDL -LocalOnlyMapping $false -LooseSourceMapping $false `
		-Description "Allow Chromecast Inbound UDP data" @Logs | Format-Output @Logs

	New-NetFirewallRule -Platform $Platform `
		-DisplayName "Chrome QUIC" -Service Any -Program $ChromeApp `
		-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $FirewallProfile -InterfaceType $Interface `
		-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress Internet4 -LocalPort 443 -RemotePort Any `
		-EdgeTraversalPolicy Block -LocalUser $UsersGroupSDDL -LocalOnlyMapping $false -LooseSourceMapping $false `
		-Description "Quick UDP Internet Connections,
	Experimental transport layer network protocol developed by Google and implemented in 2013." @Logs | Format-Output @Logs
}

Update-Logs
