## WindowsFirewallRuleset

# About WindowsFirewallRuleset
- Windows firewall rulles organized into individual powershell scripts according to:
1. Rule group
2. Traffic direction
3. Further sorted according to programs and services

- such as for example:
2. ICMP rules
3. Browser rules
4. rules for Windows system
5. services
6. Microsoft programs
7. 3rd party programs
8. multicast traffic
9. etc... 

- You can choose which rulles you want, and apply only those or apply them all with single command.
- All the rules are loaded into Local group policy giving you full power over default windows firewall.

# Minimum system requirements
1. Windows 10 Pro/Enterprise
2. Windows Powershell 5 or later

# Step by step quick usage
1. Right click on the Task bar and select `Taskbar settings`
2. Toggle on `Replace Command Prompt with Windows Powershell in the menu when I right click the start button`
3. Right click on Start button in Windows system
4. Click `Windows Powershell (Administrator)` to open Powershell as Administrator
5.  Type: ```cd C:```
6. Copy paste into console: ```git clone git@github.com:metablaster/WindowsFirewallRuleset.git``` hit enter
7. Copy paste into console: ```cd WindowsFirewallRuleset``` hit enter
8. Copy paste into console: ```.\Main.ps1``` hit enter
9. Follow prompt output, (ie. hit enter each time to proceed until done)

# Where are my rules?
Rules are loaded into Local group policy, follow bellow steps to open local group policy.
1. Press Windows key and type: `secpol.msc`
2. Expand node: `Windows Defender Firewall with Advanced Security`
3. Expand node: `Windows Defender Firewall with Advanced Security - Local Group Policy Object`
4. Click on either `Inbound` or `Outbound` node to view and manage the rulles you applied with Powershell script.
