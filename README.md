
# About Windows Firewall Ruleset

- Windows firewall rules sorted into individual powershell scripts according to:

1. Rule group
2. Traffic direction
3. IP version (IPv4 / IPv6)
4. Further sorted according to programs and services

- Such as for example:

1. ICMP traffic
2. Browser rules
3. Rules for Windows system
4. Store apps
5. Windows services
6. Microsoft programs
7. 3rd party programs
8. broadcast traffic
9. multicast traffic
10. and the list goes on...

- In addition to firewall rules you will find a number of powershell modules,
scripts and functions used to gather info relevant for building a firewall such as:

1. computers on network
2. installed programs
3. users on system
4. network configuration
5. managing firewall etc.

- Meaning this project is a good base to easily extend your firewall and include more rules.
- Currently there are some 650+ firewall rules included, 9 modules with 50+ functions,
random scripts and useful documentation.
- You can choose which rules you want, and apply only those or apply them all with
master script to your firewall.
- All the rules are loaded into Local Group Policy (GPO),
giving you full power over the default windows firewall.

## What are the core benefits of this firewall/project?

1. Unlike windows firewall in control panel, these rules are loaded into GPO firewall
(Local group policy), meaning random programs which install rules as part of their installation
process or system settings changes will have no effect on firewall unless you
explicitly make an exception.

2. Unlike default windows firewall rules, these rules are more restrictive such as,
tied to explicit user accounts, rules apply to specific ports,
network interfaces, specific programs, services etc.

3. Unlike default (or your own) rules you will know which rules have no effect or are redundant
due to ie. uninstalled program or a missing windows service which no longer exists or are
redundant/invalid for what ever other reason.

4. Changing rule attributes such as ports, addresses and similar is much easier since the rules
are in scripts, so you can use editor tools such as CTRL + F to perform bulk operations on
your rules, doing this in Windows firewall GUI is beyond all pain.

5. Default outbound is "block" unless there is a rule to explicitly allow traffic,
in default windows firewall this is not possible unless you have rules for every possible
program/service, thanks to this collection of rules setting default outbound to block
requires very little additional work.

## Licenses

This project **"Windows Firewall Ruleset"** is licensed under **MIT** license.\
3rd party and sublicensed code is located inside their own folders for organizational purposes,
usually called "External".

The project maintains "per file" licenses and Copyright notices.

## Minimum supported system requirements

