
# About this document
Parameters and their values are not the same as they are displaied in Firewall GUI such as GPO or Adv Windows firewall.

This documents helps understand what is what by mapping powershell parameters to GUI display equivalents.

# PORT
**LocalPort/RemotePort**
- `Any` All Ports

**LocalPort TCP Inbound**

- `RPCEPMap` RPC Endpoint Mapper
- `RPC` RPC Dynamic Ports
- `IPHTTPSIn` IPHTTPS

**LocalPort UDP Inbound**

- `PlayToDiscovery` PlayTo Discovery
- `Teredo` Edge Traversal

**LocalPort TCP Outbound**

- `IPHTTPSOut` IPHTTPS

# ADDRESS
- *Keywords can be restricted to IPv4 or IPv6 by appending a 4 or 6*

**RemoteAddress**
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
- `Any` All interface types
- `Wired` Wired
- `Wireless` Wireless
- `RemoteAccess` Remote access

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
