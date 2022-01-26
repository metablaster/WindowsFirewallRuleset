
# Delivery Optimization

Delivery Optimization listens on port 7680 for requests from other peers by using TCP/IP.\
The service will register and open this port on the device, but you might need to set this port
to accept inbound traffic through your firewall yourself.\
If you don't allow inbound traffic over port 7680, you can't use the peer-to-peer functionality
of Delivery Optimization.\
However, devices can still successfully download by using HTTP or HTTPS traffic over port 80
(such as for default Windows Update data).

If you set up Delivery Optimization to create peer groups that include devices across NATs
(or any form of internal subnet that uses gateways or firewalls between subnets), it will use Teredo.\
For this to work, you must allow inbound TCP/IP traffic over port 3544.\
Look for a "NAT traversal" setting in your firewall to set this up.

[Delivery Optimization for Windows client updates][delivery optimization]

## Setting

Settings -> Updates & Security -> Allow download from other PC's (PC's on my local network)

## Services

For delivery optimization set or verify following services (in bold) to "Automatic" startup:\
**NOTE:** For smooth startup of services set dependent services to delayed start.\
**NOTE:** Values in parentheses are service short name and default startup type which should work too.

- **Delivery Optimization (DoSvc, Automatic - Delayed, Trigger)**
  - Remote Procedure call (RPC)...

For teredo:

- **IP Helper (iphlpsvc, Automatic)**
  - Network Store Interface Service...
  - Remote Procedure call (RPC)...
  - TCP/IP Protocol Driver (Driver: KERNEL_DRIVER, startup type = BOOT_START)
  - Windows Management instrumentation
  - WinHTTP Web Proxy Auto-Discovery Service

## Settings

Delivery Optimization settings in Group Policy under:

`Configuration\Policies\Administrative Templates\Windows Components\Delivery Optimization`

## Troubleshooting

Check Clients Can Reach Delivery Optimization Cloud Services

```powershell
Get-DeliveryOptimizationStatus | Format-List FileID,Status,Priority,SourceURL
```

Can Clients Reach Peers on the Network

```powershell
Get-DeliveryOptimizationPerfSnap -Verbose
```

Other Delivery Optimization PowerShell Cmdlets

```powershell
Get-DeliveryOptimizationLog | Set-Content c:\temp\dosvc.log
```

[delivery optimization]: https://docs.microsoft.com/en-us/windows/deployment/update/waas-delivery-optimization
