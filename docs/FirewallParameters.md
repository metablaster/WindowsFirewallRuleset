
# Firewall Parameters

Firewall parameters and their values are not the same as they are displayed in Firewall GUI,
registry or by PowerShell commandlets.

Explain what is what by mapping powershell parameters to GUI and registry equivalents.\
In this document registry values are enclosed in parentheses.

In addition, explanation of other parameters which are not self explanatory or well documented
and usually need googling out what they do.

## Table of Contents

- [Firewall Parameters](#firewall-parameters)
  - [Table of Contents](#table-of-contents)
  - [Port](#port)
    - [LocalPort/RemotePort](#localportremoteport)
    - [LocalPort TCP Inbound](#localport-tcp-inbound)
    - [LocalPort UDP Inbound](#localport-udp-inbound)
    - [RemotePort TCP Outbound](#remoteport-tcp-outbound)
  - [Address](#address)
    - [RemoteAddress](#remoteaddress)
    - [LocalSubnet](#localsubnet)
    - [Internet](#internet)
    - [DefaultGateway](#defaultgateway)
    - [DNS](#dns)
    - [WINS](#wins)
    - [Loopback address](#loopback-address)
  - [Interface](#interface)
    - [InterfaceType](#interfacetype)
    - [InterfaceAlias](#interfacealias)
  - [Users](#users)
  - [Edge traversal](#edge-traversal)
  - [Policy store](#policy-store)
  - [Application layer enforcement](#application-layer-enforcement)
  - [Unicast response](#unicast-response)
  - [Parameter value example](#parameter-value-example)
  - [Log file fields](#log-file-fields)
  - [Conversion of parameter direction](#conversion-of-parameter-direction)
    - [Outbound](#outbound)
    - [Inbound](#inbound)
  - [Hidden parameters](#hidden-parameters)
    - [StatusCode](#statuscode)
    - [PolicyDecisionStrategy](#policydecisionstrategy)
    - [ConditionListType](#conditionlisttype)
    - [ExecutionStrategy](#executionstrategy)
    - [SequencedActions](#sequencedactions)
    - [Profiles](#profiles)
    - [EnforcementStatus](#enforcementstatus)
    - [LSM](#lsm)
    - [Platforms](#platforms)
  - [UDP mapping](#udp-mapping)
    - [LocalOnlyMapping](#localonlymapping)
    - [LooseSourceMapping](#loosesourcemapping)

## Port

- Port(s) can be specified only for TCP/UDP
- The docs say we can specify ICMP Type/Code with port parameter which doesn't work.

**NOTE:** According to docs IPHTTPS(Out\In) ports are only supported on Windows Server

### LocalPort/RemotePort

- `Any` All Ports

### LocalPort TCP Inbound

- `RPCEPMap` RPC Endpoint Mapper (RPC-EPMap)
- `RPC` RPC Dynamic Ports (RPC)
- `IPHTTPSIn` IPHTTPS (IPTLSIn, IPHTTPSIn)

### LocalPort UDP Inbound

- `PlayToDiscovery` PlayTo Discovery (sets LocalOnlyMapping to Ply2Disc)
- `Teredo` Edge Traversal (Teredo)

### RemotePort TCP Outbound

- `IPHTTPSOut` IPHTTPS (IPTLSOut, IPHTTPSOut)

[Table of Contents](#table-of-contents)

## Address

- *Keywords can be restricted to IPv4 or IPv6 by appending a 4 or 6*
- Appending 4 or 6 to "Any" address is not valid

### RemoteAddress

- `Any` Any IP Address (BLANK field)
- `LocalSubnet` Local Subnet (LocalSubnet)
- `Internet` Internet (IntErnet)
- `Intranet` Intranet (IntrAnet)
- `DefaultGateway` Default Gateway (DefaultGateway)
- `DNS` DNS Servers (DNS)
- `WINS` WINS Servers (WINS)
- `DHCP` DHCP Servers (DHCP)
- `IntranetRemoteAccess` Remote Corp Network (RmtIntrAnet)
- `PlayToDevice` PlayTo Renderers (Ply2Renders)
- `<unknown>` Captive Portal Addresses

Address sections below were tested with:

- Private IP client TCP: `psping64 -4 192.168.8.104:555`
- Server TCP: `psping64 -4 -s 192.168.8.104:555`
- Directed broadcast, client ICMP: `psping64 -4 192.168.8.255`

### LocalSubnet

1. Private IP address within subnet mask - YES
2. Private IP address on different subnet (segment) - YES
3. Directed broadcast address within subnet mask - YES
4. Directed broadcast address on different subnet (segment) - ? (send yes)
5. Limited broadcast address - Unknown
6. Multicast address space - ?

### Internet

1. Private IP address within subnet mask - NO
2. Private IP address on different subnet (segment) - YES
3. Directed broadcast address within subnet mask - YES
4. Directed broadcast address on different subnet (segment) - ? (send yes)
5. Limited broadcast address - Unknown
6. Multicast address space - ?

### DefaultGateway

1. Gateway address specified during static IP assignemt - YES
2. For dynamic assignment the default gateway address obtained from DHCP is used ?
3. If disconnected from network - ?

### DNS

1. The addresses specified in DNS entries for configured adapter - YES
2. For dynamic assignment the default gateway address is used - ?
3. If disconnected from network - ?

### WINS

1. The addresses specified in WINS entries for configured adapter - YES
2. If the WINS entry is empty - ?

### Loopback address

From addresses below, only the IPv4 loopback range is valid for Windows firewall rule.

|                     | IPv4        | IPv6    |
| ------------------- | ----------- | ------- |
| Loopback Address    | 127.0.0.0/8 | ::1/128 |
| Unspecified Address | 0.0.0.0/0   | ::/0    |
|                     |             |         |

[Table of Contents](#table-of-contents)

## Interface

### InterfaceType

- `Any` All interface types (BLANK field)
- `Wired` Wired (Lan)
- `Wireless` Wireless (Wireless)
- `RemoteAccess` Remote access (RemoteAccess)

### InterfaceAlias

**NOTE:** Not fully compatible with InterfaceType because InterfaceType parameter has higher
precedence over InterfaceAlias, mixing InterfaceType with InterfaceAlias doesn't make sense,
except if InterfaceType is `Any`, use just one of these two parameters.

```powershell
[WildCardPattern] ([string])
[WildCardPattern] ([string], [System.Management.Automation.WildCardOptions])
```

[Table of Contents](#table-of-contents)

## Users

- `Localuser` Authorized local Principals
- `<unknown>` Excepted local Principals
- `Owner` Local User Owner
- `RemoteUser` Authorized Users

## Edge traversal

- `Block` Allow edge traversal (BLANK field)
- `Allow` Block edge traversal (TRUE)
- `DeferToUser` Defer to user / Defer allow to user (Defer = User)
- `DeferToApp` Defer to application / Defer allow to application (TRUE, Defer = App)

[Table of Contents](#table-of-contents)

## Policy store

1. Persistent store

    > Is what you see in Windows Firewall with Advanced security, accessed trough control panel or
    System settings.
    > Rules created in this store are attached to the ActiveStore and activated on the computer immediately.

   Example: `-PolicyStore PersistentStore`

2. GPO store:

    > is specified as computer name, and it is what you see in Local group policy, accessed trough
    secpol.msc or gpedit.msc

    Example: `-PolicyStore ([System.Environment]::MachineName])`

3. RSOP store:

    > Stands for "resultant set of policy" and is collection of all GPO stores that apply to local computer.\
    > This applies to domain computers, on home computer RSOP consists of single local GPO (group
    policy object)

    Example: `-PolicyStore RSOP`

4. Active store:

    > Active store is the sum of Persistent store and all GPO stores (RSOP) that apply to
    local computer. in other words it's a master store.

    Example: `-PolicyStore ActiveStore`

5. SystemDefaults:

    > Read-only store contains the default state of firewall rules that ship with Windows Server 2012.
    > In other words, all predefined firewall rules are here.

    Example: `Get-NetFirewallRule -PolicyStore SystemDefaults`

6. StaticServiceStore:

    > Read-only store contains all the service restrictions that ship with Windows Server 2012.
    > Rules that cover optional and product-dependent features, can be used to harden firewall.

    Example: `Get-NetFirewallRule -PolicyStore StaticServiceStore`

7. ConfigurableServiceStore:

    > This read-write store contains all the service restrictions that are added for third-party services.
    > In addition, network isolation rules that are created for Windows Store application containers
    will appear in this policy store.
    > Network isolation rules that are created for Windows Store application containers are stored
    in the registry (and aren't accessible with Get-NetFirewallRule) under:
    `HKLM:\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\RestrictedServices\AppIso\FirewallRules`

    Example: `Get-NetFirewallRule -PolicyStore ConfigurableServiceStore`

For more information see [New-NetFirewallRule][netfirewallrule]

[Table of Contents](#table-of-contents)

## Application layer enforcement

The meaning of this parameter value depends on which parameter is it used:

1. `"*"` Applies to: services only OR application packages only (?)
2. `Any` Applies to: all programs AND (services OR application packages) (BLANK field)

Both of which are applied only if a packet meet the specified rule conditions

[Table of Contents](#table-of-contents)

## Unicast response

The option `Allow unicast response to multicast or broadcast traffic`

Prevents this computer from receiving unicast responses to its outgoing multicast or broadcast messages.

If you set this setting to `Yes (default)`, and this computer sends a multicast or broadcast message
to other computers, Windows Defender Firewall waits as long as three seconds for unicast responses
from the other computers and then blocks all later responses.

Otherwise if you set the option to `No`, Windows Defender Firewall blocks the unicast responses
sent by those other computers.

`Not configured` is equivalent to `Yes (default)` as long as control panel firewall does not
override this option.

**NOTE:** This setting has no effect if the unicast message is a response to a DHCP broadcast message
sent by this computer.
Windows Defender Firewall always permits those DHCP unicast responses.
However, this policy setting can interfere with the NetBIOS messages that detect name conflicts.

[Table of Contents](#table-of-contents)

## Parameter value example

This is how parameters are used on command line, most of them need to be enclosed in quotes if
assigned to variable first.

```none
Name                  = "NotePadFirewallRule"
DisplayName           = "Firewall Rule for program.exe"
Group                 = "Program Firewall Rule Group"
Ensure                = "Present"
Enabled               = True
Profile               = "Domain, Private"
Direction             = Outbound
RemotePort            = 8080, 8081
LocalPort             = 9080, 9081
Protocol              = TCP
Description           = "Firewall Rule for program.exe"
Program               = "c:\windows\system32\program.exe"
Service               = WinRM
Authentication        = "Required"
Encryption            = "Required"
InterfaceAlias        = "Ethernet"
InterfaceType         = Wired
LocalAddress          = 192.168.2.0-192.168.2.128, 192.168.1.0/255.255.255.0, 10.0.0.0/8
LocalUser             = "O:LSD:(D;;CC;;;S-1-15-3-4)(A;;CC;;;S-1-5-21-3337988176-3917481366-464002247-1001)"
Package               = "S-1-15-2-3676279713-3632409675-756843784-3388909659-2454753834-4233625902-1413163418"
Platform              = "6.1"
RemoteAddress         = 192.168.2.0-192.168.2.128, 192.168.1.0/255.255.255.0, 10.0.0.0/8
RemoteMachine         = "O:LSD:(D;;CC;;;S-1-5-21-1915925333-479612515-2636650677-1621)(A;;CC;;;S-1-5-21-1915925333-479612515-2636650677-1620)"
RemoteUser            = "O:LSD:(D;;CC;;;S-1-15-3-4)(A;;CC;;;S-1-5-21-3337988176-3917481366-464002247-1001)"
DynamicTransport      = ProximitySharing
EdgeTraversalPolicy   = Block
IcmpType              = 51, 52
IcmpType              = 34:4
LocalOnlyMapping      = $true
LooseSourceMapping    = $true
OverrideBlockRules    = $true
Owner                 = "S-1-5-21-3337988176-3917481366-464002247-500"
```

[Table of Contents](#table-of-contents)

## Log file fields

Their meaning in order how they appear in firewall log file:

`#Version:`

- Displays which version of the Windows Firewall security log is installed

`#Software:`

- Displays the name of the software creating the log

`#Time:`

- Indicates that all of the timestamps in the log are in local time

`#Fields:`

- Displays a static list of fields that are available for security log entries, as follows:

`date`

- Displays the year, month, and day that the recorded transaction occurred

`time`

- Displays the hour, minute, and seconds at which the recorded transaction occurred

`action`

- Displays which operation was observed by Windows Firewall
- The options available are `OPEN`, `OPEN-INBOUND`, `CLOSE`, `DROP`, and `INFO-EVENTS-LOST`

`protocol`

- Displays the protocol that was used for the communication
- The options available are `TCP`, `UDP`, `ICMP`, and a protocol number for packets

`src-ip`

- Displays the source IP address (the IP address of the computer attempting to establish communication)

`dst-ip`

- Displays the destination IP address of a communication attempt

`src-port`

- Displays the source port number of the sending computer
- Only TCP and UDP display a valid src-port entry
- All other protocols display a src-port entry of `-`

`dst-port`

- Displays the port number of the destination computer
- Only TCP and UDP display a valid dst-port entry
- All other protocols display a dst-port entry of `-`

`size`

- Displays the packet size, in bytes.

`tcpflags`

- Displays the TCP control flags found in the TCP header of an IP packet:\
`Ack` Acknowledgment field significant\
`Fin` No more data from sender\
`Psh` Push function\
`Rst` Reset the connection\
`Syn` Synchronize sequence numbers\
`Urg` Urgent Pointer field significant

`tcpsyn`

- Displays the TCP sequence number in the packet

`tcpack`

- Displays the TCP acknowledgement number in the packet

`tcpwin`

- Displays the TCP window size, in bytes, in the packet

`icmptype`

- Displays a number that represents the Type field of the ICMP message

`icmpcode`

- Displays a number that represents the Code field of the ICMP message

`info`

- Displays an entry that depends on the type of action that occurred
- For example, an INFO-EVENTS-LOST action will result in an entry of the number of events that occurred\
but were not recorded in the log from the time of the last occurrence of this event type.

`path`

- Displays the direction of the communication
- The options available are `SEND`, `RECEIVE`, `FORWARD`, and `UNKNOWN`

For more information see [Interpreting the Windows Firewall Log][firewall logs]

[Table of Contents](#table-of-contents)

## Conversion of parameter direction

Following are mappings between log file, firewall UI and PowerShell parameters.

The true meaning of source/destination is not straightforward, explanation is given in section above
and here is how to convert this info to other firewall/traffic contexts.

### Outbound

| Log      | GUI            | PowerShell    |
| -------- | -------------- | ------------- |
| src-ip   | Local Address  | LocalAddress  |
| dst-ip   | Remote Address | RemoteAddress |
| src-port | Local Port     | LocalPort     |
| dst-port | Remote Port    | RemotePort    |

### Inbound

| Log      | GUI            | PowerShell    |
| -------- | -------------- | ------------- |
| src-ip   | Remote Address | RemoteAddress |
| dst-ip   | Local Address  | LocalAddress  |
| src-port | Remote Port    | RemotePort    |
| dst-port | Local Port     | LocalPort     |

[Table of Contents](#table-of-contents)

## Hidden parameters

Following hidden parameters are part of CIM class and are not visible in firewall UI

### StatusCode

The detailed status of the rule, as a numeric error code.\
A value of `65536` means `STATUS_SUCCESS` or `NO_ERROR`, meaning there is no problem with this rule.

### PolicyDecisionStrategy

This field is ignored

### ConditionListType

This field is ignored

### ExecutionStrategy

This field is ignored.

### SequencedActions

This field is ignored.

### Profiles

Which profiles this rule is active on

The meaning of a value is as follows:\
**NOTE:** Combinations sum up, ex. a value of 5 means "Public" and "Domain"

```none
Any     = 0
Public  = 4
Private = 2
Domain  = 1
```

### EnforcementStatus

If this object is retrieved from the ActiveStore, describes the current enforcement status of the rule.

```none
0 = Invalid
1 = Full
2 = FirewallOffInProfile
3 = CategoryOff
4 = DisabledObject
5 = InactiveProfile
6 = LocalAddressResolutionEmpty
7 = RemoteAddressResolutionEmpty
8 = LocalPortResolutionEmpty
9 = RemotePortResolutionEmpty
10 = InterfaceResolutionEmpty
11 = ApplicationResolutionEmpty
12 = RemoteMachineEmpty
13 = RemoteUserEmpty
14 = LocalGlobalOpenPortsDisallowed
15 = LocalAuthorizedApplicationsDisallowed
16 = LocalFirewallRulesDisallowed
17 = LocalConsecRulesDisallowed
18 = NotTargetPlatform
19 = OptimizedOut
20 = LocalUserEmpty
21 = TransportMachinesEmpty
22 = TunnelMachinesEmpty
23 = TupleResolutionEmpty
```

### LSM

One might think this has something to do with "Local Session Manager" but it's a shorthand for
"Loose Source Mapping", the meaning is the same as `LooseSourceMapping` property.

### Platforms

Specifies which platforms the rule is applicable on.\
If null, the rule applies to all platforms (the default).\
Each entry takes the form `Major.Minor+`

If `+` is specified, then it means that the rule applies to that version or greater.\
`+` may only be attached to the final item in the list.

For more information see [MSFT_NetFirewallRule class][netfirewallrule cim] or
[Second link][netfirewallrule cim alternative]

[Table of Contents](#table-of-contents)

## UDP mapping

Applies only to UDP.\
UDP traffic is inferred by checking the following fields:

1. local address
2. remote address
3. protocol
4. local port
5. remote port

**TODO:** Rules which do not specify some of these fields, how does the above apply then?\
ex. only to new connections or existing connections? (statefull/stateless filtering)

### LocalOnlyMapping

Whether to group UDP packets into conversations based only upon the local address and port.

If this parameter is set to True, then the remote address and port will be ignored when inferring
remote sessions.\
Sessions will be grouped based on local address, protocol, and local port.

### LooseSourceMapping

Whether to group UDP packets into conversations based upon the local address, local port
and remote port.

If set, the rule accepts packets incoming from a host other than the one the packets were sent to.

**TODO:** Explain why this parameter can't be specified for inbound rule

For more information see [New-NetFirewallRule][netfirewallrule]

[Table of Contents](#table-of-contents)

[firewall logs]: https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2003/cc758040(v=ws.10) "Visit Microsoft docs"
[netfirewallrule]: https://docs.microsoft.com/en-us/powershell/module/netsecurity/new-netfirewallrule?view=winserver2012r2-ps&redirectedfrom=MSDN "Visit Microsoft docs"
[netfirewallrule cim]: https://docs.microsoft.com/en-us/previous-versions/windows/desktop/wfascimprov/msft-netfirewallrule "Visit Microsoft docs"
[netfirewallrule cim alternative]: https://docs.microsoft.com/en-us/previous-versions/windows/desktop/legacy/jj676843(v=vs.85) "Visit Microsoft docs"
