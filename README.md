
# About Windows Firewall Ruleset
- Windows firewall rules organized into individual powershell scripts according to:
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

- in addition to rules you will find a bunch of powershell functions to gather info relevant for building a firewall such as:
1. computers
2. installed programs
3. users on system
4. network configuration etc
- meaning this project is a good base to easily extend your firewall and include more rules.
- You can choose which rulles you want, and apply only those or apply them all with single command to your firewall.
- All the rules are loaded into Local group policy giving you full power over default windows firewall.
- Currently there are some 650+ firewall rules.

# What are the core benefits of this firewall/project?
1. Unlike normal windows firewall in control panel, these rules are loaded into GPO firewall (Local group policy), meaning random programs which install rules as part of their installation process or system settings changes will have no effect on firewall unless you explicitly make an exception, therefore you have full control over the firewall.
2. Unlike default windows firewall rules, these rules are much more restrictive such as, tied to explicit user accounts, rules apply to specific ports, network interfaces, specific programs, services etc.
3. Unlike default (or your custom) rules you will know which rules have no effect or are redundant due to ie. uninstalled program or a missing windows service which no longer exists or are redundant/invalid for what ever other reason.
4. Changing rule attributes such as ports, adresses and similar is so much easier since the rules are in scripts, so you can use editor tools such as CTRL + F to perform bulk operations on your rules, doing this in Windows firewall GUI is beyond all pain.
5. Default outbound is block unless there is a rule to explicitly allow traffic, in default windows firewall this is not possible unless you have rules for every possible windows program/service, thanks to this collection of rules setting default outbound to block requres very little additinoal work.

