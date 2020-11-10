
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

Following services apply to remote computer:

1. Remote Desktop Configuration (SessionEnv)
2. Remote Desktop Services (TermService)
3. Remote Desktop Services UserMode Port Redirector (UmRdpService)

## Default firewall rules

Predefined "Remote Desktop" rules for inbound traffic.
