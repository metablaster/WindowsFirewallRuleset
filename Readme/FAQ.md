
# Frequently Asked Questions

Here are the most common problems running powershell scripts in this project and how to resolve them.\
Also general questions and answers regarding firewall.

## Table of contents

- [Frequently Asked Questions](#frequently-asked-questions)
  - [Table of contents](#table-of-contents)
  - [I applied the rule(s) but it doesn't work, program "some_program.exe" doesn't connect to internet](#i-applied-the-rules-but-it-doesnt-work-program-some_programexe-doesnt-connect-to-internet)
  - [I got an error "Network path not found" or "unable to contact computer"](#i-got-an-error-network-path-not-found-or-unable-to-contact-computer)
  - [Does this firewall project give me the right protection](#does-this-firewall-project-give-me-the-right-protection)
  - [Windows Firewall does not write logs](#windows-firewall-does-not-write-logs)
  - [Can I trust scripts from this project](#can-i-trust-scripts-from-this-project)
  - [Why do I get "access denied" errors](#why-do-i-get-access-denied-errors)

## I applied the rule(s) but it doesn't work, program "some_program.exe" doesn't connect to internet

First step is to open PowerShell as Administrator and run `gpupdate.exe`, if not working then:

1. Close down the program which is unable to connect to network completely
2. In GPO select each rule that applies to this program, right click and disable,
   wait 2 seconds then enable again.
3. Open program in question and try again, in most cases this should work.
4. If not try rebooting system, Windows firewall sometimes just doesn't instantly respect rules.
5. If still no luck, open rule properties in GPO and under advanced tab allow all interface types,
all users or both, however allowing all interfaces or users should be only a temporary measure.

INFO: In addition to interfaces shown in GPO there are some hidden network interfaces,
until I figure out how to make rules based on those allow them all if this resolves the problem.\
To troubleshoot hidden adapters see [ProblematicTraffic.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Readme/ProblematicTraffic.md)

## I got an error "Network path not found" or "unable to contact computer"

Please make sure you have at a minimum following network services set to automatic and
make sure they are running:

1. Workstation (LanmanWorkstation)
2. Server (LanmanServer)
3. TCP/IP NetBIOS Helper service (lmhosts)

If this doesn't work verify the command you are using, for example following command tries to get
firewall rules from GPO and will produce this problem:

```powershell
Get-NetFirewallRule -PolicyStore [system.environment]::MachineName
```

To fix the problem modify this sample command to this and it should work just fine:

```powershell
Get-NetFirewallRule -PolicyStore $([system.environment]::MachineName)
```

Otherwise if you're trying to administer firewall on remote machines, make sure at a minimum following:

1. "Windows Remote Administration" service is running.
2. "PowerShell remoting" is configured and enabled on remote machine

If this doesn't work take a look here:

- [Computer Name Won't Resolve on Network](https://www.infopackets.com/news/10369/how-fix-computer-name-wont-resolve-network-april-update)

## Does this firewall project give me the right protection

Good firewall setup is essential for computer security, and, if not misused then the answer is yes
but only for the firewall part of protection.

For maximum security you need much more than just good firewall, here is a minimum list:

1. Using non Administrative Windows account for almost all use.\
Administrative account should be used for administration only.

2. Installing and running only digitally signed software, and only those publishers you trust.\
Installing cracks, warez and similar is the most common way to let hackers in.

3. Visiting only trusted web sites, preferably HTTPS, and checking links before clicking them.\
To visit odd sites and freely click around please do it in virtual machine (isolated browsing is OK too)

4. Use password manager capable of auto typing passwords and with the support of virtual keyboard.\
Don't use hardware keyboard to type passwords.

5. Don't let your email program or web interface to auto load mail content.\
Also important not to open attachments you don't recognize or didn't ask for.

6. Never disable antivirus or firewall except to troubleshoot issues.\
Btw. Troubleshooting doesn't include installing software or visiting some web site.

7. VPN is not recommended except for business or to bypass your IP ban.\
Even if VPN provider is considered "trusted".

8. Protect your web browser maximum possible, and avoid using addons except one to block ads.

If you don't follow these rules, no firewall, anti virus or security expert is going to help much.\
Usually the purpose of firewall or anti virus is to protect yourself from your own mistakes.

Remember, the easiest way for hacker to get in is when **you** make a mistake!

If you recognize your mistakes from these rules on daily basis, your system can't be trusted,\
only hard drive reformat and clean system reinstall can regain trust.

## Windows Firewall does not write logs

This could happen if you change default log file location in Windows Firewall settings

To resolve the issue ensure following:

1. Verify current logging setting is enabled and is pointing to expected log file location.

    To verify this open firewall properties in GPO and select current network profile tab,
    - Under logging section click on "Customize" button
    - Under "Name" verify location to log file is correct
    - Under "Log dropped packet" make sure it's set to "Yes"

2. Verify that both the target folder and all the logs inside that folder have write permission\
for Windows Firewall service which is `"NT SERVICE\mpssvc"`

3. For changes to take effect save your modifications and reboot system

Keep in mind that setting additional permissions afterwards will be reset by Windows Firewall service
on every system boot for security reasons.\
If this doesn't resolve the problem remove all log files inside target directory, just make sure the
firewall service has write permissions for target directory and reboot system.

## Can I trust scripts from this project

- You might be wondering, what happens to my system if I run scripts from this project?
- Can these scripts do any kind of harm to my computer or privacy?
- What system and environment modifications are done by this project?
- Can I trust these scripts don't do anything bad?
- Is there anything I should be aware of?

There is a lot of scripts and you might not have the time to investigate them all.\
So here is an overview to help you see what they do hopefully answering all of your concerns.

1. Group policy firewall and most of it's settings are modifed and/or overridden completely.

    - If you make modifications to GPO firewall, re-running scripts again may override your modifications.

2. Some global firewall settings are modified as explained here [Set-NetFirewallSetting](https://docs.microsoft.com/en-us/powershell/module/netsecurity/set-netfirewallsetting?view=win10-ps)

    - For details on which settings are modified see `Scripts\SetupProfile.ps1`

3. PowerShell module path is updated for current session only

    - Running any script will add modules from this repository to module path for current PS session
    only.
    - Once you close down (or open new) PowerShell, module path modifications are lost.

4. All other system settings are left alone **by default** unless you demand or accept them as follows:

    - Adjust console buffer size (valid until you close down PowerShell)
    - Modify network profile for currently connected network adapter (ex. public or private)
    - Update PowerShell module help files (only if you enable development mode)
    - Install recommended or required PowerShell modules (only if you enable development mode)
    - Install recommended VSCode extensions (if you accpet VSCode recommendation)
    - Modify file system permissions (firewall logs inside this repository only by default)
    - Modify settings for specific software (Process monitor and mTail only)

    All of these modifications in point 4 are done in following situations:

    - VScode might ask you to install recommended extensions
    - The script might ask you to confirm whether you want this or that, and you're free to deny.
    - You have enabled "development mode" project setting
    - You run some script on demand that is not run by default (ex. `Scripts\GrantLogs`)
    - You manually load software configuration from `Config` folder

5. Here is a list of scripts that may do things you don't want

    - `Scripts\GrantLogs.ps1`
    - `Scripts\ResetFirewall.ps1`
    - `Modules\...\Initialize-Module.ps1`
    - `Modules\...\Initialize-Provider.ps1`
    - `Modules\...\Uninstall-DuplicateModule.ps1`
    - `Modules\...\Find-UpdatableModule.ps1`

    By default none of these scripts run on their own, except as explained in point 4.\
    Note that last 4 scripts listed above exist also in `Test` folder.

6. Following is a list of external executables that are run by some scripts

    - [gpupdate.exe](https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/gpupdate)
    (Apply GPO to avoid system restart)
    - [reg.exe](https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/reg)
    (To load offline registry hive)
    - [code.cmd](https://code.visualstudio.com) (To learn VSCode version)
    - [git.exe](https://git-scm.com) (To learn git version)
    - [icacls.exe](https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/icacls)
    (To set permissions required to remove duplicate modules)
    - [takeown.exe](https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/takeown)
    (To take ownership required to set permissions)
    - [makecab.exe](https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/makecab)
    (To make online help content)

7. There is nothing dangerous here

   - Some scripts such as `initialize-module.ps1` will contact online PowerShell repository
   to download modules, however this happens only if you enable "development mode"
   - "development mode" may be enabled by default on "develop" branch but never on "master" branch
   - The scripts will gather all sorts of system information but only as needed to configure firewall,
   none of this information is ever sent anywhere, once you close down PowerShell it's all cleared.
   - If you publish your modification online (ex. to your fork) make sure your modification don't include
   any personal information such as user names, email or system info.
   - Bugs might exist which could break things, while I do my best to avoid bugs you might want to remind
   yourself that this is after all [free software](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/LICENSE)
   - As you can see, there is nothing dangerous here, as long as you don't do modifications that do
unexpected things you'll be just fine!

## Why do I get "access denied" errors

You may see this error while loading firewall rules.

In almost all cases this happens when `gpedit.msc` or `secpol.msc` is opened, especially if you
do something with them (ex. refreshing group policy, viewing or modifying settings/rules)

To minimize the chance of this error from appearing close down all management consoles and all
software that is not essential to apply rules with scripts.

Simple rule of thumb before applying rules is the same as when you install drivers:

- reboot system
- close down all programs
- please try agin
