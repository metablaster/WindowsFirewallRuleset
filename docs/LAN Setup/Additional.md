
# Additional Settings

Additional hints and notices that may shade some light to troubleshoot home network setup.

Before you follow hints here keep in mind there is a known workaround to make home group work with
this firewall project here:\
[Discovery and file and printer sharing issue](ProblematicTraffic.md#case-10-discovery-and-file-and-printer-sharing-issue-on-home-networks-workgroup)

## NTLM and WINS

1. NTLM authentication is still supported and must be used for Windows authentication with systems
   configured as a member of a workgroup.

   - NTLM authentication is also used for local logon authentication on non-domain controllers.

2. NTLM is still used in the following situations:

   - No Active Directory domain exists (commonly referred to as "workgroup" or "peer-to-peer")

3. Windows Internet Name Service (WINS) is a legacy computer name registration and resolution service
   that maps computer NetBIOS names to IP addresses.

4. If you don't already have WINS deployed on your network, do not deploy WINS

## Services

Following services may help in specific scenarios:\
**NOTE:** Values in parentheses are service short name and default startup type which should work too.

- Internet connection sharing (SharedAccess, Manual - Trigger Start)
- IP Translation configuration (IpxlatCfgSvc, Manual - Trigger Start)
- Link-layer topology discovery mapper (lltdsvc, Manual)
- PNRP Machine Name Publication Service (PNRPAutoReg, Manual)

Following services may help with UNC name resolution:

- Network Connections (Netman, Manual)
- Peer Name Resolution Protocol (PNRPsvc, Manual)
- Peer Networking Grouping (p2psvc, Manual)
- Peer Networking Identity Manager (p2pimsvc, Manual)

## Troubleshooting discovery

- Again Settings -> System -> About -> Rename this PC (Advanced) -> Network ID -> this is home computer
- Function Discovery Resource Publication to delayed start (or just restart for quick effect)
- Disable IPv6 (may cause unresponsiveness if router does not support IPv6)
- Internet Protocol Version 4 (TCP/IPv4) -> WINS -> Enable LMHOSTS lookup
- Remove/uninstall unneeded virtual adapters.
- Set static (and unique) IP for each computer on LAN, (Using DHCP may result in bad workgroup name,
  see event log if that's the case)

## Make This PC Discoverable in PC settings

INFO: probably point 3 does that implicitly

- The Make this PC discoverable setting will not be available if you have UAC set to Always notify.
- Setting UAC to a different level will allow Make this PC discoverable settings to be available.
- The Make this PC discoverable setting will not be available if you have created a Hyper-V virtual switch
- with this Ethernet connection.

## Troubleshoot name resolution (discovery)

```powershell
nbtstat -c
nbtstat -r
net view
Get-SmbClientConfiguration
Get-SmbClientNetworkInterface
Get-SmbShare
```

## more discovery tools

Restart following services on both computers:

- Function discovery resource publication
- Workstation ("Computer browser" on systems older than Windows 10)

## Explicitly Set Link-Layer Topology Discovery

`Computer Configuration\Administrative Templates\Network\Link-Layer Topology Discovery`

- Turn on Mapper I/O (LLTDIO) driver
- Turn on Responder (RSPNDR) driver