1. Windows 10 Pro/Enterprise, Windows Server 2019 (64 bit)
2. Powershell Core 7.0 or Windows PowerShell 5.1
[Download Powershell](https://github.com/PowerShell/PowerShell)
3. NET Framework 3.5 (for Windows PowerShell)
[Download Net Framework](https://dotnet.microsoft.com/download/dotnet-framework)
4. Git (Optional) [Download Git](https://git-scm.com/downloads)
5. Visual Studio Code (Optional) [Download VSCode](https://code.visualstudio.com)
6. PowerShell Support for VSCode (Optional)
[Download extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode.PowerShell)

- All operating systems 10.0 (Major 10, Minor 0) and up are supported,
that includes "regular" Windows, Servers etc.
- PowerShell core is not built into Windows, you will need to install it separately.
- NET Framework 3.5 is automatically installed on Windows, to make sure you have
[.NET 3.5 enabled](https://docs.microsoft.com/en-us/dotnet/framework/install/dotnet-35-windows-10),
see control panel option on that link.
- You may want to have git to check out for updates,
to easily switch between branches or to contribute code.
- VS Code is preferred and recommended editor to navigate project and edit the scripts for your
needs or for contribution, any other editor is of course your choice.
- If you get VSCode, you'll also need powershell extension for code navigation and
PowerShell specific features.

## I don't have Windows 10 or Windows Server (64 bit)

By default this project is tested and designed for most recent Windows/Servers and that is known
to work, making use of it on older systems requires additional work.

Testing is done on 64 bit windows, a small fraction of rules won't work for 32 bit system and
need adjustment, full functionality for 32 bit system is work in progress.\
For now you can load rules on 32 bit system just fine with the exception of few rules probably not
relevant at all for your configuration. (It's hard to tell since it wasn't tested)

The plan is to expand this project to manage [nftables](https://en.wikipedia.org/wiki/Nftables)
firewall on linux and other systems, but not anytime soon.

[This document](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Readme/LegacySupport.md)
describes how to make use of this project on older Windows systems such as Windows 7 or Server 2008

## Step by step quick start

**WARNING:**

- You may loose internet connectivity for some of your programs or in rare cases even lose internet
connectivity completely, if that happens, you can either temporarily allow outbound rules or run
`ResetFirewall.ps1` script, to reset GPO firewall to system defaults and remove all rules.
- Inside `Readme` folder there is a `ResetFirewall.md`, a guide on how to do it manually, by hand,
if for some reason you're unable to run the script, or the script does not solve your problems.
- Also note that your current/existing rules will not be deleted unless you have rules in GPO whose
group name interfere with group names from this ruleset, however
**this does not apply to** `ResetFirewall.ps1` which will clear GPO rules completely
and leave only those in control panel.
- If you want to be 100% sure please export your current GPO rules first, for more info see
[ManageGPOFirewall.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Readme/ManageGPOFirewall.md)
- The scripts will ask you what rules you want, to minimize internet connectivity trouble you should
apply at least all generic networking and OS related rules such as BasicNetworking, ICMP,
WindowsSystem, WindowsServices, Multicast etc. also do not ignore IPv6, Windows does need IPv6!
- Default configuration will set global firewall behavior which is not configurable in GPO GUI,
such as stateful ftp and pptp or global IPSec settings, if you need specific setup please visit
`SetupProfile.ps1` and take a look at `Set-NetFirewallSetting`.\
Note that `SetupProfile.ps1` is automatically called by `SetupFirewall.ps1` script

**NOTE:**

- If you would like to modify basic behavior of execution, such as force loading rules and various
default actions then visit `Config\ProjectSettings.ps1` and there you'll find global variables
which are used for this.
- If you're running scripts for the first time it's highly recommended to load all rules for which you
have programs installed on system,
it should be easy to delete what you do not want in GPO, rather than later searching scripts for
what you may have missed.
- Loading rules into an empty GPO should be very fast, however loading into GPO which already
contains rules will be significantly slower (depends on number of existing rules)
- All errors and warnings will be saved to `Logs` directory, so you can review these logs if you
want to fix some problem.
- Any rule that results in "Access denied" while loading should be reloaded by executing specific
script again.
- Master script `SetupFirewall.ps1` will [unblock all files](https://devblogs.microsoft.com/scripting/easily-unblock-all-files-in-a-directory-using-powershell/)
in project first to avoid YES/NO questions spam for every executing script, you should "unblock"
files manually if executing individual scripts after manual download or transfer from
another computer or media by using `UnblockProject.ps1` script.

**STEPS:**

1. If you don't have ssh keys and other setup required to clone via SSH then either clone with HTTPS
or just download the released zip file by clicking on "Release" here on this site.\
These steps assume you have downloaded a zip file.
2. Extract the archive somewhere, these steps assume you've extracted the zip into
`C:\` root drive directly.
3. Open the extracted folder, right click into an empty space and there is an option to run
PowerShell core as administrator (Assumes enabled context menu during installation of PowerShell core)
4. If you would like to use Windows PowerShell 5.1 instead see
[WindowsPowerShell](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Readme/WindowsPowerShell.md)
5. Type or copy/paste following commands and hit enter for each

```powershell
Get-ExecutionPolicy
```

Remember what the output of the above command is, note that PowerShell Core defaults to `RemoteSigned`
while Windows PowerShell defaults to `Restricted`

6. Set new execution policy: (Note that `RemoteSigned` should work too)

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Unrestricted -Force
```

7. Move to C root drive, this is where you extracted your downloaded zip file:

```powershell
cd C:\
```

8. cd into that folder, of course rename the command if your extracted folder is called something else:

```powershell
cd WindowsFirewallRuleset-master
```

9. At this point you should "unblock" all project files first by executing the script called
`UnblockProject.ps1`, btw. project files were blocked by Windows to prevent users from running
untrusted script code downloaded from internet:

```powershell
.\UnblockProject.ps1
```

9. Rules for programs such as internet browser, Visual Studio etc. depend on installation variables.\
Most paths are auto-searched and variables are updated, otherwise you get warning and description
on how to fix the problem,
If needed, you can find these installation variables in individual scripts inside `Rules` folder.

10. Back to Powershell console and type into console:

```powershell
.\SetupFirewall.ps1
```

hit enter and you will be prompted what kind of rulesets you want.

11. Follow prompt output, (ie. hit enter each time to proceed until done),
it will take at least 10 minutes of your attention.

12. If you encounter errors or warnings, you have several options such as, ignore the errors/warnings
or update script that produced the error and re-run that script once again later.

13. Once execution is done recall execution policy from step 5 and type:
(ie. if it was "RemoteSigned" which is default for PowerShell Core)

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
```

14. Now that rules are applied you may need to adjust some of them in Local Group Policy,
not all the rules are enabled by default and you may want to toggle default Allow/Block behavior for
some rules, rules for programs which do not exist need to be made additionally.

15. If you're unable to connect to internet, you can temporarily open outbound firewall in GPO,
that should work, if not and you're unable to troubleshoot the problem,
then reset firewall as explained before and take a look into `Readme` folder.

## Where are my rules?

Rules are loaded into Local group policy, follow below steps to open local group policy.

1. Press Windows key and type: `secpol.msc`
2. Right click on `secpol.msc` and click `Run as administrator`
3. Expand node: `Windows Defender Firewall with Advanced Security`
4. Expand node: `Windows Defender Firewall with Advanced Security - Local Group Policy Object`
5. Click on either `Inbound` or `Outbound` node to view and manage the rules
you applied with Powershell script.

## Applying individual rulesets

If you want to apply only specific rules there are 2 ways to do this:

1. Execute `SetupFirewall.ps1` and hit enter only for rulesets you want, otherwise type `N`
and hit enter to skip current ruleset.

2. Inside powershell navigate to folder containing the ruleset script you want,
and execute individual Powershell script.

3. You may want to run `SetupProfile.ps1` to apply default firewall behavior if it's not set
already, or you can do it manually in GPO but with limited power.
"limited power" means `SetupProfile.ps1` configures some firewall parameters which can't be
adjusted in firewall GUI.

In both cases the script will delete all of the existing rules that match the rule group (if any),
and load the rules from script
into Local Group Policy.

## Deleting rules

At the moment the easiest way is to select all the rules you want to delete in Local Group Policy,
right click and delete.

To revert to your old firewall state (the one in control panel), you will need to delete all the
rules from GPO,\
and set all properties to `"Not configured"` when right clicking on node:\
`Windows Defender Firewall with Advanced Security - Local Group Policy Object`

Deleting all rules or revetting to previous state can also be done with `ResetFirewall.ps1` script.

Note that you will also need to re-import your exported GPO rules if you had them.

## Manage loaded rules

There are 2 ways to manage your rules:

1. Using Local Group Policy, this method gives you basic freedom on what you can do with the rules,
such as disabling them or changing some attributes. For more information see
[ManageGPOFirewall.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Readme/ManageGPOFirewall.md)
2. Editing Powershell scripts, this method gives you full control, you can improve the rules,
add new ones or screw them up.

What ever your setup is, you will surely need to perform additional work such as adding more rules
in GPO to allow programs for which rules do not exist, or to reconfigure existing rules.

## Checking for updates

This repository consists of 2 branches, `master` and `develop`, develop (unstable) branch is
the most recent one and is the one where all commits (updates) directly go so it's beta product,
unlike master branch which is updated from develop branch once in a while and
not before all scripts are fully tested, meaning master brach is stable.

So if you're fine to experiment with development/beta version switch to "develop" branch and try
it out, otherwise stick to master if for example development version produces errors for you.

There are two methods to be up to date with firewall:

1. First method requires you to download scripts, first use the "branch" button here on this site to
switch to either master or develop branch, next use "Clone or download" button and download zip file.

2. Second method is good if you want to do it in powershell console without visiting this site,
you will need git (link above), github account, a fork of this repository in your account and optionally
[SSH key](https://help.github.com/en/github/authenticating-to-github/adding-a-new-ssh-key-to-your-github-account)
to check for new updates on daily, weekly or what ever other basis you want,
follow below steps to check for updates once you installed git and cloned your own fork:

- Right click on Start button in Windows system
- Click `Windows Powershell` to open Powershell
- First navigate to folder where your instance of WindowsFirewallRuleset instance is, for example:
- Type: `dir` to list directories, ```cd SomeDirectoryName``` to move to some directory or
```cd ..``` to go one directory back
- Type: (or copy paste command(s) and hit enter) ```cd WindowsFirewallRuleset```
to move into WindowsFirewallRuleset folder
- Following command (SSH) is typed only once for initial setup:

```git remote add upstream git@github.com:metablaster/WindowsFirewallRuleset.git```

Otherwise if you cloned your fork via HTTPS and want HTTPS (no SSH), then:

```git remote add upstream https://github.com/metablaster/WindowsFirewallRuleset.git```

- Following 2 sets of commands are typed each time,
to tell git you want updates from master (stable) branch:
- Type: ```git checkout master```
- Type: ```git fetch upstream```
- Type: ```git merge upstream/master```

- Following commands are to tell git you want updates from develop (unstable/beta) branch
- Type: ```git checkout develop```
- Type: ```git fetch upstream```
- Type: ```git merge upstream/develop```

Of course you can switch to from one branch to another with git in powershell as many times as you
want and all files will be auto updated without the need to re-download or re-setup anything,
for more info see [git documentation](https://git-scm.com/doc)

That's it, your scripts are now up to date, execute them as you desire (or follow steps from
"Quick start" section) to apply changes to your firewall.

## Contributing or suggestions

Below are general notes for requesting to add your rules or ideas about rules to project.\
If you would like to contribute by writing scripts you should read
[CONTRIBUTING.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/CONTRIBUTING.md)
instead.

Feel free to suggest or contribute new rules, or improvements for existing rules or scripts.\
Just make sure you follow below notices:

1. Provide some documentation or official reference for your rules so that it can be easy to verify
that these rules do not contain mistakes, for example, for ICMP rules you would provide a link to
[IANA](https://www.iana.org) with relevant reference document.
2. If you would like to suggest new rules or improving existing ones,
but you can't push an update here, please open new issue here on github and provide details
preferably with documentation.
3. To contribute rules, it is also important that each rule contains good description of it's
purpose, when a user clicks on a rule in firewall GUI he wants to see what this rule is about and
easily conclude whether to enable/disable the rule or allow/block the traffic.
4. It is also important that a rule is very specific and not generic, that means specifying protocol,
IP addresses, ports, system user, interface type and other relevant information.\
for example just saying: allow TCP outbound port 80 for any address or any user or no explanation
what is this supposed to allow or block is not acceptable.

## More information and help

Inside the [Readme](https://github.com/metablaster/WindowsFirewallRuleset/tree/master/Readme)
folder you will find useful information not only about this project but also general information on
how to troubleshoot firewall and network problems, or gather more relevant information.

It may answer some of your questions, for example
[MonitoringFirewall.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Readme/MonitoringFirewall.md)
explains how to monitor firewall in real time, you should go ahead and read it!\
It's recommended you read those documents here on github because of formatting and screenshots.
