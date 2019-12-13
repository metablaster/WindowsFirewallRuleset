
# Make sure to check for updated content!
# http://tools.ietf.org/html/rfc1918
# http://www.iana.org/assignments/icmp-parameters/icmp-parameters.xhtml
# https://en.wikipedia.org/wiki/Internet_Control_Message_Protocol
# https://tools.ietf.org/html/rfc4861

# Deprecated, year 2019:
# 4 Source Quench
# 6	Alternate Host Address
# 5 Information Request
# 16 Information Reply
# 17 Address Mask Request
# 18 Address Mask Reply
# 30 Traceroute
# 31 to 39

#setup variables:
$PolicyStore = "localhost" #local group policy
$Platform = "10.0+" #Windows 10 and above
$NT_AUTHORITY_SYSTEM = "D:(A;;CC;;;S-1-5-18)"
$Group = "ICMPv4"
$Program = "System"
$Profile = "Public"
$Interface = "Wired, Wireless"
$Description = "Internet Control Message Protocol version 4"
$RemoteAddr = "Internet4"
$APIPA = "169.254.1.0-169.254.254.255"
$OnError = "Stop"
$Deubg = $false


#First remove all existing rules matching setup
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction Inbound -ErrorAction SilentlyContinue

#
# Destination filtering
#
New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "ICMP Local Subnet" -Service Any -Program $Program `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile Private, Domain -InterfaceType $Interface `
-Direction Inbound -Protocol ICMPv4 -IcmpType Any -LocalAddress Any -RemoteAddress LocalSubnet4 `
-EdgeTraversalPolicy Block -LocalUser $NT_AUTHORITY_SYSTEM -Description $Description

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "ICMP Subnet APIPA" -Service Any -Program $Program `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile Private, Domain -InterfaceType $Interface `
-Direction Inbound -Protocol ICMPv4 -IcmpType Any -LocalAddress Any -RemoteAddress $APIPA `
-EdgeTraversalPolicy Block -LocalUser $NT_AUTHORITY_SYSTEM -Description $Description

#
# Type filtering
#
New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Echo Request" -Service Any -Program $Program `
-PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Inbound -Protocol ICMPv4 -IcmpType 8 -LocalAddress Any -RemoteAddress $RemoteAddr `
-EdgeTraversalPolicy Allow -LocalUser $NT_AUTHORITY_SYSTEM `
-Description "The data received in the echo message must be returned in the echo reply message.
The identifier and sequence number may be used by the echo sender to aid in matching the replies with the echo requests.
For example, the identifier might be used like a port in TCP or UDP to identify a session,
and the sequence number might be incremented on each echo request sent.
The echoer returns these same values in the echo reply.

IP Fields:
Addresses
The address of the source in an echo message will be the destination of the echo reply message.
To form an echo reply message, the source and destination addresses are simply reversed,
the type code changed to 0, and the checksum recomputed.

Code:
0
Code 0 may be received from a gateway or a host."

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Echo Reply" -Service Any -Program $Program `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Inbound -Protocol ICMPv4 -IcmpType 0 -LocalAddress Any -RemoteAddress $RemoteAddr `
-EdgeTraversalPolicy Block -LocalUser $NT_AUTHORITY_SYSTEM `
-Description "The data received in the echo message must be returned in the echo reply message.
The identifier and sequence number may be used by the echo sender to aid in matching the replies with the echo requests.
For example, the identifier might be used like a port in TCP or UDP to identify a session,
and the sequence number might be incremented on each echo request sent.
The echoer returns these same values in the echo reply.

IP Fields:
Addresses
The address of the source in an echo message will be the destination of the echo reply message.
To form an echo reply message, the source and destination addresses are simply reversed,
the type code changed to 0, and the checksum recomputed.

Code:
0
Code 0 may be received from a gateway or a host."

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Destination Unreachable" -Service Any -Program $Program `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Inbound -Protocol ICMPv4 -IcmpType 3 -LocalAddress Any -RemoteAddress $RemoteAddr `
-EdgeTraversalPolicy Block -LocalUser $NT_AUTHORITY_SYSTEM `
-Description "network specified in the RemoteAddress is unreachable, ie,
the distance to the network is infinity, the gateway may send a destination unreachable message to the internet source host of the datagram.

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
Codes 2 and 3 may be received from a host."

