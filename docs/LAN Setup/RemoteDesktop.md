
# Remote Desktop

## Enable remote desktop

The following applies to remote computer:

- Settings -> System -> Remote desktop -> Enable Remote Desktop
  - Make my PC discoverable on private network to enable automatic connection from a remote device.

Alternative way:

- Settings -> System -> About -> System info -> Remote settings -> Allow remote connections to
  this computer (not assistance)
  - Allow only network level authentication.

## Services

The following services (in bold) need to run remote computer,
set or verify these services are set to "Automatic" startup:\
**NOTE:** For smooth startup of services set dependent services to delayed start.\
**NOTE:** Values in parentheses are service short name and default startup type which should work too.

1. **Remote Desktop Configuration (SessionEnv, Manual)**

    - Remote Procedure Call (RPC)
    - Workstation

2. **Remote Desktop Services (TermService, Manual)**

    - Remote Procedure Call (RPC)

3. **Remote Desktop Services UserMode Port Redirector (UmRdpService, Manual)**

    - Remote Desktop Services
    - Remote Desktop Device Redirector Driver

## Default firewall rules

Predefined "Remote Desktop" rules for inbound traffic.\
For blocking outbound firewall custom rules are needed to allow traffic.

## Custom SSL certificate

- A certificate with private key located in `Personal Store`
- Right-click the certificate, select All Tasks, and then select Manage Private Keys
- In the Permissions dialog box, click Add, type `NETWORK SERVICE`, click OK,
  select Read under the Allow check box, and then click OK
- Export certificate including private key
- Import exported certificate into `Remote Desktop` store
- Double click certificate -> Detail -> Thumbprint -> copy value
- Replace `THUMBPRINT` portion in the code below with copied value

```powershell
$RdpTCP = Get-CimInstance -Class Win32_TSGeneralSetting -Namespace root\cimv2\terminalservices -Filter "TerminalName='RDP-tcp'"
Set-CimInstance -InputObject $RdpTCP -Property @{ SSLCertificateSHA1Hash = "THUMBPRINT" }
```
