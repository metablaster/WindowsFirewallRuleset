## WindowsFirewallRuleset

# About WindowsFirewallRuleset
- Windows firewall rulles organized into individual powershell scripts according to:
1. Rule group
2. Traffic direction
3. IP version (IPv4 / IPv6)
4. Further sorted according to programs and services

- such as for example:
2. ICMP traffic
3. Browser rules
4. rules for Windows system
5. Store apps
6. Windows services
7. Microsoft programs
8. 3rd party programs
9. broadcast traffic
10. multicast traffic
11. and the list goes on... 

- You can choose which rulles you want, and apply only those or apply them all with single command to your firewall.
- All the rules are loaded into Local group policy giving you full power over default windows firewall.

This project **"WindowsFirewallRuleset"** is licensed under **MIT** license.\
Subproject **"Indented.Net.IP"** (3rd party code) located in "Indented.Net.IP" subfolder is licensed under **ISC** license.

License, Copyright notices and all material of subproject is in it's own folder\
License and Copyright notices for this project is in project root folder

For more info see respective licences:\
[LICENSE](https://raw.githubusercontent.com/metablaster/WindowsFirewallRuleset/master/LICENSE)\
[Indented.Net.IP\LICENSE](https://raw.githubusercontent.com/metablaster/WindowsFirewallRuleset/master/Indented.Net.IP/LICENSE)

# Minimum system requirements
1. Windows 10 Pro/Enterprise
2. Windows Powershell 5.1 [Download Powershell](https://github.com/PowerShell/PowerShell)
3. Git (Optional) [Download Git](https://git-scm.com/downloads)

Note that Powershell is built into Windows by default, you will probably need to install it or update on some old systems.

To be able to apply rules to older systems such as Windows 7, edit the `GlobalVariables.ps1` and add a new variable that defines your system version:

```$Platform = "10.0+" #Windows 10 and above``` is defined to target Windows 10 and above by default for all rules, for example for Windows 7, define a new variable that looks like this:

```$PlatformWin7 = "6.1" #Windows 7```

Next you open individual ruleset scripts, and take a look which rules you want to be loaded into your firewall,\
then simply replace ```-Platform $Platform``` with ```-Platform $PatformWin7``` for each rule you want.

In VS Code for example you would simply (CTRL + F) for each script and replace all instances. very simple.

If you miss something you can delete, add or modify rules in GPO later.

Note that if you define your platform globaly (ie. ```$Platform = "6.1"```) instead of making your own variable, just replacing the string, but do not exclude unrelated rules, most of the rules will work, but ie. rules for Store Apps will fail to load.\
Also ie. rules for programs and services that were introduced in Windows 10 will be most likely applied but redundant.

What this means, is, just edit the GPO later to refine your imports if you go that route.

In any case, new system or old, **know that Home versions of Windows do not have GPO (Local Group Policy), therefore not possible to make use of this project.**

# Step by step quick start

**WARNING:**
- these steps here are for somebody who doesn't know how to use `git`, `Powershell` or `Local group policy`
- You may loose internet conectivity for some of your programs or in rare cases even lose internet conectivity completely, if that happens, you can run `ResetFirewall.ps1` to reset firewall to previous state.
- Inside the Readme folder there is a `ResetFirewall.md`, a guide on how to do it manually, by hand, if for some reason you're unable to run the script, or the script does not solve your problems.
- Also note that your current/existing rules will not be deleted unless you have rules in GPO whose group name interfere with group names from this ruleset.
- to be 100% sure please export your current GPO rules first, (if you don't know to do that, then ignore this, you don't have GPO rules)

**STEPS:**
1. Right click on the Task bar and select `Taskbar settings`
2. Toggle on `Replace Command Prompt with Windows Powershell in the menu when I right click the start button`
3. Right click on Start button in Windows system
4. Click `Windows Powershell (Administrator)` to open Powershell as Administrator (Input Admin password if needed)
5. Type: (or copy paste command) ```Get-ExecutionPolicy``` and remeber what the ouput is.
6. Type ```Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Unrestricted -Force```
7. Type: ```cd C:\```
8. Copy paste into console: ```git clone git@github.com:metablaster/WindowsFirewallRuleset.git``` and hit enter
9. Copy paste into console: ```cd WindowsFirewallRuleset``` and hit enter
10. Open file explorer and navigate to `C:\WindowsFirewallRuleset\Modules`
11. Open `GlobalVariables.ps1` with your preffered code editor such as VS Code or Powershell ISE
12. Edit the line `$UserName = "User"`, input your username by replacing "User" with your username,
for example if your username is Patrick the line should look like `$UserName = "Patrick"`
13. Save and close the Powershell script file.
14. Back to Powershell console and copy paste into console: ```.\Main.ps1``` and hit enter (this will load all the rulles)
15. Follow prompt output, (ie. hit enter each time to proceed until done), it will take at least 10 minutes of your attention.
16. If you encounter errors, you have several options such as, ignore the errors or fix the script that produced the error and re-run that script only once again later.
17. Once execution is done recall execution policy from step 5 and type:\
```Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force``` (if previous policy was "RemoteSigned")

# Where are my rules?
Rules are loaded into Local group policy, follow bellow steps to open local group policy.
1. Press Windows key and type: `secpol.msc`
2. Righ click on `secpol.msc` and click `Run as administrator`
3. Expand node: `Windows Defender Firewall with Advanced Security`
4. Expand node: `Windows Defender Firewall with Advanced Security - Local Group Policy Object`
5. Click on either `Inbound` or `Outbound` node to view and manage the rulles you applied with Powershell script.

# Applying individual rulesets
If you want to apply only specific rules there are 2 ways to do this:
1. Execute `Main.ps1` and hit enter only for rullesets you want, otherwise type `n` and hit enter to skip current ruleset.
2. Inside powershell navigate to folder containing the ruleset script you want, and execute individual Powershell script.

In both cases the script will delete all of the existing rules that match the rule group (if any), and load the rules from script
into Local Group Policy.

# Deleting rules
At the moment the easiest way is to select all the rules you want to delete in Local Group Policy, right click and delete.\
To revert to your old firewall state, you will need to delete all the rules from GPO, and set all properties to "Not configured" when right clicking on node `Windows Defender Firewall with Advanced Security - Local Group Policy Object`

# Manage loaded rules
There are 2 ways to manage your rules:
1. Using Local Group Policy, this method gives you limited freedom on what you can do whith the rules, such as disabling them or changing some attributes.
2. Editting Powershell scripts, this method gives you full control, you can improve the rules, add new ones or screw them up.

# Contribution or suggestions
Feel free to suggest or contribute new rules, or improvements for existing rules or scripts.\
Just make sure you follow existing code style, as follows:
1. Note that each rule uses exactly the same order or paramters split into exactly the same number of lines.\
This is so that when you need to search for something it's easy to see what is where right away.
2. Provide documentation and official reference for your rules so that it can be easy to verify that these rules do not contain mistakes, for example, for ICMP rules you would provide a link to [IANA](https://www.iana.org/) with relevant reference document.
3. If you would like to suggest new rules or improving existing ones, but you do not have the skills to upload an update here, please open new issue here on github and provide details prefferably with documentation.
4. To contribute rules, it is also important that each rule contains good description of it's purpose, when a user clicks on a rule in firewall GUI he wants to see what this rule is about and easily conclude whether to enable/disable the rule or allow/block the traffic.
5. It is also important that a rule is very specific and not generic, that means specifying protocol, IP addresses, ports, system user, interface type and other relevant information.\
for example just saying: allow TCP outbound port 80 for any address or any user or no explanation what is this supposed to allow or block is not acceptable.

# More information and help
Inside the Readme folder you will find very usefull information not only about this project but also general information on how to troubleshoot problems, or gather more information.\
It may answer some of your questions, you should go ahead and read it!\
btw. I recommend you read those papers on github because of formatting and screenshots.