<# Edge Traversal comment for redirect:
There are certain cases where ICMP packets can be used to attack a network. Although this type of problem is not common today,
there are situations where such problems do happen. This is the case with ICMP redirect,
or ICMP Type 5 packet. ICMP redirects are used by routers to specify better routing paths out of one network,
based on the host choice, so basically it affects the way packets are routed and destinations.

Through ICMP redirects, a host can find out which networks can be accessed from within the local network,
and which are the routers to be used for each such network. The security problem comes from the fact that ICMP packets,
including ICMP redirect, are extremely easy to fake and basically it would be rather easy for an attacker to forge ICMP redirect packets.
The atacker can then on basically alter your host's routing tables and diver traffic towards external hosts on a path of his/her choice;

the new path is kept active by the router for 10 minutes.
Due to this fact and the security risks involved in such scenario,
it is still a recommended practice to disable ICMP redirect messages (ignore them) from all public interfaces.
#>
# TODO: figure out if redirects can be unsolicited, to set up EdgeTraversalPolicy (currently allowing by logic of comments)
New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Redirect" -Service Any -Program $Program `
-PolicyStore $PolicyStore -Enabled False -Action Block -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Inbound -Protocol ICMPv4 -IcmpType 5 -LocalAddress Any -RemoteAddress $RemoteAddr `
-EdgeTraversalPolicy Allow -LocalUser $NT_AUTHORITY_SYSTEM `
-Description "ICMP redirect messages are used by routers to notify the hosts on the data link that a better route is available for a particular destination.
The gateway sends a redirect message to a host in the following situation.
A gateway, G1, receives an internet datagram from a host on a network to which the gateway is attached.
The gateway, G1, checks its routing table and obtains the address of the next gateway, G2,
on the route to the datagram's internet destination network, X.
If G2 and the host identified by the internet source address of the datagram are on the same network,
a redirect message is sent to the host.
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
Codes 0, 1, 2, and 3 may be received from a gateway."

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Router Advertisement" -Service Any -Program $Program `
-PolicyStore $PolicyStore -Enabled False -Action Block -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Inbound -Protocol ICMPv4 -IcmpType 9 -LocalAddress Any -RemoteAddress $RemoteAddr `
-EdgeTraversalPolicy Allow -LocalUser $NT_AUTHORITY_SYSTEM `
-Description "the ICMP Internet Router Discovery Protocol (IRDP), also called the Internet Router Discovery Protocol,
is a protocol for computer hosts to discover the presence and location of routers on their IPv4 local area network.
Router discovery is useful for accessing computer systems on other nonlocal area networks.

A host MUST NOT send Router Advertisement messages at any time.
A router sends periodic as well as solicited Router Advertisements out its advertising interfaces.
A router might want to send Router Advertisements without advertising itself as a default router.
For instance, a router might advertise prefixes for stateless address autoconfiguration while not wishing to forward p ackets.
Unsolicited Router Advertisements are not strictly periodic:
the interval between subsequent transmissions is randomized to reduce the probability of synchronization with the advertisements from other routers on the same link."

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Router Solicitation" -Service Any -Program $Program `
-PolicyStore $PolicyStore -Enabled False -Action Block -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Inbound -Protocol ICMPv4 -IcmpType 10 -LocalAddress Any -RemoteAddress $RemoteAddr `
-EdgeTraversalPolicy Allow -LocalUser $NT_AUTHORITY_SYSTEM `
-Description "the ICMP Internet Router Discovery Protocol (IRDP), also called the Internet Router Discovery Protocol,
is a protocol for computer hosts to discover the presence and location of routers on their IPv4 local area network.
Router discovery is useful for accessing computer systems on other nonlocal area networks.

