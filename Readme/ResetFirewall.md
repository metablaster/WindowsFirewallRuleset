# Steps to reset Firewall to previous state

Applies to reseting firewall by hand after runing Powershell scripts from this project.

Usefull if you encountered problems such as internet conectivity and you're unable to run\
`ResetFirewall.ps1` script file located in project root directory, or if the script file did\
not resolve your problems.

**Follow bellow steps to revert firewall**
1. Press start button
2. type: `secpol.msc`
2. Righ click on `secpol.msc` and click `Run as administrator`
3. Expand node: `Windows Defender Firewall with Advanced Security`
4. Right click on: `Windows Defender Firewall with Advanced Security - Local Group Policy Object`
5. Select properties
6. There are 3 tabls: "Domain", "Private" and "Public"
7. set every available property to "Not configured", do so under "Customize" buttons too
8. under "Inbound" and "outbound" node select all the rules right click and delete them all.
9. If problem is not fixed right away you may need to reboot system

**Problem still not resolved**

This should not be the case, but can happen if you modified firewall in control panel.\
Follow bellow steps to reset default windows firewall:

1. Open control panel and click on "Windows defender firewall"
2. Click on "Restore defaults" to restore firewall to defaults
3. If problem is not fixed right away you may need to reboot system
4. Also try disabling firewall in control panel.

**Still having problems?**
1. Open control panel and click on "Network and sharing center"
2. Click on "Troubleshoot problems"
3. depending on your system choose different options to troubleshoot problems.
4. what you are looking for is "Network reset" and "Diagnose problems"
5. If problem is not fixed right away you may need to reboot system
6. if still problems verify your router and conectivity with other devices on same router.
7. Otherwise contact your system administrator for more help.
