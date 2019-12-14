
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

#
# Import global variables
#
. "$PSScriptRoot\..\..\Modules\GlobalVariables.ps1"

#
# Setup local variables:
#
$Group = "Multicast IPv4"
$Profile = "Private, Domain" #Boot time multicast dropped due to WFP Operation (The transition from boot-time to persistent filters could be several seconds, or even longer on a slow machine.)
$Interface = "Wired, Wireless"

#First remove all existing rules matching setup
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction Inbound -ErrorAction SilentlyContinue

#
# ICMP type filtering for All profiles
#
New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Local Network Control Block" -Service Any -Program Any `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Inbound -Protocol UDP -LocalAddress 224.0.0.0-224.0.0.255 -RemoteAddress Any `
-EdgeTraversalPolicy Block -LocalUser $NT_AUTHORITY_LOCALSERVICE `
-Description "Addresses in the Local Network Control Block are used for protocol control traffic that is not forwarded off link.
Examples of this type of use include OSPFIGP All Routers (224.0.0.5)."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Internetwork Control Block" -Service Any -Program Any `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Inbound -Protocol UDP -LocalAddress 224.0.1.0-224.0.1.255 -RemoteAddress Any `
-EdgeTraversalPolicy Block -LocalUser $NT_AUTHORITY_LOCALSERVICE `
-Description "Addresses in the Internetwork Control Block are used for protocol
control traffic that MAY be forwarded through the Internet.  Examples
include 224.0.1.1 (Network Time Protocol (NTP)) and 224.0.1.68 (mdhcpdiscover)."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "AD-HOC Block I" -Service Any -Program Any `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Inbound -Protocol UDP -LocalAddress 224.0.2.0-224.0.255.255 -RemoteAddress Any `
-EdgeTraversalPolicy Block -LocalUser $NT_AUTHORITY_LOCALSERVICE `
-Description "Addresses in the AD-HOC blocks were
traditionally used for assignments for those applications that don't fit in either the Local or Internetwork Control blocks.
These addresses MAY be globally routed and are typically used by applications that require small blocks of addressing (e.g., less than a /24 ).
Future assignments of blocks of addresses that do not fit in the Local Network or Internetwork Control blocks
will be made in AD-HOC Block III."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "SDP/SAP Block" -Service Any -Program Any `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Inbound -Protocol UDP -LocalAddress 224.2.0.0-224.2.255.255 -RemoteAddress Any `
-EdgeTraversalPolicy Block -LocalUser $NT_AUTHORITY_LOCALSERVICE `
-Description "Addresses in the SDP/SAP Block are used by applications that receive addresses through the Session Announcement Protocol
for use via applications like the session directory tool (such as [SDR])."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "AD-HOC Block II" -Service Any -Program Any `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Inbound -Protocol UDP -LocalAddress 224.3.0.0-224.4.255.255 -RemoteAddress Any `
-EdgeTraversalPolicy Block -LocalUser $NT_AUTHORITY_LOCALSERVICE `
-Description "Addresses in the AD-HOC blocks were
traditionally used for assignments for those applications that don't fit in either the Local or Internetwork Control blocks.
These addresses MAY be globally routed and are typically used by applications that require small blocks of addressing (e.g., less than a /24 ).
Future assignments of blocks of addresses that do not fit in the Local Network or Internetwork Control blocks
will be made in AD-HOC Block III."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "DIS Transient Groups" -Service Any -Program Any `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Inbound -Protocol UDP -LocalAddress 224.252.0.0-224.255.255.255 -RemoteAddress Any `
-EdgeTraversalPolicy Block -LocalUser $NT_AUTHORITY_LOCALSERVICE `
-Description "The statically assigned link-local scope is 224.0.0.0/24."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Source-Specific Multicast Block" -Service Any -Program Any `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Inbound -Protocol UDP -LocalAddress 232.0.0.0-232.255.255.255 -RemoteAddress Any `
-EdgeTraversalPolicy Block -LocalUser $NT_AUTHORITY_LOCALSERVICE `
-Description "SSM is an extension of IP Multicast in which traffic is forwarded to receivers from only those multicast sources for which
the receivers have explicitly expressed interest and is primarily targeted at one-to-many (broadcast) applications.
Note that this block was initially assigned to the Versatile Message Transaction Protocol (VMTP) transient groups [IANA]."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "GLOP Block" -Service Any -Program Any `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Inbound -Protocol UDP -LocalAddress 233.0.0.0-233.251.255.255 -RemoteAddress Any `
-EdgeTraversalPolicy Block -LocalUser $NT_AUTHORITY_LOCALSERVICE `
-Description "Addresses in the GLOP Block are globally-scoped, statically-assigned addresses.
The assignment is made, for a domain with a 16-bit Autonomous System Number (ASN), by mapping a domain's autonomous system number,
expressed in octets as X.Y, into the middle two octets of the GLOP Block, yielding an assignment of 233.X.Y.0/24.
The mapping and assignment is defined in [RFC3180].
Domains with a 32-bit ASN MAY apply for space in AD-HOC Block III, or consider using IPv6 multicast addresses."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "AD-HOC Block III" -Service Any -Program Any `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Inbound -Protocol UDP -LocalAddress 233.252.0.0-233.255.255.255 -RemoteAddress Any `
-EdgeTraversalPolicy Block -LocalUser $NT_AUTHORITY_LOCALSERVICE `
-Description "[RFC3138] delegated to the RIRs the assignment of the GLOP sub-block mapped by the private Autonomous
System (AS) space (64512-65534) and the IANA reserved ASN 65535.
This space was known as Extended GLOP (EGLOP).
RFC 3138 should not have asked the RIRs to develop policies for the EGLOP space because [RFC2860] reserves that to the IETF.
It is important to make this space available for use by network operators,
and it is therefore appropriate to obsolete RFC 3138 and classify this address range as available for AD-HOC assignment."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Unicast-Prefix-based IPv4 Multicast Addresses" -Service Any -Program Any `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Inbound -Protocol UDP -LocalAddress 234.0.0.0-234.255.255.255 -RemoteAddress Any `
-EdgeTraversalPolicy Block -LocalUser $NT_AUTHORITY_LOCALSERVICE `
-Description "This specification defines an extension to the multicast addressing architecture of the IP Version 4 protocol.
The extension presented in this document allows for unicast-prefix-based assignment of multicast addresses.
By delegating multicast addresses at the same time as unicast prefixes, network operators will be able to identify
their multicast addresses without needing to run an inter-domain allocation protocol."

New-NetFirewallRule -Confirm:$Execute -Whatif:$Debug -ErrorAction $OnError -Platform $Platform `
-DisplayName "Administratively Scoped Block" -Service Any -Program Any `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Inbound -Protocol UDP -LocalAddress 239.0.0.0-239.255.255.255 -RemoteAddress Any `
-EdgeTraversalPolicy Block -LocalUser $NT_AUTHORITY_LOCALSERVICE `
-Description "Addresses in the Administratively Scoped Block are for local use within a domain."
