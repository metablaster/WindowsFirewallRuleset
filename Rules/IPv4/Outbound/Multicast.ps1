
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

<# http://www.iana.org/assignments/multicast-addresses/multicast-addresses.xhtml
Address Range                 Size       Designation
-------------                 ----       -----------
224.0.0.0 - 224.0.0.255       (/24)      Local Network Control Block
224.0.1.0 - 224.0.1.255       (/24)      Internetwork Control Block
224.0.2.0 - 224.0.255.255     (65024)    AD-HOC Block I
224.1.0.0 - 224.1.255.255     (/16)      RESERVED
224.2.0.0 - 224.2.255.255     (/16)      SDP/SAP Block
224.3.0.0 - 224.4.255.255     (2 /16s)   AD-HOC Block II
224.5.0.0 - 224.255.255.255   (251 /16s) RESERVED
224.252.0.0 - 224.255.255.255 (/14)      DIS Transient Groups
225.0.0.0 - 231.255.255.255   (7 /8s)    RESERVED
232.0.0.0 - 232.255.255.255   (/8)       Source-Specific Multicast Block
233.0.0.0 - 233.251.255.255   (16515072) GLOP Block
233.252.0.0 - 233.255.255.255 (/14)      AD-HOC Block III
234.0.0.0 - 234.255.255.255     ()       Unicast-Prefix-based IPv4 Multicast Addresses
235.0.0.0 - 238.255.255.255   ()         Scoped Multicast Ranges (RESERVED)
239.0.0.0 - 239.255.255.255   (/8)       Scoped Multicast Ranges (Organization-Local Scope) aka Administratively Scoped Block.
#>

. $PSScriptRoot\..\..\..\Config\ProjectSettings.ps1

# Check requirements for this project
Import-Module -Name $RepoDir\Modules\Project.AllPlatforms.System
Test-SystemRequirements

# Includes
. $PSScriptRoot\DirectionSetup.ps1
. $PSScriptRoot\..\IPSetup.ps1
Import-Module -Name $RepoDir\Modules\Project.Windows.UserInfo
Import-Module -Name $RepoDir\Modules\Project.AllPlatforms.Logging
Import-Module -Name $RepoDir\Modules\Project.AllPlatforms.Utility

#
# Setup local variables:
#
$Group = "Multicast IPv4"
$Profile = "Private, Domain"
$MulticastUsers = Get-AccountSDDL @("NT AUTHORITY\NETWORK SERVICE", "NT AUTHORITY\LOCAL SERVICE")

# Ask user if he wants to load these rules
Update-Context "IPv$IPVersion" $Direction $Group
if (!(Approve-Execute)) { exit }

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction SilentlyContinue

#
# IPv4 Multicast Address Space
# NOTE: Boot time multicast dropped due to WFP Operation (Windows Filtering Platform),
# The transition from boot-time to persistent filters could be several seconds, or even longer on a slow machine.
#

New-NetFirewallRule -Platform $Platform `
-DisplayName "Local Network Control Block" -Service Any -Program Any `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress 224.0.0.0-224.0.0.255 `
-LocalUser $MulticastUsers -LocalOnlyMapping $false -LooseSourceMapping $false `
-Description "Addresses in the Local Network Control Block are used for protocol control traffic that is not forwarded off link.
Examples of this type of use include OSPFIGP All Routers (224.0.0.5)." | Format-Output

New-NetFirewallRule -Platform $Platform `
-DisplayName "Internetwork Control Block" -Service Any -Program Any `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress 224.0.1.0-224.0.1.255 `
-LocalUser $MulticastUsers -LocalOnlyMapping $false -LooseSourceMapping $false `
-Description "Addresses in the Internetwork Control Block are used for protocol
control traffic that MAY be forwarded through the Internet.  Examples
include 224.0.1.1 (Network Time Protocol (NTP)) and 224.0.1.68 (mdhcpdiscover)." | Format-Output

New-NetFirewallRule -Platform $Platform `
-DisplayName "AD-HOC Block I" -Service Any -Program Any `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress 224.0.2.0-224.0.255.255 `
-LocalUser $MulticastUsers -LocalOnlyMapping $false -LooseSourceMapping $false `
-Description "Addresses in the AD-HOC blocks were
traditionally used for assignments for those applications that don't fit in either the Local or Internetwork Control blocks.
These addresses MAY be globally routed and are typically used by applications that require small blocks of addressing (e.g., less than a /24 ).
Future assignments of blocks of addresses that do not fit in the Local Network or Internetwork Control blocks
will be made in AD-HOC Block III." | Format-Output

