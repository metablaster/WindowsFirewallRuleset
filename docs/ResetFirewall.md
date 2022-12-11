
# Steps to reset Firewall to previous state

This document explains how to restore everything that was done by `Windows Firewall Ruleset` to
system defaults.

The easiest and highly recommended method is to use `Reset-Firewall.ps1` which will undo everything
automatically, example how to run it:

```powershell
C:
cd \
cd WindowsFirewallRuleset*
.\Scripts\Reset-Firewall.ps1 -Remoting -Service
# Restart PowerShell
```

If you encounter problems such as internet connectivity and you're unable to run\
`Scripts\Reset-Firewall.ps1 -Remoting` or if the script did not resolve your problems then follow
next sections as needed.

## Reset GPO firewall by hand

1. Press start button
2. type: `secpol.msc`
3. Right click on `secpol.msc` and click `Run as administrator`
4. Expand node: `Windows Defender Firewall with Advanced Security`
5. Right click on: `Windows Defender Firewall with Advanced Security - Local Group Policy Object`
6. Select `Clear Policy` and GPO firewall will be reset to system defaults.

## Reset PowerShell remoting by hand

To disable PowerShell remoting open PowerShell as Administrator, the edition you run depends on
edition that was used to deploy firewall.

Run the following commands:

```powershell
Disable-PSRemoting
Remove-Item -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\LocalAccountTokenFilterPolicy `
    -ErrorAction Ignore
```

You might have to manually disable the firewall exceptions for WS-Management communications.

## Reset WinRM by hand

Reseting WinRM by hand to system default is certainly not easy to do.

To reset WinRM (Windows remote management) by hand use `winrm.cmd` command.\
See [Installation and configuration for Windows Remote Management][configure winrm] for information
about default values.

## Restore system services

`Windows Firewal Ruleset` might have started some system services required for deployment, to see
which services were modified take a look into `Logs` folder and find `Services-<DATE>.log`

The log file lists all the services whose startup mode and\or status status was changed.

If you're unable to find the file or you don't know defaults, the following table lists all the
services which `Windows Firewal Ruleset` might have modified and their system defaults:

| Service                                            | Startup                   | Status  |
|----------------------------------------------------|---------------------------|---------|
| TCP/IP NetBIOS Helper (lmhosts)                    | Manual (Trigger Start)    | Running |
| Workstation (LanmanWorkstation)                    | Automatic                 | Running |
| Server (LanmanServer)                              | Automatic (Trigger Start) | Running |
| Windows Remote Management (WinRM)                  | Manual                    | Stopped |
| OpenSSH Authentication Agent (ssh-agent)           | Disabled                  | Stopped |
| Remote Registry (RemoteRegistry)                   | Manual                    | Stopped |
| Function Discovery Provider host (fdPHost)         | Manual                    | Running |
| Function Discovery Resource Publication (FDResPub) | Manual (Trigger Start)    | Running |

## Problem still not resolved

This should not be the case and if you followed all the steps above only few things are left that
`Windows Firewal Ruleset` did, but if you still have issues first step is to reboot system and
double check GPO firewall is all set to `Not configured`.

If this doesn't solve the problem then please either run `Scripts\Reset-Firewall.ps1 -Remoting` or
take a look into that script to see what it does if you insist to do things by hand.

## Reset control panel firewall

It could be you modified firewall in control panel manually.\
Follow steps below to reset windows firewall in control panel:

**WARNING:** Resetting control Panel firewall leaves only default rules shipped with system and
removes the rest, this might cause some of your programs stop being being able to connect to
internet.

1. Press start button, type `Control Panel` and run the control panel app
2. In control panel is sorted by "category" select `View by: small icons`
3. Click on `Windows Defender Firewall`
4. Click on `Restore defaults` to restore firewall to defaults
5. If problem is not fixed right away you may need to reboot system
6. Otherwise try disabling firewall in control panel.

## Still having problems

See [Network troubleshooting detailed guide](NetworkTroubleshooting.md)

[configure winrm]: https://docs.microsoft.com/en-us/windows/win32/winrm/installation-and-configuration-for-windows-remote-management "Visit Microsoft docs"
