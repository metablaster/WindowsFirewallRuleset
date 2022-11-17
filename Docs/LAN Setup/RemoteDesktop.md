
# Remote Desktop

## Enable remote desktop

Following applies to remote computer:

- Settings -> System -> Remote desktop -> Enable Remote Desktop
  - Make my PC discoverable on private network to enable automatic connection from a remote device.

Alternative way:

- Settings -> System -> About -> System info -> Remote settings -> Allow remote connections to
  this computer (not assistance)
  - Allow only network level authentication.

## Services

Following services (in bold) need to run remote computer,
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
