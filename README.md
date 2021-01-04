
# Windows Firewall Ruleset

![Alt Text][corporate firewall]

## Table of Contents

- [Windows Firewall Ruleset](#windows-firewall-ruleset)
  - [Table of Contents](#table-of-contents)
  - [About Windows Firewall Ruleset](#about-windows-firewall-ruleset)
  - [Core benefits of this firewall project](#core-benefits-of-this-firewall-project)
  - [License](#license)
  - [Requirements](#requirements)
    - [Requirements details](#requirements-details)
    - [I don't meet the requirements](#i-dont-meet-the-requirements)
  - [First time user](#first-time-user)
    - [Warning](#warning)
    - [Note](#note)
    - [Quick start](#quick-start)
  - [Firewall management](#firewall-management)
    - [Manage loaded rules](#manage-loaded-rules)
    - [Applying individual rulesets](#applying-individual-rulesets)
    - [Deleting rules](#deleting-rules)
    - [Export\Import rules](#exportimport-rules)
  - [Checking for updates](#checking-for-updates)
    - [Manual release download](#manual-release-download)
    - [Manual beta download](#manual-beta-download)
    - [Using GitHub Desktop app](#using-github-desktop-app)
    - [Using git command](#using-git-command)
    - [Which update method is the best](#which-update-method-is-the-best)
  - [Contributing or suggestions](#contributing-or-suggestions)
  - [Customization](#customization)
  - [More information and help](#more-information-and-help)
  - [The future](#the-future)

## About Windows Firewall Ruleset

- Windows firewall rules sorted into individual PowerShell scripts according to:

  - Rule group
  - Traffic direction (ex. inbound, outbound or IPSec)
  - Software type
  - IP version (IPv4 / IPv6)

- Such as for example:

  - ICMP traffic
  - Browser rules
  - Rules for Windows system
  - Store apps
  - Windows services
  - Multiplayer Games
  - Microsoft programs
  - 3rd party programs
  - broadcast traffic
  - multicast traffic

- In addition to firewall rules you will find a number of PowerShell modules, scripts and
functions used to gather environment info relevant to build specialized firewall such as:

  - Computers on network
  - Installed programs
  - IP subnet math
  - Remote or local system users
  - Network configuration
  - Firewall management
  - Quick analysis of packet trace and audit logs
  - Various firewall, system and network utility functions

- Meaning this project is a good base to easily extend your firewall and include more rules and
functionalities.
- Currently there are some 800+ firewall rules, 10+ modules with 100+ functions, several scripts
and a bunch of useful documentation.
- You can choose which rules you want, and apply only those or apply them all with
master script to your firewall.
- All of the rules are loaded into GPO (Local Group Policy),
giving you full power over the default Windows firewall.

[Table of Contents](#table-of-contents)

## Core benefits of this firewall project

1. System administrators would usually try to evade setting up firewall because detailed firewall
configuration is very time consuming process, takes a lot of troubleshooting, changes require
testing and security auditing and it only gets worse if you want to deploy firewall to hundreds or
thousands of remote computers, for example not all computers might have same software or restriction
requirements.

2. Unlike firewall rules in control panel, these rules are loaded into GPO firewall
(Local group policy), meaning system settings changes or random programs which install rules as
part of their installation process will have no effect on firewall unless you
explicitly make an exception.

3. Unlike default (aka predefined) Windows firewall rules, these rules are more restrictive such as,
tied to explicit user accounts, rules apply to specific ports, network interfaces, specific executables,
services etc. all of which is learned automatically from target system.

4. Unlike in usual scenario, you will know which rules have no effect or are redundant
due to ex. uninstalled program, a missing system service which no longer exists, renamed
executable after Windows update or are redundant/invalid for what ever other reason.

5. Updating, filtering or sorting rules and attributes such as ports, addresses and similar is much
easier since these rules are in scripts, you can use editor tools such as `CTRL + F`, regex or
multicursor to perform bulk operations on your rules, doing this in Windows firewall GUI is beyond
all pain or not possible due to interface limitations.

6. Default outbound is "block" unless there is a rule to explicitly allow network traffic,
in default Windows firewall this is not possible unless you maintain rules for every possible
program or service, thanks to this collection of rules, setting default outbound to block
requires very little or no additional work.

7. A good portion of code is dedicated to provide cross platform and automated solution to build and
define firewall specialized for specific target system and users, minimizing the need to do something
manually thus saving you much valuable administration time.

[Table of Contents](#table-of-contents)

## License

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](/LICENSE)

This project `Windows Firewall Ruleset` is licensed under `MIT` license.

License files and and Copyright notices are maintained **"per file"**.

3rd party and sublicensed code is located either inside their own folders (with individual license file)\
or inside folders called `External` for organizational purposes.

[Table of Contents](#table-of-contents)

## Requirements

Following table lists currently tested operating systems

| OS                  | Edition       | Build       | Architecture |
| ------------------- | ------------- | ----------- | ------------ |
| Windows 10          | Pro           | 1809 - 20H2 | x64          |
| Windows 10          | Pro Education | 20H2        | x64          |
| Windows 10          | Enterprise    | 1809 - 20H2 | x64          |
| Windows 10          | Education     | 20H2        | x64          |
| Windows Server 2019 | Standard      | 1809        | x64          |
| Windows Server 2019 | Datacenter    | 1809        | x64          |

***

1. Windows PowerShell 5.1 or PowerShell Core 7.1 [Download PowerShell Core][download core]
2. .NET Framework 4.5 (Windows PowerShell only) [Download Net Framework][download .net]
3. Git (Optional) [Download Git][download git]
4. Visual Studio Code (Recommended) [Download VSCode][vscode]
5. PowerShell Support for VSCode (Recommended) [Download extension][download powershell extension]
6. PSScriptAnalyzer (Recommended) [Download PSScriptAnalyzer][module psscriptanalyzer]

### Requirements details

- All operating systems 10.0 (Major 10, Minor 0) and above are supported,
but only those editions listed in the table are actively tested.\
Build column indicates tested releases, however only latest builds continue to be tested.\
A list of other untested but supported systems and features is in [The future](#the-future)
- PowerShell "Core" is not built into Windows, you will need to install it separately\
or use [Windows PowerShell](Readme/WindowsPowerShell.md) which is already installed.
- .NET Framework version 4.5 is required if using Windows PowerShell (Desktop edition)
instead of PowerShell Core.\
Windows 10 ships with min .NET 4.6 (which includes .NET 4.5)
- You might want to have git to check out for updates,
to easily switch between branches or to contribute code.
- VS Code is preferred and recommended editor to navigate project and edit scripts for your
own needs or contribution.
- If you get VSCode, you'll also need PowerShell extension for code navigation and
PowerShell specific features.
- To navigate and edit code with VSCode, `PSScriptAnalyzer` is recommended otherwise editing
experience may behave really odd due to other project settings.
- Hardware requirements are min. 8GB of memory and SSD drive to work on project, otherwise to just
apply rules to your personal firewall less than that should work just fine!

[Table of Contents](#table-of-contents)

### I don't meet the requirements

At the moment this firewall is tested and designed for most recent Windows Desktop/Servers and that
is known to work, to make use of it on older systems requires additional work.

Testing is done on 64 bit Windows, a small fraction of rules won't work for 32 bit system and
need adjustment, full functionality for 32 bit system is work in progress.\
For now you can load rules on 32 bit system just fine with the exception of few rules probably not
relevant at all for your configuration.

For information on how to make use of this firewall on older Windows systems such as\
Windows 7 or Windows Server 2008 see [Legacy Support](Readme/LegacySupport.md)

[Table of Contents](#table-of-contents)

## First time user

Following are short warnings and notes first time user should be aware of

### Warning

- You might loose internet connectivity for some of your programs or in rare cases even lose internet
connectivity completely, if that happens, you can either temporarily allow outbound network traffic
or run `Scripts\Reset-Firewall.ps1`, to reset GPO firewall to system defaults and remove all rules.
- Inside `Readme` folder there is a `ResetFirewall.md`, a guide on how to do it manually, by hand,
if for some reason you're unable to run the script, or the script doesn't solve your problems.
- Your existing rules will not be deleted unless you have rules in GPO with exact same group names
as rules from this ruleset, however **this does not apply to** `Scripts\Reset-Firewall.ps1` which
will clear GPO rules completely and leave only those in control panel.
- If you want to be 100% sure please export your GPO rules as explained in [Export\Import rules](#exportimport-rules)
- You will be asked which rules to load, to minimize internet connectivity trouble you should
apply at least all generic networking and OS related rules such as "CoreNetworking", "ICMP",
"WindowsSystem", "WindowsServices", "Multicast" including all rules for which you have programs installed
on system, also do not ignore IPv6, Windows indeed needs IPv6 even if you're on IPv4 network.\
It will be easy to delete what you don't need in GPO, rather than later digging through code finding
what you have missed.
- Default configuration will set global firewall behavior which is not configurable in GPO,
such as `stateful ftp` and `pptp` or global `IPSec` settings, if you need specific setup please visit
`Scripts\Complete-Firewall.ps1` and take a look at `Set-NetFirewallSetting`.\
Note that `Scripts\Complete-Firewall.ps1` is automatically called by `Scripts\Deploy-Firewall.ps1`
- Some scripts require network adapter to be connected to network, for example to determine
IPv4 broadcast address. (Otherwise errors may be generated without completing the task)

[Table of Contents](#table-of-contents)

### Note

- Loading rules into an empty GPO should be very fast, however loading into GPO which already
contains rules will be significantly slower (depends on number of existing rules)
- All errors and warnings will be saved to `Logs` directory, you can review these logs later if you
want to fix some problem, most warnings can be safely ignored but errors should be resolved.
- Any rule that results in "Access is denied" while loading should be reloaded by executing specific
script again, see [FAQ.md](Readme/FAQ.md)
for information on why this may happen.
- If the project was manually downloaded, transferred from another computer or media then you should\
unblock all files in project first to avoid YES/NO spam questions for every executing script,
by running `Scripts\Unblock-Project.ps1`\
Master script `Scripts\Deploy-Firewall.ps1` does this in case if you forget, but initial YES/NO spam questions
will still be present in that case.
- If you download code to location that is under "Ransomware protection" (in Windows Defender),
make sure to whitelist either `pwsh.exe` (Core edition) or `powershell.exe` (Desktop edition)
otherwise doing anything may be blocked.\
PowerShell console may need to be restarted for "Controlled folder access" changes to take effect.
- It's important to understand these rules are designed to be used as "Standard" user, not as
user that is Administrator, if you're Administrator on your computer you'll have to either create standard
user account and use that for your everyday life or modify code to allow Administrator online access.
See [FAQ entry](Readme/FAQ.md#does-this-firewall-project-give-me-the-right-protection) for more information
why using Administrator account is not recommended for security reasons.
- Software or Windows updates may rename executables or their locations, also user accounts may be
renamed by Administrator, therefore it's important to reload specific rules from time to time as
needed to update firewall for system changes that may happen at any time.

[Table of Contents](#table-of-contents)

### Quick start

1. If you don't have ssh keys and other setup required to clone via SSH then either clone with HTTPS
or just download released zip file by clicking on "Releases" here on this site, and then for latest
release under "assets" download zip file.\
These steps here assume you have downloaded a zip file from "assets" section under "Releases".
2. Extract downloaded archive somewhere, these steps assume you've extracted the zip (project root directory)
into `C:\` root drive directly.
3. If you would like to use Windows PowerShell instead of PowerShell Core see:\
[How to open Windows PowerShell](Readme/WindowsPowerShell.md)
4. Otherwise the procedure for both PowerShell Core and Windows PowerShell is similar:\
Open up extracted folder, right click into an empty space and there is an option to run
PowerShell Core as Administrator (Assumes you enabled context menu during installment of PowerShell
Core) if not open it manually.
5. If you don't have PowerShell context menu then move to `C:\` root drive by executing following 2
lines (type or copy/paste following commands and hit enter for each),
this is where you extracted your downloaded zip file

    ```powershell
    c:
    cd \
    ```

6. cd into downloaded folder, of course update command below if your extracted folder is called
something else:

    ```powershell
    cd WindowsFirewallRuleset-master
    ```

7. To see current execution policy run following command:\
(**hint:** *you can use `TAB` key to auto complete commands*)

    ```powershell
    Get-ExecutionPolicy
    ```

    Remember what is the output of the above command, note that PowerShell Core defaults to `RemoteSigned`
    while Windows PowerShell defaults to `Restricted` on non server editions.

8. Set execution policy to unrestricted to be able to unblock project files,
(Note that `RemoteSigned` will work only once scripts are unblocked)

    ```powershell
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Unrestricted
    ```

    You may be prompted to accept execution policy change, if so type `Y` and press enter to accept.\
    For more information see [About Execution Policies][about execution policies]

9. At this point you should "unblock" all project files first by executing the script called `Scripts\Unblock-Project.ps1`,
btw. project files were blocked by Windows to prevent users from running untrusted script code
downloaded from internet:

    ```powershell
    .\Scripts\Unblock-Project.ps1
    ```

    If asked, make sure your answer is `R` that is `[R] Run once` as many times as needed to unblock
    project. (approx. up to 8 times)

10. Once project files are unblocked set execution policy to `RemoteSigned`:

    ```powershell
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
    ```

    You may be again prompted to accept execution policy change, type `Y` and press enter to accept.

11. Rules for programs such as your web browser, games etc. depend on installation variables.\
Most paths are auto-searched and variables are updated, otherwise you get warning and description
on how to fix the problem.\
If needed, you can find these installation variables in individual scripts inside `Rules` folder.\
It is recommended to close down all other programs before running master script in the next step

12. Back to PowerShell console and run:

    ```powershell
    .\Scripts\Deploy-Firewall.ps1
    ```

    Hit enter and you will be asked questions such as what kind of rulesets you want.\
    If you need help to decide whether to run some ruleset or not, type `?` and press enter.

13. Follow prompt output, (ex. hit enter to accept default action),
it will take at least 15 minutes of your attention.

14. If you encounter errors, you can either ignore errors or update script that produced the error
then re-run that specific script once again later.

15. When done you might want to adjust some of the rules in Local Group Policy,
not all rules are enabled by default or you might want to toggle default Allow/Block behavior.
Rules which don't exist for specific programs need to be made additionally.

16. Now go ahead and test your internet connection (ex. with a browser or some other program),
If you're unable to connect to internet after applying these rules you have several options:

    - Temporarily open outbound firewall in GPO or [Disable Firewall](Readme/DisableFirewall.md)
    - Troubleshoot problems: [Network troubleshooting detailed guide](Readme/NetworkTroubleshooting.md)
    - You can [Reset Firewall to previous state](Readme/ResetFirewall.md)
    - Take a look into `Readme` folder for more troubleshooting options and documentation

17. As a prerequisite to deploy firewall, some system services have been started and set to automatic
start, inside `Logs` directory you'll find `Services_DATE.log` to help you restore these services to
default if desired.\
For example `Windows Remote Management` service should not run if not needed (The default is "Manual"
startup)

[Table of Contents](#table-of-contents)

## Firewall management

### Manage loaded rules

There are 2 mothods to manage your rules:

1. Using Local Group Policy, this method gives you limited freedom on what you can do with project
rules, such as disabling them, changing some attributes or adding new rules. For more information see:
[Manage GPO Firewall](Readme/ManageGPOFirewall.md)

2. Editing PowerShell scripts, this method gives you full control, you can change or remove existing
rules with no restriction or add new ones.

What ever your plan or setup is, you will surely want to perform additional work such as customizing
rules, or adding new rules for programs not yet covered by this firewall.

Rules are loaded into local group policy, if during firewall setup you accepted creating shortcut to
personalized firewall management console you can run the schortcut, otherwise follow steps below to
open local group policy.

1. Press Windows key and type: `secpol.msc`
2. Right click on `secpol.msc` and click `Run as administrator`
3. If prompted for password, enter administrator password and click "Yes" to continue
4. Expand node: `Windows Defender Firewall with Advanced Security`
5. Expand node: `Windows Defender Firewall with Advanced Security - Local Group Policy Object`
6. Click on either `Inbound`, `Outbound` or `Windows Defender Firewall...` node to view and manage
rules and settings applied with PowerShell.

For more information about GPO see: [Configure security policy settings][configure security policy settings]

[Table of Contents](#table-of-contents)

### Applying individual rulesets

If you want to apply only specific rules there are 2 ways to do this:

1. Execute `Scripts\Deploy-Firewall.ps1` and chose `Yes` only for rulesets you want, otherwise chose `No`
and hit enter to skip current ruleset.

2. With PowerShell navigate (`cd`) to directory containing ruleset script you want and execute
individual script.

You might want to run `Scripts\Complete-Firewall.ps1` afterwards to apply default firewall behavior if
it's not already set, or you can do it manually in GPO but with limited power.
"limited power" means `Scripts\Complete-Firewall.ps1` configures some firewall parameters which can't be
adjusted in firewall GUI.

In all 3 cases the script will delete all rules that match ruleset display group, before loading
rules into GPO.

[Table of Contents](#table-of-contents)

### Deleting rules

At the moment there are 3 options to delete firewall rules:

1. The easiest way is to select all rules you want to delete in GPO, right click and delete.

2. To delete rules according to file there is a function for this purpose, located in:\
`Modules\Ruleset.Firewall\Public\Remove-FirewallRules.ps1`\
however you're advised to perform some tests before using it due to it's
experimental state.

3. To revert to your old firewall state (the one in control panel), you'll need to delete all off
the rules from GPO, and set all properties to `Not configured` after right click on node:\
`Windows Defender Firewall with Advanced Security - Local Group Policy Object`

Deleting all rules or revetting to previous state can also be done with `Scripts\Reset-Firewall.ps1`\
Note that you'll also need to re-import your exported GPO rules if you had them.

[Table of Contents](#table-of-contents)

### Export\Import rules

If you want to export rules from GPO there are 2 methods available:

1. Export in local group policy by clicking on `Export Policy...` menu, after right click on node:\
`Windows Defender Firewall with Advanced Security - Local Group Policy Object`

2. To export using PowerShell run `Scripts\Backup-Firewall.ps1` which is much slower process but
unlike method from point 1 you can customize your export in almost any way you want.

If you want to import rules, importing by using GPO is same as for export, and to import with
PowerShell just run `Scripts\Restore-Firewall.ps1` which will pick up your previous export file.

To customize your export\import please take a look into `Modules\Ruleset.Firewall\Public\External`,
which is where you'll find description on how to use export\import module functions.

**NOTE:** Method 2 is experimental and really slow, you're advised to verify results.

[Table of Contents](#table-of-contents)

## Checking for updates

Just like any other software on your computer, this firewall will go out of date as well,
become obsolete, and may no longer function properly.

This repository consists of 2 branches, `master` (stable) and `develop` (possibly unstable).\
The "develop" branch is where all updates directly go, so it's work in progress,
unlike "master" branch which is updated from develop once in a while and not before all scripts
are thoroughly tested on fresh installed systems, which is what makes master brach stable.

If you want to experiment with development version to check out new stuff, switch to "develop" branch
and try it out, however if it produces errors, you can either fix problems or switch back to "master".

There are at least 4 methods to be up to date with this firewall, each with it's own benefits:

### Manual release download

This method requires you to simply download released scripts which can be found in
[Releases](https://github.com/metablaster/WindowsFirewallRuleset/releases), this is always from "master"
branch

### Manual beta download

This method is good if you want to download from "develop" branch, to do so, use the `branch` button
here on this site to switch to either master or develop branch, next use `Code` button and either clone
or download zip.

### Using GitHub Desktop app

This method is similar to the one that follows, but instead you'll use a graphical interface which
you can get from here: [GitHub Desktop][github desktop]

To use it you will need [github account][github join] and a [fork][github fork] of this repository
in your GitHub account.

To configure GitHub Desktop see [GitHub Desktop Documentation][github desktop docs]

### Using git command

This method is similar to GitHub Desktop above but good if you need to do it in console,
In addition to 2 mentioned requirements for GitHub Desktop you will also need [git][download git]
and optionally (but recommended) [SSH keys][github ssh]

Follow steps below to check for updates once you installed git and cloned your own fork:

- Right click on Start button in Windows
- Click `Windows PowerShell` to open PowerShell
- First navigate to folder where your instance of Windows Firewall Ruleset instance is, for example:
- Type: `dir` to list directories, ```cd SomeDirectoryName``` to move to some directory or
```cd ..``` to go one directory back
- Type: ```cd WindowsFirewallRuleset``` to move into WindowsFirewallRuleset folder

Following 2 sets of commands are typed only once for initial setup:

1. If you cloned your fork with `SSH` then run following command:

    ```git remote add upstream git@github.com:metablaster/WindowsFirewallRuleset.git```

2. Otherwise if you cloned your fork with `HTTPS` run:

    ```git remote add upstream https://github.com/metablaster/WindowsFirewallRuleset.git```

Next 2 sets of commands are typed each time you want to check for updates:

1. To get updates from master branch run:

    - Type: ```git checkout master```
    - Type: ```git fetch upstream```
    - Type: ```git merge upstream/master```

2. Otherwise to get updates from develop branch run:

    - Type: ```git checkout develop```
    - Type: ```git fetch upstream```
    - Type: ```git merge upstream/develop```

For this to work, you need to make sure your working tree is "clean", which means
you need to save and upload your modifications to your fork, for example:

 ```powershell
 git add .
 git commit -m "my changes"
 git push
 ```

 Of course you can switch from one branch to another with git in PowerShell as many times as you
 want and all files will be auto updated without the need to re-download or re-setup anything.

 For more info on how to use git see [git documentation][git docs]

### Which update method is the best

If your goal is to just get updates then `GitHub Desktop` is cool, otherwise if your goal is
firewall customization, using `git` command would be more productive because it offers specific
functionalities that you might need.

You can have both setups in same time and use them as needed in specific situation.\
There isn't any real benefit with manual zip download in comparison with git or GitHub Desktop.

[Table of Contents](#table-of-contents)

## Contributing or suggestions

Do you want to suggest new rules, features, report problems or contribute?

Below are general notes for requesting new rules or features.\
If you would like to contribute by writing code you should read [CONTRIBUTING.md](CONTRIBUTING.md)
instead.

Feel free to suggest or contribute new rules, or improvements for existing rules or scripts.\
Just make sure you abide to notices below:

1. If possible provide some documentation or links (preferably official) for your rules or changes
so that it can be easy to verify these rules don't contain mistakes, ex. for ICMP rules you would
provide a link to [IANA][iana] with relevant reference document.

2. To suggest new rules, report problems, or various rule and code improvements, please open new issue
here on github and provide details as outlined in "New issue".

3. To contribute your own rules, it is also desired that each rule contains good description of it's
purpose, when the user clicks on rule in firewall GUI he/she wants to see what this rule is about
and easily conclude whether to enable/disable rule or allow/block network traffic.

4. It is also important that the rule is very specific and not generic, that means specifying protocol,
IP addresses, ports, system user, interface type and other relevant information.\
For example just saying: allow TCP outbound port 2891 for my new game without telling where, why
or which user account to allow, or no explanation what this is supposed to allow or block is not acceptable.

If you lack some of the information, no problem but please try to do some research first.

[Table of Contents](#table-of-contents)

## Customization

If you would like to customize how scripts run, such as force loading rules and various defaults then
visit `Config\ProjectSettings.ps1` and there you'll find global variables which are used for this.

If you would like to customize project code or add more firewall rules to suit your private or corporate
interests then first step is to set up development environment and learn about project best practices
all of which is explained in [CONTRIBUTING.md](CONTRIBUTING.md)

Depending on your situation and target platform you might also want to read [Legacy Support](Readme/LegacySupport.md)

These 2 documents are bare minimum to get you started customizing this repository.

## More information and help

Inside [Readme](Readme) folder you will find useful information not only about this project but also
general information on how to troubleshoot firewall and network problems, or gather other relevant information.

It might answer some of your questions, for example [Monitoring Firewall](Readme/MonitoringFirewall.md)
explains how to monitor firewall in real time.

[Table of Contents](#table-of-contents)

## The future

Following features are desired and might be available at some point in the future:

1. Remote firewall administration

   - Deploying firewall configuration to remote computers on domain or home networks

2. Comprehensive firewall rulesets for Windows Server editions

3. On demand or scheduled registry scan to validate integrity of active firewall filtering policy

   - Any firewall rule in the registry that is not part of this repository is reported for review
   - Because, malware, hackers and even trusted software might attempt to bypass firewall at any time

4. Full functionality for the following not yet tested editions of Windows 10.0
   - Windows 10 Pro for Workstations
   - Windows 10 IoT Core Blast
   - Windows 10 IoT Enterprise
   - Windows 10 S
   - Windows Server 2019 Essentials

[Table of Contents](#table-of-contents)

[corporate firewall]: https://bitbucket.org/SuperAAAAA/shack/raw/60508e0e23d73aeb8f9a4fdc75b13ea94e56e62b/corporate.jpg "Corporate Firewall"
[download core]: https://github.com/PowerShell/PowerShell "Download PowerShell Core"
[download .net]: https://dotnet.microsoft.com/download/dotnet-framework "Download .NET Framework"
[download git]: https://git-scm.com/downloads "Download git"
[vscode]: https://code.visualstudio.com "Visual Studio Code"
[download powershell extension]: https://marketplace.visualstudio.com/items?itemName=ms-vscode.PowerShell "Visit Marketplace"
[module psscriptanalyzer]: https://github.com/PowerShell/PSScriptAnalyzer "Visit PSScriptAnalyzer repository"
[about execution policies]: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-7 "About Execution Policies"
[configure security policy settings]: https://docs.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/how-to-configure-security-policy-settings "Configure Security Policy Settings"
[github join]: https://github.com/join "Join GitHub"
[github fork]: https://guides.github.com/activities/forking "Create a fork on GitHub"
[github ssh]: https://docs.github.com/en/free-pro-team@latest/github/authenticating-to-github/connecting-to-github-with-ssh "Connecting to GitHub with SSH"
[git docs]: https://git-scm.com/doc "Git Documentation"
[iana]: https://www.iana.org "Internet Assigned Numbers Authority (IANA)"
[github desktop]: https://desktop.github.com "Download GitHub Desktop"
[github desktop docs]: https://docs.github.com/en/free-pro-team@latest/desktop "Visit GitHub Desktop docs"
