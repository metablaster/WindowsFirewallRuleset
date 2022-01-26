
# Steps to reset Firewall to previous state

Applies to resetting firewall and remoting by hand after running Powershell scripts from this project.

Useful if you encountered problems such as internet connectivity and you're unable to run\
`Scripts\Reset-Firewall.ps1` or if the script did not resolve your problems.

**WARNING:** These steps will not save any GPO rules, all preferences will be gone, resetting
Control Panel firewall leaves only default rules shipped with system and removes the rest.

## Follow steps below to reset GPO firewall by hand

1. Press start button
2. type: `secpol.msc`
3. Right click on `secpol.msc` and click `Run as administrator`
4. Expand node: `Windows Defender Firewall with Advanced Security`
5. Right click on: `Windows Defender Firewall with Advanced Security - Local Group Policy Object`
6. Select "Clear Policy" and GPO firewall will be reset to factory defaults.

## Follow steps below to reset WinRM and PowerShell remoting by hand

To reset WinRM (Windows remote management) by hand use `winrm.cmd` command.\
See [Installation and configuration for Windows Remote Management][configure winrm] for information
about default values

## Problem still not resolved

This should not be the case, but first step is to reboot system and double check GPO firewall is off.

Otherwise it can happen if you modified firewall in control panel.\
Follow steps below to reset default windows firewall:

1. Open control panel and click on `Windows Defender Firewall`
2. Click on `Restore defaults` to restore firewall to defaults
3. If problem is not fixed right away you may need to reboot system
4. Otherwise try disabling firewall in control panel.

## Still having problems

See [Network troubleshooting detailed guide](NetworkTroubleshooting.md)

[configure winrm]: https://docs.microsoft.com/en-us/windows/win32/winrm/installation-and-configuration-for-windows-remote-management
