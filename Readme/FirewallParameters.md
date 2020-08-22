
# Firewall Parameters

Parameters and their values are not the same as they are displayed in Firewall GUI such as
GPO or Adv Windows firewall.

This documents helps understand what is what by mapping powershell parameters to GUI
display equivalents.

In addition, explanation of other parameters which are not self explanatory or well documented
and usually need googling out what they do.

# PORT

## LocalPort/RemotePort

- `Any` All Ports

## LocalPort TCP Inbound

- `RPCEPMap` RPC Endpoint Mapper
- `RPC` RPC Dynamic Ports
- `IPHTTPSIn` IPHTTPS

## LocalPort UDP Inbound

- `PlayToDiscovery` PlayTo Discovery
- `Teredo` Edge Traversal

## LocalPort TCP Outbound

- `IPHTTPSOut` IPHTTPS

# ADDRESS

- *Keywords can be restricted to IPv4 or IPv6 by appending a 4 or 6*

## RemoteAddress

- `Any` Any IP Address
- `LocalSubnet` Local Subnet
- `Internet` Internet
- `Intranet` Intranet
- `DefaultGateway` Default Gateway
- `DNS` DNS Servers
- `WINS` WINS Servers
- `DHCP` DHCP Servers
- `IntranetRemoteAccess` Remote Corp Network
- `PlayToDevice` PlayTo Renderers
- `?` Captive Portal Addresses

# INTERFACE

## InterfaceType

- `Any` All interface types
- `Wired` Wired
- `Wireless` Wireless
- `RemoteAccess` Remote access

## InterfaceAlias

**NOTE:** Not fully compatible with interfaceType because interfaceType parameter has higher
precedence over InterfaceAlias, Mixing interfaceType with InterfaceAlias doesn't make sense,
except if InterfaceType is "Any", use just one of these two parameters.

- [WildCardPattern] ([string])
- [WildCardPattern] ([string], [WildCardOptions])

# USERS

- `Localuser` Authorized local Principals
- `?` Excepted local Principals
- `Owner` Local User Owner
- `RemoteUser` Authorized Users

# EDGE TRAVERSAL

- `Block` Allow edge traversal
- `Allow` Block edge traversal
- `DeferToUser` Defer to user / Defer allow to user
- `DeferToApp` Defer to application / Defer allow to application

# POLICY STORE

1. Persistent Store (example: `-PolicyStore PersistentStore`)
2. GPO              (example: `-PolicyStore localhost`)
3. RSOP             (example: `-PolicyStore RSOP`)
4. ActiveStore      (example: `-PolicyStore ActiveStore`)

- Persistent Store:

> is what you see in Windows Firewall with Advanced security, accessed trough control panel or
System settings.

- GPO Store:

> is specified as computer name, and it is what you see in Local group policy, accessed trough
secpol.msc or gpedit.msc

- RSOP:

> stands for "resultant set of policy" and is collection of all GPO stores that apply to local computer.
> this applies to domain computers, on your home computer RSOP consists of only single
local GPO (group policy object)

- Active Store:

> Active store is collection (sum) of Persistent store and all GPO stores (RSOP) that apply to
local computer. in other words it's a master store.

There are other stores not mentioned here, which are used in corporate networks, AD's or Domains,
so irrelevant for home users.

# APPLICATION LAYER ENFORCEMENT

The meaning of this parameter value depends on which parameter it is used:

1. `"*"` Apply to services only / Apply to application packages only
2. `Any` Apply to all programs + and services / and application packages / that meet the specified condition

# PARAMETER VALUES EXAMPLE

This is how parameters are used on command line, most of them need to be enclosed in quotes if
assigned to variable first.

```Name                  = "NotePadFirewallRule"
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

# LOG FILE FIELDS

Depending on settings, firewall log can contain dropped and allowed packets,
setting in powershell allow us to log **ignored** packets too however this does not happen
probably due to a bug.\
Sample values and their meaning in order how they appear in firewall log file:

```date        = 2019-12-21
time        = 13:35:31
action      = DROP
protocol    = UDP
src-ip      = 192.168.8.110
dst-ip      = 224.0.0.22
src-port    = 61148
dst-port    = 3702
size        = 0
tcpflags    = -
tcpsyn      = -
tcpack      = -
tcpwin      = -
icmptype    = 134
icmpcode    = 1
info        = -
path        = RECEIVE
```

Following are mappings between log file, Firewall GUI and PowerShell parameters

## Outbound

```none
Log         GUI               PowerShell
src-ip      Local Address     LocalAddress
dst-ip      Remote Address    RemoteAddress
src-port    Local Port        LocalPort
dst-port    Remote Port       RemotePort
```

## Inbound

```none
Log         GUI               PowerShell
src-ip      Remote Address    RemoteAddress
dst-ip      Local Address     LocalAddress
src-port    Remote Port       RemotePort
dst-port    Local Port        LocalPort
```
