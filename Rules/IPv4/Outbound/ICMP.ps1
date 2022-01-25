
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
Outbound firewall rules for ICMPv4 traffic

.DESCRIPTION
Outbound firewall rules for ICMPv4 traffic

.PARAMETER Trusted
If specified, rules will be loaded for executables with missing or invalid digital signature.
By default an error is generated and rule isn't loaded.

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\ICMP.ps1

.INPUTS
None. You cannot pipe objects to ICMP.ps1

.OUTPUTS
None. ICMP.ps1 does not generate any output

.NOTES
Make sure to check for updated content!
https://tools.ietf.org/html/rfc1918
https://www.iana.org/assignments/icmp-parameters/icmp-parameters.xhtml
https://en.wikipedia.org/wiki/Internet_Control_Message_Protocol
https://tools.ietf.org/html/rfc4861

Deprecated, year 2019:
4 Source Quench
6 Alternate Host Address
5 Information Request
16 Information Reply
17 Address Mask Request
18 Address Mask Reply
30 Traceroute
31 to 39

TODO: we don't use rules for APIPA or local subnet ranges
If a network client fails to get an IP address using DHCP, it can discover an address on its own
using APIPA.
To get an IPv4 address, the client will select an address at random in the range
169.254.1.0 to 169.254.254.255 (inclusive), with a netmask of 255.255.0.0.
The client will then send an ARP packet asking for the MAC address that corresponds to the
randomly-generated IPv4 address.

If any other machine is using that address, the client will generate another random address and
try again.

The entire address range 169.254.0.0/16 has been set aside for "link local" addresses
(the first and last 256 addresses have been reserved for future use).
They should not be manually assigned or assigned using DHCP.
NOTE: APIPA is how Microsoft refers to Link-Local
ex. $APIPA = "169.254.1.0-169.254.254.255"
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
. $PSScriptRoot\..\..\..\Config\ProjectSettings.ps1 $PSCmdlet
. $PSScriptRoot\DirectionSetup.ps1

Initialize-Project -Strict
Import-Module -Name Ruleset.UserInfo

# Setup local variables
$Group = "ICMPv4"
$Program = "System"
$RemoteAddrWAN = "Any"
$RemoteAddrLAN = "LocalSubnet4"
$Accept = "Outbound rules for ICMPv4 will be loaded, recommended for proper network functioning"
$Deny = "Skip operation, outbound ICMPv4 rules will not be loaded into firewall"

if (!(Approve-Execute -Accept $Accept -Deny $Deny -ContextLeaf $Group -Force:$Force)) { exit }
$PSDefaultParameterValues["Test-ExecutableFile:Force"] = $Trusted -or $SkipSignatureCheck
#endregion

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore

#
# ICMP type filtering for All profiles
#

