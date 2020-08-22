
# Network Discovery

Setup these services to autostart:

- DNS Client

- Network Store Interface Service
  - NSI Proxy Service Driver (invisible: WIN32_SHARE_PROCESS, startup type = AUTO_START)
  - Remote Procedure Call (RPC)
    - DCOM Server Process Launcher
    - RPC Endpoint Mapper

- Function Discovery Resource Publication (auto (delayed start! probably needed so if IPv6 enabled)
  - HTTP Service (invisible service: system32\drivers\HTTP.sys, startup type = DEMAND_START)
    - WinQuic (invisible service: system32\drivers\winquic.sys, startup type = DEMAND_START)
  - Remote Procedure Call (RPC) ...
  - Function Discovery Provider Host
    - Remote Procedure Call (RPC) ...
    - HTTP Service ...

- UPnP Device Host
  - SSDP Discovery
    - HTTP Service ...
    - Network Store Interface Service ...
  - HTTP Service ...

- Workstation
  - Network Store Interface Service ...
  - Browser (invisible service)
  - SMB Mini redirector (invisible service)

- Server
  - Security Accounts Manager
    - Remote Procedure Call (RPC)...
  - Server SMB Driver (invisible service)

- TCP/IP NetBIOS Helper
  - Ancillary Function Driver for Winsock (driver)

- Computer Browser
  - Workstation...
  - Server...

## Additional

1. Set static (and unique) IP for each computer in LAN, (DHCP may result in bad workgroup name,
   possible bug or crappy router, see event log if that's the case)

2. Turn on Network Discovery in Network and Sharing Center.

3. Configure all firewalls in the network to allow Network Discovery rules.

4. Settings -> System -> System info -> Advanced system settings -> Computer name -> Network ID ->
   this is home computer

5. Change -> rename computers and set them all to same workgroup.