Sending Router Solicitations:
When an interface becomes enabled, a host may be unwilling to wait for the next unsolicited Router Advertisement
to locate default routers or learn prefixes.
To obtain Router Advertisements quickly, a host SHOULD transmit up to MAX_RTR_SOLICITATIONS Router Solicitation messages,
each separated by at least RTR_SOLICITATION_INTERVAL seconds."

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Time Exceeded" -Service Any -Program $Program `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Inbound -Protocol ICMPv4 -IcmpType 11 -LocalAddress Any -RemoteAddress $RemoteAddr `
-EdgeTraversalPolicy Block -LocalUser $NT_AUTHORITY_SYSTEM `
-Description "If the gateway processing a datagram finds the time to live field is zero it must discard the datagram.
The gateway may also notify the source host via the time exceeded message.
If a host reassembling a fragmented datagram cannot complete the reassembly due to missing fragments within its time limit it discards the datagram,
and it may send a time exceeded message.
If fragment zero is not available then no time exceeded need be sent at all.

IP Fields:
Destination Address
The source network and address from the original datagram's data.

Code:
0 = time to live exceeded in transit;
1 = fragment reassembly time exceeded.
Code 0 may be received from a gateway.
Code 1 may be received from a host."

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Parameter Problem" -Service Any -Program $Program `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Inbound -Protocol ICMPv4 -IcmpType 12 -LocalAddress Any -RemoteAddress $RemoteAddr `
-EdgeTraversalPolicy Block -LocalUser $NT_AUTHORITY_SYSTEM `
-Description "If the gateway or host processing a datagram finds a problem with the header parameters such that it cannot complete processing the
datagram it must discard the datagram.  One potential source of such a problem is with incorrect arguments in an option.
The gateway or host may also notify the source host via the parameter problem message.
This message is only sent if the error caused the datagram to be discarded.

IP Fields:
Destination Address
The source network and address from the original datagram's data.

Code:
0 = pointer indicates the error.
Code 0 may be received from a gateway or a host."

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Timestamp" -Service Any -Program $Program `
-PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Inbound -Protocol ICMPv4 -IcmpType 13 -LocalAddress Any -RemoteAddress $RemoteAddr `
-EdgeTraversalPolicy Allow -LocalUser $NT_AUTHORITY_SYSTEM `
-Description "The data received (a timestamp) in the message is returned in the reply together with an additional timestamp.
The timestamp is 32 bits of milliseconds since midnight UT.
One use of these timestamps is described by Mills.

The Originate Timestamp is the time the sender last touched the message before sending it,
the Receive Timestamp is the time the echoer first touched it on receipt, and the Transmit Timestamp is
the time the echoer last touched the message on sending it.

If the time is not available in miliseconds or cannot be provided with respect to midnight UT then any time can be inserted in a
timestamp provided the high order bit of the timestamp is also set to indicate this non-standard value.

IP Fields:
Addresses
The address of the source in a timestamp message will be the
destination of the timestamp reply message.
To form a timestamp reply message, the source and destination addresses are simply
reversed, the type code changed to 14, and the checksum recomputed.

Code:
0 = pointer indicates the error.
Code 0 may be received from a gateway or a host."

New-NetFirewallRule -Whatif:$Deubg -ErrorAction $OnError -Platform $Platform `
-DisplayName "Timestamp Reply" -Service Any -Program $Program `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction Inbound -Protocol ICMPv4 -IcmpType 14 -LocalAddress Any -RemoteAddress $RemoteAddr `
-EdgeTraversalPolicy Block -LocalUser $NT_AUTHORITY_SYSTEM `
-Description "The data received (a timestamp) in the message is returned in the reply together with an additional timestamp.
The timestamp is 32 bits of milliseconds since midnight UT.
One use of these timestamps is described by Mills.

The Originate Timestamp is the time the sender last touched the message before sending it,
the Receive Timestamp is the time the echoer first touched it on receipt, and the Transmit Timestamp is
the time the echoer last touched the message on sending it.

If the time is not available in miliseconds or cannot be provided with respect to midnight UT then any time can be inserted in a
timestamp provided the high order bit of the timestamp is also set to indicate this non-standard value.

IP Fields:
Addresses
The address of the source in a timestamp message will be the
destination of the timestamp reply message.
To form a timestamp reply message, the source and destination addresses are simply
reversed, the type code changed to 14, and the checksum recomputed.

Code:
0 = pointer indicates the error.
Code 0 may be received from a gateway or a host."