# TODO: Echo request description is same as for echo reply
New-NetFirewallRule -DisplayName "Echo Request (8)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Any `
	-Service Any -Program $Program -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol ICMPv4 -IcmpType 8 `
	-LocalAddress Any -RemoteAddress Any `
	-LocalPort Any -RemotePort Any `
	-LocalUser $LocalSystem `
	-InterfaceType $DefaultInterface `
	-Description "The data received in the echo message must be returned in the echo reply message.
The identifier and sequence number may be used by the echo sender to aid in matching the replies
with the echo requests.
For example, the identifier might be used like a port in TCP or UDP to identify a session,
and the sequence number might be incremented on each echo request sent.
The echoer returns these same values in the echo reply.

IP Fields:
Addresses
The address of the source in an echo message will be the
destination of the echo reply message.
To form an echo reply message, the source and destination addresses are simply reversed,
the type code changed to 0, and the checksum recomputed.

Code:
0
Code 0 may be received from a gateway or a host." |
Format-RuleOutput

New-NetFirewallRule -DisplayName "Timestamp (13)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Any `
	-Service Any -Program $Program -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol ICMPv4 -IcmpType 13 `
	-LocalAddress Any -RemoteAddress Any `
	-LocalPort Any -RemotePort Any `
	-LocalUser $LocalSystem `
	-InterfaceType $DefaultInterface `
	-Description "The data received (a timestamp) in the message is returned in the reply together
with an additional timestamp.
The timestamp is 32 bits of milliseconds since midnight UT.
One use of these timestamps is described by Mills.

The Originate Timestamp is the time the sender last touched the message before sending it,
the Receive Timestamp is the time the echoer first touched it on receipt,
and the Transmit Timestamp is the time the echoer last touched the message on sending it.

If the time is not available in milliseconds or cannot be provided with respect to midnight UT then
any time can be inserted in a timestamp provided the high order bit of the timestamp is also set to
indicate this non-standard value.

IP Fields:
Addresses
The address of the source in a timestamp message will be the
destination of the timestamp reply message.
To form a timestamp reply message, the source and destination addresses are simply
reversed, the type code changed to 14, and the checksum recomputed.

Code:
0 = pointer indicates the error.
Code 0 may be received from a gateway or a host." |
Format-RuleOutput

New-NetFirewallRule -DisplayName "Router Advertisement (9)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Any `
	-Service Any -Program $Program -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol ICMPv4 -IcmpType 9 `
	-LocalAddress Any -RemoteAddress $RemoteAddrLAN `
	-LocalPort Any -RemotePort Any `
	-LocalUser $LocalSystem `
	-InterfaceType $DefaultInterface `
	-Description "the ICMP Internet Router Discovery Protocol (IRDP), also called the
Internet Router Discovery Protocol, is a protocol for computer hosts to discover the presence and
location of routers on their IPv4 local area network.
Router discovery is useful for accessing computer systems on other nonlocal area networks.

A host MUST NOT send Router Advertisement messages at any time.
A router sends periodic as well as solicited Router Advertisements out its advertising interfaces.
A router might want to send Router Advertisements without advertising itself as a default router.
For instance, a router might advertise prefixes for stateless address autoconfiguration while not
wishing to forward packets.
Unsolicited Router Advertisements are not strictly periodic:
the interval between subsequent transmissions is randomized to reduce the probability of
synchronization with the advertisements from other routers on the same link." |
Format-RuleOutput

# TODO: figure out if redirects can be unsolicited, to set up EdgeTraversalPolicy
# (currently allowing by logic of comments)
New-NetFirewallRule -DisplayName "Redirect (5)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Any `
	-Service Any -Program $Program -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol ICMPv4 -IcmpType 5 `
	-LocalAddress Any -RemoteAddress $RemoteAddrLAN `
	-LocalPort Any -RemotePort Any `
	-LocalUser $LocalSystem `
	-InterfaceType $DefaultInterface `
	-Description "ICMP redirect messages are used by routers to notify the hosts on the data link
that a better route is available for a particular destination.
The gateway sends a redirect message to a host in the following situation.
A gateway, G1, receives an internet datagram from a host on a network to which the gateway is
attached.
The gateway, G1, checks its routing table and obtains the address of the next gateway, G2,
on the route to the datagram's internet destination network, X.
If G2 and the host identified by the internet source address of the datagram are on the same
network, a redirect message is sent to the host.
The redirect message advises the host to send its traffic for network X directly to gateway G2 as
this is a shorter path to the destination.
The gateway forwards the original datagram's data to its internet destination.

IP Fields:
Destination Address
The source network and address of the original datagram's data.

Code:
0 = Redirect datagrams for the Network.
1 = Redirect datagrams for the Host.
2 = Redirect datagrams for the Type of Service and Network.
3 = Redirect datagrams for the Type of Service and Host.
Codes 0, 1, 2, and 3 may be received from a gateway." |
Format-RuleOutput

#
# ICMP type filtering for public profile
#

New-NetFirewallRule -DisplayName "Echo Reply (0)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Public `
	-Service Any -Program $Program -Group $Group `
	-Enabled True -Action Block -Direction $Direction -Protocol ICMPv4 -IcmpType 0 `
	-LocalAddress Any -RemoteAddress $RemoteAddrWAN `
	-LocalPort Any -RemotePort Any `
	-LocalUser $LocalSystem `
	-InterfaceType $DefaultInterface `
	-Description "The data received in the echo message must be returned in the echo reply message.
