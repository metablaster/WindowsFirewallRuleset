## WindowsFirewallRuleset

# About WindowsFirewallRuleset
- Windows firewall rulles organized into individual powershell scripts according to:
1. Rule group
2. Traffic direction
3. Further sorted according to programs and services

- such as for example:
2. ICMP traffic
3. Browser rules
4. rules for Windows system
5. Windows services
6. Microsoft programs
7. 3rd party programs
8. multicast traffic
9. etc... 

- You can choose which rulles you want, and apply only those or apply them all with single command.
- All the rules are loaded into Local group policy giving you full power over default windows firewall.

# License notice
WindowsFirewallRuleset
> Copyright (c) 2019 metablaster

Indented.Net.IP
> Copyright (c) 2016 Chris Dent

For more info see:\
LICENSE.md\
LICENSE\
Indented.Net.IP\LICENSE

# Minimum system requirements
1. Windows 10 Pro/Enterprise
2. Windows Powershell 5 [Download Powershell](https://github.com/PowerShell/PowerShell)
3. Git (Optional) [Download Git](https://git-scm.com/downloads)

For older system such as Windows 7 most of the rules will work, ie. rules for Store Apps will not work.

To be able to apply rules to older system, edit the `GlobalVariables.ps1` and edit the line:

```$Platform = "10.0+" #Windows 10 and above``` by specifying windows version, for example for Windows 7

it should look like:
```$Platform = "6.1" #Windows 7```

Next you can delete or comment out Widnows 10 related rules by editing the scripts.

Otherwise try just ignore the execution errors and run the scripts by force, you can delete irrelevant rules in GPO later.

# Step by step quick usage
1. Right click on the Task bar and select `Taskbar settings`
2. Toggle on `Replace Command Prompt with Windows Powershell in the menu when I right click the start button`
3. Right click on Start button in Windows system
4. Click `Windows Powershell (Administrator)` to open Powershell as Administrator (Input Admin password if needed)
5. Type: ```cd C:```
6. Copy paste into console: ```git clone git@github.com:metablaster/WindowsFirewallRuleset.git``` and hit enter
7. Copy paste into console: ```cd WindowsFirewallRuleset``` and hit enter
8. Open file explorer and navigate to `C:\WindowsFirewallRuleset\Modules`
9. Open `GlobalVariables.ps1` with your preffered code editor such as VS Code or Powershell ISE
10. Edit the line `$User = Get-UserSDDL User`, input your username by replacing 'User' with your username,
for example if your username is Patrick the line should look like `$User = Get-UserSDDL Patrick`
11. Save and close the Powershell script file.
12. Back to Powershell console and copy paste into console: ```.\Main.ps1``` and hit enter (this will load all the rulles)
13. Follow prompt output, (ie. hit enter each time to proceed until done)

# Where are my rules?
Rules are loaded into Local group policy, follow bellow steps to open local group policy.
1. Press Windows key and type: `secpol.msc`
2. Righ click on `secpol.msc` and click `Run as administrator`
2. Expand node: `Windows Defender Firewall with Advanced Security`
3. Expand node: `Windows Defender Firewall with Advanced Security - Local Group Policy Object`
4. Click on either `Inbound` or `Outbound` node to view and manage the rulles you applied with Powershell script.

# Applying individual rulesets
If you want to apply only specific rules there are 2 ways to do this:
1. Execute `Main.ps1` and hit enter only for rullesets you want, otherwise type `n` and hit enter to skip current ruleset.
2. Inside powershell navigate to folder containing the ruleset script you want, and execute individual Powershell script.

In both cases the script will delete all of the existing rules that match the rule group (if any), and load the rules from script
into Local Group Policy.

# Deleting rules
At the moment the easiest way is to select all the rules you want to delete in Local Group Policy, right click and delete.

# Manage loaded rules
There are 2 ways to manage your rules:
1. Using Local Group Policy, this method gives you limited freedom on what you can do whith the rules, such as disabling them or changing some attributes.
2. Editting Powershell scripts, this method gives you full control, you can improve the rules, add new ones or screw them up.

# Contribution
Feel free to contribute new rules, or improvements for existing rules or scripts.
Just make sure you follow existing code style.