New-NetFirewallRule -Platform $Platform `
-DisplayName "SDP/SAP Block" -Service Any -Program Any `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress 224.2.0.0-224.2.255.255 `
-LocalUser $MulticastUsers -LocalOnlyMapping $false -LooseSourceMapping $false `
-Description "Addresses in the SDP/SAP Block are used by applications that receive addresses through the Session Announcement Protocol
for use via applications like the session directory tool (such as [SDR])." | Format-Output

New-NetFirewallRule -Platform $Platform `
-DisplayName "AD-HOC Block II" -Service Any -Program Any `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress 224.3.0.0-224.4.255.255 `
-LocalUser $MulticastUsers -LocalOnlyMapping $false -LooseSourceMapping $false `
-Description "Addresses in the AD-HOC blocks were
traditionally used for assignments for those applications that don't fit in either the Local or Internetwork Control blocks.
These addresses MAY be globally routed and are typically used by applications that require small blocks of addressing (e.g., less than a /24 ).
Future assignments of blocks of addresses that do not fit in the Local Network or Internetwork Control blocks
will be made in AD-HOC Block III." | Format-Output

New-NetFirewallRule -Platform $Platform `
-DisplayName "DIS Transient Groups" -Service Any -Program Any `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress 224.252.0.0-224.255.255.255 `
-LocalUser $MulticastUsers -LocalOnlyMapping $false -LooseSourceMapping $false `
-Description "The statically assigned link-local scope is 224.0.0.0/24." | Format-Output

New-NetFirewallRule -Platform $Platform `
-DisplayName "Source-Specific Multicast Block" -Service Any -Program Any `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress 232.0.0.0-232.255.255.255 `
-LocalUser $MulticastUsers -LocalOnlyMapping $false -LooseSourceMapping $false `
-Description "SSM is an extension of IP Multicast in which traffic is forwarded to receivers from only those multicast sources for which
the receivers have explicitly expressed interest and is primarily targeted at one-to-many (broadcast) applications.
Note that this block was initially assigned to the Versatile Message Transaction Protocol (VMTP) transient groups [IANA]." | Format-Output

New-NetFirewallRule -Platform $Platform `
-DisplayName "GLOP Block" -Service Any -Program Any `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress 233.0.0.0-233.251.255.255 `
-LocalUser $MulticastUsers -LocalOnlyMapping $false -LooseSourceMapping $false `
-Description "Addresses in the GLOP Block are globally-scoped, statically-assigned addresses.
The assignment is made, for a domain with a 16-bit Autonomous System Number (ASN), by mapping a domain's autonomous system number,
expressed in octets as X.Y, into the middle two octets of the GLOP Block, yielding an assignment of 233.X.Y.0/24.
The mapping and assignment is defined in [RFC3180].
Domains with a 32-bit ASN MAY apply for space in AD-HOC Block III, or consider using IPv6 multicast addresses." | Format-Output

New-NetFirewallRule -Platform $Platform `
-DisplayName "AD-HOC Block III" -Service Any -Program Any `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress 233.252.0.0-233.255.255.255 `
-LocalUser $MulticastUsers -LocalOnlyMapping $false -LooseSourceMapping $false `
-Description "[RFC3138] delegated to the RIRs the assignment of the GLOP sub-block mapped by the private Autonomous
System (AS) space (64512-65534) and the IANA reserved ASN 65535.
This space was known as Extended GLOP (EGLOP).
RFC 3138 should not have asked the RIRs to develop policies for the EGLOP space because [RFC2860] reserves that to the IETF.
It is important to make this space available for use by network operators,
and it is therefore appropriate to obsolete RFC 3138 and classify this address range as available for AD-HOC assignment." | Format-Output

New-NetFirewallRule -Platform $Platform `
-DisplayName "Unicast-Prefix-based IPv4 Multicast Addresses" -Service Any -Program Any `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress 234.0.0.0-234.255.255.255 `
-LocalUser $MulticastUsers -LocalOnlyMapping $false -LooseSourceMapping $false `
-Description "This specification defines an extension to the multicast addressing architecture of the IP Version 4 protocol.
The extension presented in this document allows for unicast-prefix-based assignment of multicast addresses.
By delegating multicast addresses at the same time as unicast prefixes, network operators will be able to identify
their multicast addresses without needing to run an inter-domain allocation protocol." | Format-Output

New-NetFirewallRule -Platform $Platform `
-DisplayName "Administratively Scoped Block" -Service Any -Program Any `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress 239.0.0.0-239.255.255.255 `
-LocalUser $MulticastUsers -LocalOnlyMapping $false -LooseSourceMapping $false `
-Description "Addresses in the Administratively Scoped Block are for local use within a domain." | Format-Output