The identifier and sequence number may be used by the echo sender to aid in matching the replies
with the echo requests.
For example, the identifier might be used like a port in TCP or UDP to identify a session,
and the sequence number might be incremented on each echo request sent.
The echoer returns these same values in the echo reply.

IP Fields:
Addresses
The address of the source in an echo message will be the
destination of the echo reply message.
To form an echo reply message, the source and destination addresses are simply reversed,
the type code changed to 0, and the checksum recomputed.

Code:
0
Code 0 may be received from a gateway or a host." |
Format-RuleOutput

New-NetFirewallRule -DisplayName "Destination Unreachable (3)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Public `
	-Service Any -Program $Program -Group $Group `
	-Enabled True -Action Block -Direction $Direction -Protocol ICMPv4 -IcmpType 3 `
	-LocalAddress Any -RemoteAddress $RemoteAddrWAN `
	-LocalPort Any -RemotePort Any `
	-LocalUser $LocalSystem `
	-InterfaceType $DefaultInterface `
	-Description "network specified in the RemoteAddress is unreachable, ie,
the distance to the network is infinity, the gateway may send a destination unreachable message
to the internet source host of the datagram.

IP Fields:
Destination Address
The source network and address from the original datagram's data.

Code:
0 = net unreachable;
1 = host unreachable;
2 = protocol unreachable;
3 = port unreachable;
4 = fragmentation needed and DF set;
5 = source route failed.
Codes 0, 1, 4, and 5 may be received from a gateway.
Codes 2 and 3 may be received from a host." |
Format-RuleOutput

New-NetFirewallRule -DisplayName "Router Solicitation (10)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Public `
	-Service Any -Program $Program -Group $Group `
	-Enabled True -Action Block -Direction $Direction -Protocol ICMPv4 -IcmpType 10 `
	-LocalAddress Any -RemoteAddress $RemoteAddrLAN `
	-LocalPort Any -RemotePort Any `
	-LocalUser $LocalSystem `
	-InterfaceType $DefaultInterface `
	-Description "the ICMP Internet Router Discovery Protocol (IRDP), also called the
Internet Router Discovery Protocol, is a protocol for computer hosts to discover the presence and
location of routers on their IPv4 local area network.
Router discovery is useful for accessing computer systems on other nonlocal area networks.

Sending Router Solicitations:
When an interface becomes enabled, a host may be unwilling to wait for the next unsolicited Router
Advertisement to locate default routers or learn prefixes.
To obtain Router Advertisements quickly, a host SHOULD transmit up to MAX_RTR_SOLICITATIONS
Router Solicitation messages, each separated by at least RTR_SOLICITATION_INTERVAL seconds." |
Format-RuleOutput

New-NetFirewallRule -DisplayName "Time Exceeded (11)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Public `
	-Service Any -Program $Program -Group $Group `
	-Enabled True -Action Block -Direction $Direction -Protocol ICMPv4 -IcmpType 11 `
	-LocalAddress Any -RemoteAddress $RemoteAddrWAN `
	-LocalPort Any -RemotePort Any `
	-LocalUser $LocalSystem `
	-InterfaceType $DefaultInterface `
	-Description "If the gateway processing a datagram finds the time to live field is zero it must
discard the datagram.
The gateway may also notify the source host via the time exceeded message.
If a host reassembling a fragmented datagram cannot complete the reassembly due to missing
fragments within its time limit it discards the datagram, and it may send a time exceeded message.
If fragment zero is not available then no time exceeded need be sent at all.

IP Fields:
Destination Address
The source network and address from the original datagram's data.

Code:
0 = time to live exceeded in transit;
1 = fragment reassembly time exceeded.
Code 0 may be received from a gateway.
Code 1 may be received from a host." |
Format-RuleOutput

New-NetFirewallRule -DisplayName "Parameter Problem (12)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Public `
	-Service Any -Program $Program -Group $Group `
	-Enabled True -Action Block -Direction $Direction -Protocol ICMPv4 -IcmpType 12 `
	-LocalAddress Any -RemoteAddress $RemoteAddrWAN `
	-LocalPort Any -RemotePort Any `
	-LocalUser $LocalSystem `
	-InterfaceType $DefaultInterface `
	-Description "If the gateway or host processing a datagram finds a problem with the header
