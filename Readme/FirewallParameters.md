
# About this document
Parameters and their values are not the same as they are displaied in Firewall GUI such as GPO or Adv Windows firewall.

This documents helps understand what is what by mapping powershell parameters to GUI display equivalents.

In addition, explanation of other parameters which are not self explanatory or well documented and usually need googling out what they do.

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

# POLICY STORE
1. Persistent Store (example: `-PolicyStore PersistentStore`)
2. GPO              (example: `-PolicyStore localhost`)
3. RSOP             (example: `-PolicyStore RSOP`)
4. ActiveStore      (example: `-PolicyStore ActiveStore`)

Persistent Store:
- is what you see in Windows Firewall with Advanced security, accessed trough control panel or System settings.
GPO Store:
- is specified as computer name, and it is what you see in Local group policy, accessed trough secpol.msc or gpedit.msc
RSOP:
- stands for "resultant set of policy" and is collection of all GPO stores that apply to local computer.
- this applies to domain computers, on your home computer RSOP consists of only single local GPO (group policy object)
Active Store:
- Active store is collection (sum) of Persistent store and all GPO stores (RSOP) that apply to local computer. in other words it's a master store.

There are other stores not mentioned here, which are used in corporate networks, AD's or Domains, so irrelevant for home users.
