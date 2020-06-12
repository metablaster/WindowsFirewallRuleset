
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

. $PSScriptRoot\..\..\..\Config\ProjectSettings.ps1

# Check requirements for this project
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.System
Test-SystemRequirements

# Includes
. $PSScriptRoot\DirectionSetup.ps1
. $PSScriptRoot\..\IPSetup.ps1
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Logging
Import-Module -Name $ProjectRoot\Modules\Project.Windows.UserInfo @Logs
Import-Module -Name $ProjectRoot\Modules\Project.AllPlatforms.Utility @Logs

#
# Setup local variables:
#
$Group = "Basic Networking - IPv6"
$FirewallProfile = "Any"
$ISATAP_Remotes = @("Internet6", "LocalSubnet6")

# Ask user if he wants to load these rules
Update-Context "IPv$IPVersion" $Direction $Group @Logs
if (!(Approve-Execute @Logs)) { exit }

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore @Logs

#
# Predefined rules from Core Networking are here
#

#
# Loop back
# TODO: why specifying loopback address ::1/128 doesn't work?
# NOTE: IPv6 loopback rule does not work
# NOTE: even though we specify "IPv6 the loopback interface alias is the same for for IPv4 and IPv6,
# meaning there is only one loopback interface!"
# $Loopback = Get-NetIPInterface | Where-Object {
# 	$_.InterfaceAlias -like "*Loopback*" -and $_.AddressFamily -eq "IPv6"
# } | Select-Object -ExpandProperty InterfaceAlias


# New-NetFirewallRule -DisplayName "Loopback IP" `
# 	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
# 	-Service Any -Program Any -Group $Group `
# 	-Enabled True -Action Allow -Direction $Direction -Protocol Any `
# 	-LocalAddress Any -RemoteAddress Any `
# 	-LocalPort Any -RemotePort Any `
# 	-LocalUser Any `
#	-InterfaceType Any -InterfaceAlias $Loopback `
# 	-Description "This rule covers both IPv4 and IPv6 loopback interface.
# Network software and utilities use loopback address to access a local computer's TCP/IP network
# resources." `
# 	@Logs | Format-Output @Logs

#
# DNS (Domain Name System)
#

New-NetFirewallRule -DisplayName "Domain Name System" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Dnscache -Program $ServiceHost -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress DNS6 `
	-LocalPort Any -RemotePort 53 `
	-LocalUser Any `
	-InterfaceType $Interface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Rule to allow IPv6 DNS requests." `
	@Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Domain Name System" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress DefaultGateway6 `
	-LocalPort Any -RemotePort 53 `
	-LocalUser $NT_AUTHORITY_System `
	-InterfaceType $Interface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Rule to allow IPv6 DNS requests by System to default gateway." `
	@Logs | Format-Output @Logs

#
# mDNS (Multicast Domain Name System)
# NOTE: this should be placed in Multicast.ps1 like it is for IPv6, but it's here because of
# specific address, which is part of "Local Network Control Block" (224.0.0.0 - 224.0.0.255)
# An mDNS message is a multicast UDP packet sent using the following addressing:
# IPv4 address 224.0.0.251 or IPv6 address ff02::fb
# UDP port 5353
# https://en.wikipedia.org/wiki/Multicast_DNS
#

New-NetFirewallRule -DisplayName "Multicast Domain Name System" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private, Domain `
	-Service Dnscache -Program $ServiceHost -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress ff02::fb `
	-LocalPort 5353 -RemotePort 5353 `
	-LocalUser Any `
	-InterfaceType $Interface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "In computer networking, the multicast DNS (mDNS) protocol resolves hostnames to IP
addresses within small networks that do not include a local name server.
It is a zero-configuration service, using essentially the same programming interfaces,
packet formats and operating semantics as the unicast Domain Name System (DNS)." `
 @Logs | Format-Output @Logs

New-NetFirewallRule -DisplayName "Multicast Domain Name System" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Public `
	-Service Dnscache -Program $ServiceHost -Group $Group `
	-Enabled True -Action Block -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress ff02::fb `
	-LocalPort 5353 -RemotePort 5353 `
	-LocalUser Any `
	-InterfaceType $Interface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "In computer networking, the multicast DNS (mDNS) protocol resolves hostnames to IP
addresses within small networks that do not include a local name server.
It is a zero-configuration service, using essentially the same programming interfaces,
packet formats and operating semantics as the unicast Domain Name System (DNS)." `
 @Logs | Format-Output @Logs

#
# DHCP (Dynamic Host Configuration Protocol)
#

New-NetFirewallRule -DisplayName "Dynamic Host Configuration Protocol" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Dhcp -Program $ServiceHost -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress Any -RemoteAddress DHCP6 `
	-LocalPort 546 -RemotePort 547 `
	-LocalUser Any `
	-InterfaceType $Interface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Allows DHCPv6 messages for stateful auto-configuration." `
	@Logs | Format-Output @Logs

#
# IGMP (Internet Group Management Protocol)
#

# Multicast Listener Discovery (MLD) is a component of the Internet Protocol Version 6 (IPv6) suite.
# MLD is used by IPv6 routers for discovering multicast listeners on a directly attached link,
# much like Internet Group Management Protocol (IGMP) is used in IPv4.

#
# IPHTTPS (IPv6 over HTTPS)
#

New-NetFirewallRule -DisplayName "IPv6 over HTTPS" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
	-LocalAddress Any -RemoteAddress Internet6 `
	-LocalPort Any -RemotePort IPHTTPSout `
	-LocalUser $NT_AUTHORITY_System `
	-InterfaceType $Interface `
	-Description "Allow IPv6 IPHTTPS tunneling technology to provide connectivity across HTTP
proxies and firewalls." `
	@Logs | Format-Output @Logs

#
# IPv6 Encapsulation
#

New-NetFirewallRule -DisplayName "IPv6 Encapsulation" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
	-Service Any -Program System -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol 41 `
	-LocalAddress Any -RemoteAddress $ISATAP_Remotes `
	-LocalPort Any -RemotePort Any `
	-LocalUser $NT_AUTHORITY_System `
	-InterfaceType $Interface `
	-Description "Rule required to permit IPv6 traffic for
ISATAP (Intra-Site Automatic Tunnel Addressing Protocol) and 6to4 tunneling services." `
	@Logs | Format-Output @Logs

Update-Logs