parameters such that it cannot complete processing the datagram it must discard the datagram.
One potential source of such a problem is with incorrect arguments in an option.
The gateway or host may also notify the source host via the parameter problem message.
This message is only sent if the error caused the datagram to be discarded.

IP Fields:
Destination Address
The source network and address from the original datagram's data.

Code:
0 = pointer indicates the error.
Code 0 may be received from a gateway or a host." |
Format-RuleOutput

New-NetFirewallRule -DisplayName "Timestamp Reply (14)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Public `
	-Service Any -Program $Program -Group $Group `
	-Enabled True -Action Block -Direction $Direction -Protocol ICMPv4 -IcmpType 14 `
	-LocalAddress Any -RemoteAddress $RemoteAddrWAN `
	-LocalPort Any -RemotePort Any `
	-LocalUser $LocalSystem `
	-InterfaceType $DefaultInterface `
	-Description "The data received (a timestamp) in the message is returned in the reply together
with an additional timestamp.
The timestamp is 32 bits of milliseconds since midnight UT.
One use of these timestamps is described by Mills.

The Originate Timestamp is the time the sender last touched the message before sending it,
the Receive Timestamp is the time the echoer first touched it on receipt,
and the Transmit Timestamp is the time the echoer last touched the message on sending it.

If the time is not available in milliseconds or cannot be provided with respect to midnight UT
then any time can be inserted in a timestamp provided the high order bit of the timestamp is also
set to indicate this non-standard value.

IP Fields:
Addresses
The address of the source in a timestamp message will be the
destination of the timestamp reply message.
To form a timestamp reply message, the source and destination addresses are simply
reversed, the type code changed to 14, and the checksum recomputed.

Code:
0 = pointer indicates the error.
Code 0 may be received from a gateway or a host." |
Format-RuleOutput

#
# ICMP type filtering for private and domain profile
#

