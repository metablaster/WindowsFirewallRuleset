
# About this document

Explains network adapter items

## Client for Microsoft Networks

- Allows this computer to access resources on a Microsoft network.
- This is the Workstation Service. This service is complex and third party applications
may depend on this being there.
- Disabling this is often recommended for server hardening.
- Essential if networked.

## File and Printer Sharing for Microsoft Networks

- Needed if you connect to another computer or vice versa.
- Allows other computers on a network to access resources on this computer by using a Microsoft network.
- This component is installed and enabled by default for all VPN connections. However,
this component needs to be enabled for PPPoE and dial-up connections.
- It is enabled per connection and is necessary to share local folders.

## Microsoft LLDP Protocol Driver

- Microsoft's version of LLDP.
- The Link Layer Discovery Protocol (LLDP) is a link layer protocol used by network devices for
advertising their identity, capabilities and neighbors on an IEEE 802 local area network.
- Not needed if you aren't accessing anything except the internet on your network.

## Microsoft Network Adapter Multiplexor Protocol

- Provides a platform for network adapter load balancing and fail-over.
- The Network Load Balancing (NLB) feature distributes traffic across several servers by using the
TCP/IP networking protocol. By combining two or more computers that are running applications
into a single virtual cluster.
- This protocol is used for Network Interface Card bonding, which is the combining of two ethernet
cards to appear as one physical device in order to increase the available bandwidth.
- NIC Teaming allows you to group physical Ethernet network adapters into one or more software-based
virtual network adapters.
These virtual network adapters provide fast performance and fault tolerance
in the event of a network adapter failure.

## Link-Layer Topology Discovery  I/O Driver

- Used to discover and locate other PC's, devices, and network infrastructure components on the network.
- Also used to determine network bandwidth.
- If the Link-Layer Topology Discovery Mapper I/O Driver fails to start, the error is logged.
Windows startup proceeds, but a message box is displayed informing you that the lltdio
service has failed to start.

## Link-Layer Topology Discovery Responder

- Allows this PC to be discovered and located on the network.

## Internet Protocol Version 4 (TCP/IPv4)

- Internet Protocol v4 (IPv4) is the fourth revision of the Internet Protocol and a vastly used
protocol in data communication over different kinds of networks.
- IPv4 is a protocol used in packet-switched layer networks, such as Ethernet.
- It provides the logical connection between network devices by providing identification for each device.
Internet Protocol version 6 (TCP/IPv6)
- Internet Protocol v6 (IPv6) is the latest revision of the Internet Protocol (IP),
the communications protocol that routes traffic across the internet and is intended to replace IPv4.
- IPv6 is designed to solve many of the problems of IPv4, including mobility, auto-configuration,
and overall extensibility.
- IPv6 expands the address space on the Internet and supports a nearly unlimited number of devices
that can be directly connected to the Internet.
- For many users this is an essential component. HomeGroup, VPN, DirectAccess and other parts of
the operating system use this.
- You should keep ipv6 enabled even if your ISP doesn't provide ipv6 connectivity yet.
- Applications that you might not think are using IPv6 such as Remote Assistance, HomeGroup, DirectAccess.

## QoS Packet Scheduler

- A Windows platform component that is enabled by default and is designed to control the IP traffic
for various network services, as a method of network bandwidth management that can monitor
the importance of data packets and based on the priority of the packet.
- a quality of service (QoS) network can guarantee a certain level of throughput for a specific path,
connection, or type of traffic.
- For example, networks carrying real-time audio or video require a high level of QoS to ensure that
reception is smooth and free of errors.
- You can control the following network properties in a network that supports QoS functions:

1. Throughput (total bandwidth used)
2. Latency (traffic delay)
3. Priority (among types of traffic)
4. Peak traffic, burstiness, and jitter (to smooth traffic flow)
5. Packet or cell loss and retransmission

## Hyper-V Extensible Virtual Switch

- the Hyper-V host and the Hyper-V guests will share the physical NIC.
- The Hyper-V extensible switch supports connections from various types of virtual or
physical network adapters.
The connection to these types of network adapters is made through an extensible switch port.
- Ports are created before a virtual network adapter connection is made, and are deleted after
the network adapter connection is torn down.
- the Hyper-V Virtual Switch Manager disables everything else in your native physical network
adapter's properties, only enabling the Hyper-V Extensible Switch.

## Bridge Driver

- This component provides I2 bridge capability between mbb, wifi and ethernet networks.