# Licenses
This project **"WindowsFirewallRuleset"** is licensed under **MIT** license.\
Subproject [Indented.Net.IP](https://github.com/indented-automation/Indented.Net.IP) (3rd party code) located in **"Modules\Indented.Net.IP"** subfolder is licensed under **ISC** license.\
Subproject [VSSetup](https://github.com/microsoft/vssetup.powershell) (3rd party code) located in **"Modules\VSSetup"** subfolder is licensed under **MIT** license.\
Various 3rd party scripts located in **"Utility"** subfolder have their own licenses.

License, Copyright notices and all material of subprojects is in their own folder.\
License and Copyright notices for this project is in project root folder.\
License, Copyright notices, and links, for "Utility" scripts are included into individual script files directly.

For more info see respective licences:\
[WindowsFirewallRuleset\LICENSE](https://raw.githubusercontent.com/metablaster/WindowsFirewallRuleset/master/LICENSE)\
[Indented.Net.IP\LICENSE](https://raw.githubusercontent.com/metablaster/WindowsFirewallRuleset/master/Modules/Indented.Net.IP/LICENSE)\
[VSSetup\LICENSE.txt](https://raw.githubusercontent.com/metablaster/WindowsFirewallRuleset/master/Modules/VSSetup/LICENSE.txt)\
[Utility\Licences](https://raw.githubusercontent.com/metablaster/WindowsFirewallRuleset/master/Utility/Licences/)

# Minimum system requirements
1. Windows 10 Pro/Enterprise, Windows Server 2019
2. Windows Powershell 5.1 [Download Powershell](https://github.com/PowerShell/PowerShell)
3. NET Framework 4.7 [Download Net Framework](https://dotnet.microsoft.com/download/dotnet-framework)
4. Git (Optional) [Download Git](https://git-scm.com/downloads)
5. Visual Studio Code (Optional) [Download VSCode](https://code.visualstudio.com)
6. PowerShell Support for VSCode (Optional) [Download extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode.PowerShell)

**If any of the requirements from point 1, 2 and 3 are not meet the scripts will refuse to run.**
Anniversary Update (Version 1607)
- All operating systems 10.0 (Major 10, Minor 0) and up are supported.
- Powershell is built into Windows by default, you will probably need to install it or update on different systems.
- NET Framework 4.7 is automatically installed (through Windwos update) on Windows 10 1607, in addition make sure you have [.NET 3.5 enabled](https://docs.microsoft.com/en-us/dotnet/framework/install/dotnet-35-windows-10), see control panel option.
- You may want to have git to check out for updates, to easily switch between branches or to contribute code.
- VS Code is preferred editor to edit the scripts for your needs or for contribution, any other editor is of course your choice.
- If you get VSCode, you'll also need powershell extension for syntax highliting and code navigation among other cool features.

# I don't have Windows 10 or Windows Server
**First, note that Home versions of Windows do not have GPO (Local Group Policy), therefore not possible to make use of this project.**

To be able to apply rules to older systems such as Windows 7 or Windows server 2008, you'll need to modify code.\
At a bare minimum you should do the following 4 modifications:

**Modification 1:**\
edit the `Modules\System\System.psm1` to allow execution for older system.

**Modification 2:**\
edit the `Modules\FirewallModule\FirewallModule.psm1` and define new variable that defines your system version, following variable is defined to target Windows 10.0 editions and above by default for all rules.\
```New-Variable -Name Platform -Option Constant -Scope Global -Value "10.0+""```

For example for Windows 7, define a new variable that looks like this:\
```New-Variable -Name PlatformWin7 -Option Constant -Scope Global -Value "6.1"```

`Platfrom` variable specifies which version of Windows the associated rule applies.\
The acceptable format for this parameter is a number in the Major.Minor format.

**Modification 3:**\
edit individual ruleset scripts, and take a look which rules you want or need to be loaded on that system,\
then simply replace ```-Platform $Platform``` with ```-Platform $PatformWin7``` for each rule you want.

In VS Code for example you can also simply (CTRL + F) for each script and replace all instances. very simple.\
If you miss something you can delete, add or modify rules in GPO later.

Note that if you define your platform globaly (ie. ```$Platform = "6.1"```) instead of making your own variable, just replacing the string, but do not exclude unrelated rules, most of the rules should work, but ie. rules for Store Apps will fail to load.\
Also ie. rules for programs and services that do not exist on system will be most likely applied but redundant.

What this means, is, just edit the GPO later to refine your imports if you go that route, or alternatively revisit your edits and re-run individual scripts again.

**Modification 4:**\
Visit `Test` folder and run all tests individually to confirm modules and their functions work as expected, any failure should be fixed.

# Step by step quick start

**WARNING:**
- You may loose internet conectivity for some of your programs or in rare cases even lose internet conectivity completely, if that happens, you can run `ResetFirewall.ps1` to reset firewall to previous state and clear GPO firewall.
- Inside the Readme folder there is a `ResetFirewall.md`, a guide on how to do it manually, by hand, if for some reason you're unable to run the script, or the script does not solve your problems.
- Also note that your current/existing rules will not be deleted unless you have rules in GPO whose group name interfere with group names from this ruleset.
- To be 100% sure please export your current GPO rules first, (if you don't know to do that, then you most likely don't have GPO rules)
- The script will ask you what rules you want, to minimize internet connectivity trouble you should apply at least all generic networking and OS related rules such as BasicNetworking, ICMP, WindowsSystem, WindowsServices, Multicast etc. also do not ignore IPv6, Windows really depends on these!

**NOTE:**
- If you would like to modify basic behavior of execution, such as force loading rules and various default actions then visit `Modules` folder, open each module, scroll down and there you'll find global variables which are used for this.
- If you're running scripts for first time it's higly recommended to load all rules, it should be easy to delete what you do not wan't in GPO, rather than later searching scripts for what you may have missed.
- Loading rules into an empty GPO should be very fast, however loading into GPO which already contains rules will be significally slower (depends on number of existing rules)
- All errors and warnings will be saved to `Logs` directory, so you can review these logs if you want to fix some problem.
- Any rule that results in "Access denied" while loading should be reloaded by executing specific script again.

**STEPS:**
1. If you don't have ssh keys and other setup required to clone then just download the zip file by clicking on green "Clone or download" button here on this site.
2. extract the archive somewhere, this steps assume you've extracted the zip into `C:\` root drive directly.
3. Right click on the Task bar and select `Taskbar settings`
4. Toggle on `Replace Command Prompt with Windows Powershell in the menu when I right click the start button`
5. Right click on Start button in Windows system
6. Click `Windows Powershell (Administrator)` to open Powershell as Administrator (Input Admin password if needed)
7. Type: (or copy paste command(s) and hit enter) ```Get-ExecutionPolicy``` and remeber what the ouput is.
6. Type: ```Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Unrestricted -Force```
7. Type: ```cd C:\```
8. Type: ```cd WindowsFirewallRuleset-master``` (ofcourse if extracted folder name is something else then update this command)
9. Rules for programs such as internet browser, Visual Studio etc. depend on installation variables.\
Most paths are auto-searched and variables are updated, otherwise you get warning and description on how to fix the problem,
If needed, you can find these installation variables in individual scripts inside `Rules` folder.
10. Back to Powershell console and type into console: ```.\SetupFirewall.ps1``` and hit enter (You will be asked what kind of rulesets you want)
11. Follow prompt output, (ie. hit enter each time to proceed until done), it will take at least 10 minutes of your attention.
12. If you encounter errors or warnings, you have several options such as, ignore the errors/warnings or update script that produced the error and re-run that script once again later.
13. Once execution is done recall execution policy from step 5 and type: (ie. if it was "RemoteSigned" which is default)\
```Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force```
14. Now that rules are applied you may need to adjust some of them in Local Group Policy, not all the rules are enabled by default and you may want to toggle default Allow/Block behavior for some rules, rules for programs which do not exist need to be made additionally.\
See next sections for more info.
15. If you're unable to connect to internet, you can temporarly open outbound firewall in GPO, that should work, if not, reset firewall as explained before.

# Where are my rules?
Rules are loaded into Local group policy, follow bellow steps to open local group policy.
1. Press Windows key and type: `secpol.msc`
2. Righ click on `secpol.msc` and click `Run as administrator`
3. Expand node: `Windows Defender Firewall with Advanced Security`
4. Expand node: `Windows Defender Firewall with Advanced Security - Local Group Policy Object`
5. Click on either `Inbound` or `Outbound` node to view and manage the rulles you applied with Powershell script.

# Applying individual rulesets
If you want to apply only specific rules there are 2 ways to do this:
1. Execute `SetupFirewall.ps1` and hit enter only for rullesets you want, otherwise type `n` and hit enter to skip current ruleset.
2. Inside powershell navigate to folder containing the ruleset script you want, and execute individual Powershell script.
3. You may want to run `FirewallProfile.ps1` to apply default firewall behavior, or you can do it manually in GPO.

In both cases the script will delete all of the existing rules that match the rule group (if any), and load the rules from script
into Local Group Policy.

# Deleting rules
At the moment the easiest way is to select all the rules you want to delete in Local Group Policy, right click and delete.\
To revert to your old firewall state, you will need to delete all the rules from GPO, and set all properties to "Not configured" when right clicking on node `Windows Defender Firewall with Advanced Security - Local Group Policy Object`\
Deleting all rules or reveting to previsous state can be done with `ResetFirewall.ps1` script.

# Manage loaded rules
There are 2 ways to manage your rules:
1. Using Local Group Policy, this method gives you basic freedom on what you can do whith the rules, such as disabling them or changing some attributes.
2. Editting Powershell scripts, this method gives you full control, you can improve the rules, add new ones or screw them up.

What ever your setup is, you will surelly need to perform additinal work such as adding more rules in GPO to allow programs for which rules do not exist, or to reconfigure existing rules.

# Checking for updates
This repository consists of 2 branches, "master" and "develop", develop (unstable) branch is the most recent one and is the one where all commits (updates) directly go so it's beta product, unlike master branch which is updated from develop branch once in a while and
not before all scripts are fully tested, meaning master brach is stable.

So if you're fine to experiment with development/beta version switch to "develop" branch and try it out, otherwise stick to master if for example development version produces errors for you.

There are two methods to be up to date with firewall:
1. First method requires you to download scripts, first use the "branch" button here on this site to switch to either master or develop branch, next use "Clone or download" button and either downlaod zip file or copy clone link and make a new clone.

2. Second method is good if you want to do it in powershell console without visiting this site, you will need git (link above), github account and [SSH key](https://help.github.com/en/github/authenticating-to-github/adding-a-new-ssh-key-to-your-github-account) to check for new updates on daily, weekly or what ever other basis you want, follow bellow steps to check for updates once you installed git:
- Right click on Start button in Windows system
- Click `Windows Powershell` to open Powershell
- First navigate to folder where your instance of WindowsFirewallRuleset instance is, for example:
- Type: `dir` to list directories, ```cd SomeDirectoryName``` to move to some directory or ```cd ..``` to go one directory back
- Type: (or copy paste command(s) and hit enter) ```cd WindowsFirewallRuleset``` to move into WindowsFirewallRuleset folder
- This command is typed only once for initial setup:\
```git remote add upstream https://github.com/metablaster/WindowsFirewallRuleset```
- Following 2 sets of commands are typed each time, to tell git you want updates from master (stable) branch:
- Type: ```git checkout master```
- Type: ```git fetch upstream```
- Type: ```git merge upstream/master```
- Following commands are to tell git you want updates from develop (unstable/beta) branch
- Type: ```git checkout develop```
- Type: ```git fetch upstream```
- Type: ```git merge upstream/develop```

Of course you can switch to from one branch to another with git in powershell as many times as you want and all files will be auto updated without the need to redownload or re-setup anything.\
That's it, your scripts are now up to date, execute them as you desire (or follow steps from "Quick start" section) to apply changes to your firewall.

# Contribution or suggestions
Bellow are general notes regarldess if you're developer or just a user.\
If you would like to contribute by writing scripts you should also read [CONTRIBUTION.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Readme/CONTRIBUTION.md)

Feel free to suggest or contribute new rules, or improvements for existing rules or scripts.\
Just make sure you follow existing code style, as follows:
1. Note that each rule uses exactly the same order or paramters split into exactly the same number of lines.\
This is so that when you need to search for something it's easy to see what is where right away.
2. Provide documentation and official reference for your rules so that it can be easy to verify that these rules do not contain mistakes, for example, for ICMP rules you would provide a link to [IANA](https://www.iana.org) with relevant reference document.
3. If you would like to suggest new rules or improving existing ones, but you can't push an update here, please open new issue here on github and provide details prefferably with documentation.
4. To contribute rules, it is also important that each rule contains good description of it's purpose, when a user clicks on a rule in firewall GUI he wants to see what this rule is about and easily conclude whether to enable/disable the rule or allow/block the traffic.
5. It is also important that a rule is very specific and not generic, that means specifying protocol, IP addresses, ports, system user, interface type and other relevant information.\
for example just saying: allow TCP outbound port 80 for any address or any user or no explanation what is this supposed to allow or block is not acceptable.

# More information and help
Inside the [Readme](https://github.com/metablaster/WindowsFirewallRuleset/tree/master/Readme) folder you will find usefull information not only about this project but also general information on how to troubleshoot firewall and network problems, or gather more relevant information.

It may answer some of your questions, you should go ahead and read it!\
btw. It's recommended you read those papers here on github because of formatting and screenshots.