New-NetFirewallRule -DisplayName "Echo Reply (0)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private, Domain `
	-Service Any -Program $Program -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol ICMPv4 -IcmpType 0 `
	-LocalAddress Any -RemoteAddress $RemoteAddrLAN `
	-LocalPort Any -RemotePort Any `
	-LocalUser $LocalSystem `
	-InterfaceType $DefaultInterface `
	-Description "The data received in the echo message must be returned in the echo reply message.
The identifier and sequence number may be used by the echo sender to aid in matching the replies
with the echo requests.
For example, the identifier might be used like a port in TCP or UDP to identify a session,
and the sequence number might be incremented on each echo request sent.
The echoer returns these same values in the echo reply.

IP Fields:
Addresses
The address of the source in an echo message will be the
destination of the echo reply message.
To form an echo reply message, the source and destination addresses are simply reversed,
the type code changed to 0, and the checksum recomputed.

Code:
0
Code 0 may be received from a gateway or a host." |
Format-RuleOutput

New-NetFirewallRule -DisplayName "Destination Unreachable (3)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private, Domain `
	-Service Any -Program $Program -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol ICMPv4 -IcmpType 3 `
	-LocalAddress Any -RemoteAddress $RemoteAddrLAN `
	-LocalPort Any -RemotePort Any `
	-LocalUser $LocalSystem `
	-InterfaceType $DefaultInterface `
	-Description "network specified in the RemoteAddress is unreachable, ie,
the distance to the network is infinity, the gateway may send a destination unreachable message to
the internet source host of the datagram.

IP Fields:
Destination Address
The source network and address from the original datagram's data.

Code:
0 = net unreachable;
1 = host unreachable;
2 = protocol unreachable;
3 = port unreachable;
4 = fragmentation needed and DF set;
5 = source route failed.
Codes 0, 1, 4, and 5 may be received from a gateway.
Codes 2 and 3 may be received from a host." |
Format-RuleOutput

New-NetFirewallRule -DisplayName "Router Solicitation (10)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private, Domain `
	-Service Any -Program $Program -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol ICMPv4 -IcmpType 10 `
	-LocalAddress Any -RemoteAddress $RemoteAddrLAN `
	-LocalPort Any -RemotePort Any `
	-LocalUser $LocalSystem `
	-InterfaceType $DefaultInterface `
	-Description "the ICMP Internet Router Discovery Protocol (IRDP), also called the
Internet Router Discovery Protocol, is a protocol for computer hosts to discover the presence and
location of routers on their IPv4 local area network.
Router discovery is useful for accessing computer systems on other nonlocal area networks.

Sending Router Solicitations:
When an interface becomes enabled, a host may be unwilling to wait for the next unsolicited Router
Advertisement to locate default routers or learn prefixes.
To obtain Router Advertisements quickly, a host SHOULD transmit up to MAX_RTR_SOLICITATIONS
Router Solicitation messages, each separated by at least RTR_SOLICITATION_INTERVAL seconds." |
Format-RuleOutput

New-NetFirewallRule -DisplayName "Time Exceeded (11)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private, Domain `
	-Service Any -Program $Program -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol ICMPv4 -IcmpType 11 `
	-LocalAddress Any -RemoteAddress $RemoteAddrLAN `
	-LocalPort Any -RemotePort Any `
	-LocalUser $LocalSystem `
	-InterfaceType $DefaultInterface `
	-Description "If the gateway processing a datagram finds the time to live field is zero it
must discard the datagram.
The gateway may also notify the source host via the time exceeded message.
If a host reassembling a fragmented datagram cannot complete the reassembly due to missing
fragments within its time limit it discards the datagram,
and it may send a time exceeded message.
If fragment zero is not available then no time exceeded need be sent at all.

IP Fields:
Destination Address
The source network and address from the original datagram's data.

Code:
0 = time to live exceeded in transit;
1 = fragment reassembly time exceeded.
Code 0 may be received from a gateway.
Code 1 may be received from a host." |
Format-RuleOutput

New-NetFirewallRule -DisplayName "Parameter Problem (12)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private, Domain `
	-Service Any -Program $Program -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol ICMPv4 -IcmpType 12 `
	-LocalAddress Any -RemoteAddress $RemoteAddrLAN `
	-LocalPort Any -RemotePort Any `
	-LocalUser $LocalSystem `
	-InterfaceType $DefaultInterface `
	-Description "If the gateway or host processing a datagram finds a problem with the header
parameters such that it cannot complete processing the
datagram it must discard the datagram. One potential source of such a problem is with incorrect
arguments in an option.
The gateway or host may also notify the source host via the parameter problem message.
This message is only sent if the error caused the datagram to be discarded.

IP Fields:
Destination Address
The source network and address from the original datagram's data.

Code:
0 = pointer indicates the error.
Code 0 may be received from a gateway or a host." |
Format-RuleOutput

New-NetFirewallRule -DisplayName "Timestamp Reply (14)" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile Private, Domain `
	-Service Any -Program $Program -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol ICMPv4 -IcmpType 14 `
	-LocalAddress Any -RemoteAddress $RemoteAddrLAN `
	-LocalPort Any -RemotePort Any `
	-LocalUser $LocalSystem `
	-InterfaceType $DefaultInterface `
	-Description "The data received (a timestamp) in the message is returned in the reply together
with an additional timestamp.
The timestamp is 32 bits of milliseconds since midnight UT.
One use of these timestamps is described by Mills.

The Originate Timestamp is the time the sender last touched the message before sending it,
the Receive Timestamp is the time the echoer first touched it on receipt,
and the Transmit Timestamp is the time the echoer last touched the message on sending it.

If the time is not available in milliseconds or cannot be provided with respect to midnight UT
then any time can be inserted in a timestamp provided the high order bit of the timestamp is also
set to indicate this non-standard value.

IP Fields:
Addresses
The address of the source in a timestamp message will be the
destination of the timestamp reply message.
To form a timestamp reply message, the source and destination addresses are simply
reversed, the type code changed to 14, and the checksum recomputed.

Code:
0 = pointer indicates the error.
Code 0 may be received from a gateway or a host." |
Format-RuleOutput

if ($UpdateGPO)
{
	Invoke-Process gpupdate.exe -NoNewWindow -ArgumentList "/target:computer"
}

Update-Log
