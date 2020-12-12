
# Frequently Asked Questions

Here are the most common problems running powershell scripts in this project and how to resolve them.\
Also general questions and answers regarding firewall.

## Table of contents

- [Frequently Asked Questions](#frequently-asked-questions)
  - [Table of contents](#table-of-contents)
  - [Firewall rule doesn't work, program "some_program.exe" doesn't connect to internet](#firewall-rule-doesnt-work-program-some_programexe-doesnt-connect-to-internet)
  - [I got an error "Network path not found" or "Unable to contact computer"](#i-got-an-error-network-path-not-found-or-unable-to-contact-computer)
  - [Does this firewall project give me the right protection](#does-this-firewall-project-give-me-the-right-protection)
  - [Windows Firewall does not write logs](#windows-firewall-does-not-write-logs)
  - [Can I trust scripts from this repository](#can-i-trust-scripts-from-this-repository)
  - [Why do I get "access denied" errors](#why-do-i-get-access-denied-errors)

## Firewall rule doesn't work, program "some_program.exe" doesn't connect to internet

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
To troubleshoot hidden adapters see [Problematic Traffic](ProblematicTraffic.md)

## I got an error "Network path not found" or "Unable to contact computer"

Please make sure you have at a minimum following network services set to automatic and
make sure they are running:

1. Workstation (LanmanWorkstation)
2. Server (LanmanServer)
3. TCP/IP NetBIOS Helper service (lmhosts)

Verify following adapter items are enabled and restart adapter for any changes to take effect:

1. Client for Microsoft Networks
2. File and Printer Sharing for Microsoft Networks
3. Internet Protocol version 4 (TCP/IPv4)
4. Internet Protocol version 6 (TCP/IPv6)
5. Link-Layer Topology Discovery Responder
6. Link-Layer Topology Discovery I/O Driver

For more information about these items see [Adapter Items](/Readme/LAN%20Setup/AdapterItems.md)

If this doesn't work verify the command you are using, for example following command tries to get
firewall rules from GPO and will produce this problem:

```powershell
Get-NetFirewallRule -PolicyStore [system.environment]::MachineName
```

In this example to fix the problem modify this command to following and it should work just fine:

```powershell
Get-NetFirewallRule -PolicyStore ([system.environment]::MachineName)
```

Otherwise if you're trying to administer firewall on remote machines, make sure at a minimum following:

1. WinRM "Windows Remote Management (WS-Management)" service is running and optionally set to Automatic.
2. "PowerShell remoting" is configured and enabled on target machine

If none of this works even after reboot, following link might help:

- [Computer Name Won't Resolve on Network][name resolution issue]

## Does this firewall project give me the right protection

Good firewall setup is essential for computer security, and, if not misused then the answer is yes
but only for the firewall part of protection.

For maximum security you'll need much more than just good firewall, here is a minimum list:

1. Using non Administrative Windows account for almost all use.\
Administrative account should be used for administration only, preferably offline.

2. Installing and running only digitally signed software, and only those publishers you trust.\
Installing cracks, warez and similar is the most common way to let hackers in.

3. Visit only known trusted web sites, preferably HTTPS, and check links before clicking them.\
To visit odd sites and freely click around please do it in virtual machine,\
(isolated browser session is OK too, as long as you don't misconfigure it)

4. Use password manager capable of auto typing passwords and with the support of virtual keyboard.\
Don't use hardware keyboard to type passwords.
Your passwords should meet length and complexity requirements.
Never use same password to log in to multiple places, use unique password for each login.

5. Don't let your email program or web interface auto load mail content.\
Also important not to open attachments you don't recognize or didn't ask for.

6. Never disable antivirus or firewall except to troubleshoot issues.\
Btw. Troubleshooting doesn't include installing software or visiting some web site.

7. VPN is not recommended except for business or to bypass your IP or geolocation ban.\
Even if VPN provider is considered "trusted".

8. Protect your web browser maximum possible by restrictively adjusting settings, and
avoid using addons except one to block ads, which is known to be trusted by online community.

9. When it comes to privacy, briefly, there 2 very different defense categories:

   - Prevent identity theft, this is worse than loosing data, being hacked or just being spied on
   Go ahead and study worse identity theft cases and you'll understand

   - Hide your activity, is what people usually refer to when talking about "privacy"
   Understanding the difference is important, because how do you defend if the threat is unknown?

10. Keep your operating system and anti virus patched maximum possible, that means checking for
system and virus updates on daily basis.

11. High value data and larger financial transactions should be performed on separate computer whose
only purpose is to do this an nothing else, and to keep valueable data protected away from network.

12. Encrypt your valueable hard drives or individual files, for computers such as those in point 10,
this is requirement not suggestion.

13. Always keep a backup of everything on at least 1 drive that is offline and away from online machine.
If you have to bring it online, take down the rest of network.

If you don't follow this list, no firewall, anti virus or security expert is going to help much.\
Usually the purpose of a firewall, anti virus or a paid expert is to protect you from your own mistakes.

Remember, the most common ways for hackers "getting in" and stealing data is when **YOU** make a mistake!
(not because of their skills)

If you recognize your mistakes from this list on regular basis, your system or network simply cannot
be trusted, only hard drive reformat, network reset and clean reinstall of operating systems can regain
trust to original value, in 99% of cases (hopefully) you won't need to throw your expensive hardware
into trash can.

## Windows Firewall does not write logs

This could happen if you change default log file location in Windows Firewall settings

To resolve this issue ensure following:

1. Verify current logging setting is enabled and is pointing to expected log file location.

    To verify this, open firewall properties in GPO and select current network profile tab,
    - Under logging section click on `Customize...` button
    - Under `Name` verify location to log file is correct
    - Under `Log dropped packet` make sure it's set to `Yes`

2. Verify that both the target folder and all the logs inside that logs directory grants write
permission for Windows Firewall service which is `"NT SERVICE\mpssvc"`

3. For changes to take effect save your modifications and reboot system

Keep in mind that setting additional permissions afterwards will be reset by Windows firewall service
on every system boot or firewall setting change for security reasons.\
If this doesn't resolve the problem remove all log files inside target directory, to be able to do this,
you'll have to instruct firewall to write to different location to set your logs free, then reboot system.

Btw. firewall service can't be stopped or manipulated in any way except trough UI followed by reboot.

## Can I trust scripts from this repository

- You might be wondering, what happens to my system if I run scripts from this repository?
- Can these scripts do any kind of harm to my computer or privacy?
- What system and environment modifications are done by this project?
- Can I trust these scripts don't do anything bad such as break my system?
- Is there anything I should be aware of?

There is a lot of scripts and you might not have the time to investigate them all.\
So here is an overview to help you see what they do hopefully answering all of your concerns.

1. Group policy firewall and most of it's settings are modifed and/or overridden completely.

    - If you make modifications to GPO firewall, re-running scripts again may override your modifications.

2. Some global firewall settings are modified as explained here [Set-NetFirewallSetting][netfirewallsetting]

    - For details on which settings are modified see `Scripts\SetupProfile.ps1`

3. PowerShell module path is updated for current session only

    - Running any script will add modules from this repository to module path for current PS session
    only.
    - Once you close down (or open new) PowerShell session, module path modifications are lost.

4. All other system settings are left alone **by default** unless you demand or accept them as follows:

    - Adjust console buffer size (valid until you close down PowerShell)
    - Modify network profile for currently connected network adapter (ex. public or private)
    - Update PowerShell module help files (only if you enable development mode)
    - Install required or recommended PowerShell modules (only if you enable development mode)
    - Install recommended VSCode extensions (if you accpet VSCode recommendation)
    - Modify file system permissions (firewall logs inside this repository only by default)
    - Modify settings for specific software (Process monitor, mTail and Windows Performance Analyzer only)

    All of these modifications in point 4 are done in following situations:

    - VScode might ask you to install recommended extensions
    - The script might ask you to confirm whether you want this or that, and you're free to deny by default.
    - You have enabled "development mode" project setting
    - You run some script on demand that is not run by default (ex. `Scripts\GrantLogs`)
    - You manually load software configuration from `Config` folder
    - You run experimental or dangerous tests from `Test` folder (default action for these tests is `No`)

5. Here is a list of scripts that may do things you don't want

    - `Scripts\GrantLogs.ps1`
    - `Scripts\ResetFirewall.ps1`
    - `Modules\...\Initialize-Module.ps1`
    - `Modules\...\Initialize-Provider.ps1`
    - `Modules\...\Uninstall-DuplicateModule.ps1`
    - `Modules\...\Find-UpdatableModule.ps1`
    - `Test\Ruleset.Utility\Set-Permission.ps1`
    - `Test\Ruleset.Firewall\Remove-FirewallRules.ps1`
    - `Test\Ruleset.Firewall\Export-FirewallRules.ps1`
    - `Test\Ruleset.Firewall\Import-FirewallRules.ps1`

    By default none of these scripts run on their own, except as explained in point 4.\
    Note that last 4 scripts listed above exist also in `Test` folder.

6. Following is a list of external executables that are run by some scripts

    - [gpupdate.exe][gpupdate] (Apply GPO to avoid system restart)
    - [reg.exe][reg] (To load offline registry hive)
    - [code.cmd][vscode] (To learn VSCode version)
    - [git.exe][git] (To learn git version)
    - [makecab.exe][makecab] (To make online help content)

7. There is nothing harmful here

   - Some scripts such as `initialize-module.ps1` will contact online PowerShell repository
   to download modules, however this happens only if you enable "development mode"
   - Some scripts are potentially dangerous due to their experimental state such as
   `Uninstall-DuplicateModule.ps1` which may fail and leave you with broken modules that you would
   have to to fix with your own intervention.
   - "development mode" may be enabled by default on `develop` branch but never on `master` branch
   - The scripts will gather all sorts of system information but only as required to configure firewall,
   none of this information is ever sent anywhere, once you close down PowerShell it's all cleared.
   - If you publish your code modifications online (ex. to your fork) make sure your modifications
   don't include any personal information such as user names, email or system details.
   - Bugs might exist which could break things, while I do my best to avoid bugs you might want to remind
   yourself that this is after all [free software][license]

## Why do I get "access denied" errors

You might see this error while loading firewall rules.

In almost all cases this happens when `gpedit.msc` or `secpol.msc` is opened, especially if you
do something with them (ex. refreshing group policy, viewing or modifying settings/rules)

To minimize the chance of this error from appearing close down all management consoles and all
software that is not essential to apply rules with scripts.

[name resolution issue]: https://www.infopackets.com/news/10369/how-fix-computer-name-wont-resolve-network-april-update
[netfirewallsetting]: https://docs.microsoft.com/en-us/powershell/module/netsecurity/set-netfirewallsetting?view=win10-ps "Visit Microsoft docs"
[gpupdate]: https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/gpupdate "Visit Microsoft docs"
[reg]: https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/reg "Visit Microsoft docs"
[vscode]: https://code.visualstudio.com "Visual Studio Code"
[git]: https://git-scm.com
[makecab]: https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/makecab "Visit Microsoft docs"
[license]: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/LICENSE
