
# Manage Windows Firewall trough Local Group Policy (GPO)

For general reference see:

[Windows Defender Firewall with Advanced Security][ref firewall]

Following is an older reference for servers with some unique information:

[Windows Firewall with Advanced Security Administration with Windows PowerShell][ref firewall powershell]

To open management console to manage GPO firewall follow steps below:

1. Press start button
2. Type: `secpol.msc`
3. Right click on secpol.msc and click `Run as administrator`
4. If asked, enter Administrator credentials to continue
5. Expand node: `Windows Defender Firewall with Advanced Security`
6. Expand node: `Windows Defender Firewall with Advanced Security - Local Group Policy Object`
7. Click on either `Inbound Rules`, `Outbound Rules` or `Windows Defender Firewall...` node to view
and manage rules and settings.

GPO firewall is located in the following location:

`Computer Configuration\Windows Settings\Security Settings\Windows Defender Firewall with Advanced security`

Additional options to manage GPO firewall are located in the following location:

`Computer Configuration\Administrative Templates\Network\Network Connections\Windows Defender Firewall`

Options to control network profile are located in:

`Computer Configuration\Windows Settings\Security Settings\Network List Manager Policies`

Options to control IP security are located in:

`Computer Configuration\Windows Settings\Security Settings\IP Security Policies on Local Computer`

To open GPO editor to navigate mentioned locations above follow steps below:

1. Press start button
2. Type: `gpedit.msc`
3. Right click on gpedit.msc and click `Run as administrator`
4. If asked, enter Administrator credentials to continue

[ref firewall]: https://docs.microsoft.com/en-us/windows/security/threat-protection/windows-firewall/windows-firewall-with-advanced-security "Visit Microsoft docs"
[ref firewall powershell]: https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-r2-and-2012/hh831755(v=ws.11) "Visit Microsoft docs"
