
# Network Discovery

Set or verify following services (in bold) are set to "Automatic" startup (here listed alphabetically):\
**NOTE:** For smooth startup of services set dependent services to delayed start.\
**NOTE:** Values in parentheses are service short name and default startup type which should work too.

- **DNS Client (Dnscache, Automatic - Trigger)**
  - Ancillary Function Driver for Winsock (Driver)
  - Network Store Interface Service ...

- **Function Discovery Provider Host (fdPHost, Manual)**
  - HTTP Service ...
  - Remote Procedure Call (RPC) ...

- **Function Discovery Resource Publication (FDResPub, Manual - Trigger)**
  - HTTP Service (Driver: System32\drivers\HTTP.sys, startup type = DEMAND_START)
    - MsQuic (Driver: system32\drivers\msquic.sys, startup type = DEMAND_START)
  - Remote Procedure Call (RPC) ...
  - Function Discovery Provider Host...

- **Network Store Interface Service (nsi, Automatic)**
  - NSI Proxy Service Driver (Driver: WIN32_SHARE_PROCESS, startup type = AUTO_START)
  - Remote Procedure Call (RPC)
    - DCOM Server Process Launcher
    - RPC Endpoint Mapper

- **Server (LanmanServer, Automatic - Trigger)**
  - Security Accounts Manager
    - Remote Procedure Call (RPC)...
  - Server SMB Driver (Driver)
    - srvnet (Driver)

- **SSDP Discovery (SSDPSRV - Manual)**
  - HTTP Service ...
  - Network Store Interface Service ...

- **TCP/IP NetBIOS Helper (lmhosts, Manual - Trigger)**
  - Ancillary Function Driver for Winsock (Driver)

- **UPnP Device Host (upnphost, Manual)**
  - SSDP Discovery
    - HTTP Service ...
    - Network Store Interface Service ...
  - HTTP Service ...

- **Workstation (LanmanWorkstation, Automatic)**
  - Network Store Interface Service ...
  - Browser (Driver)
  - SMB Mini redirector (Driver)

- *Computer Browser* (Available on older Windows, before Windows 10, "Browser" is now in Workstation)
  - Workstation...
  - Server...

## Additional

1. Turn on Network Discovery in Network and Sharing Center.

2. Configure all firewalls in the network to allow Network Discovery rules.

3. Settings -> System -> System info -> Advanced system settings -> Computer name -> Network ID ->
   this is home computer

4. Change -> rename computers and set them all to same workgroup.
