
# Frequently Asked Questions

Here are the most common problems running PowerShell scripts from this repository and how to resolve
them.\
In addition, general questions and answers regarding this firewall.

## Table of contents

- [Frequently Asked Questions](#frequently-asked-questions)
  - [Table of contents](#table-of-contents)
  - [Firewall rule doesn't work, program "some_program.exe" fails to connect to internet](#firewall-rule-doesnt-work-program-some_programexe-fails-to-connect-to-internet)
  - [I get an error "Network path not found", "Unable to contact computer" or "The client cannot connect"](#i-get-an-error-network-path-not-found-unable-to-contact-computer-or-the-client-cannot-connect)
  - [Does this firewall project give me the right (or better) protection](#does-this-firewall-project-give-me-the-right-or-better-protection)
  - [Windows Firewall does not write logs](#windows-firewall-does-not-write-logs)
  - [Can I trust scripts from this repository](#can-i-trust-scripts-from-this-repository)
  - [Why do I get "Access is denied" errors](#why-do-i-get-access-is-denied-errors)
  - [I'm missing network profile settings in Settings App](#im-missing-network-profile-settings-in-settings-app)

## Firewall rule doesn't work, program "some_program.exe" fails to connect to internet

First step is to open PowerShell as Administrator and run `gpupdate.exe`, if not working then:

1. Close down the program which is unable to connect to network completely
2. In GPO select each rule that applies to this program, right click and disable,
   wait 2 seconds then enable again.
3. Open program in question and try again, in most cases this should work.
4. If not try rebooting system, Windows firewall sometimes just doesn't instantly respect rules.
5. If still no luck, open rule properties in GPO and under advanced tab allow all interface types,
all users or both, however allowing all interfaces or users should be only a temporary measure.

**NOTE**: In addition to interfaces shown in GPO there are some hidden network interfaces,
until I figure out how to make rules based on those allow them all if this resolves the problem.\
To troubleshoot hidden adapters see [Problematic Traffic](ProblematicTraffic.md)

## I get an error "Network path not found", "Unable to contact computer" or "The client cannot connect"

First verify following network adapter items are enabled (checked) and if not restart adapter for
any changes to take effect:

1. Client for Microsoft Networks
2. File and Printer Sharing for Microsoft Networks
3. Internet Protocol version 4 (TCP/IPv4)
4. Internet Protocol version 6 (TCP/IPv6)
5. Link-Layer Topology Discovery Responder
6. Link-Layer Topology Discovery I/O Driver

For more information about these items see [Adapter Items](/Readme/LAN%20Setup/AdapterItems.md)

Next ensure at a minimum following network services are `Running` and optionally set to `Automatic` startup

1. LanmanWorkstation: `Workstation`
2. LanmanServer: `Server`
3. lmhosts: `TCP/IP NetBIOS Helper service`
4. WinRM: `Windows Remote Management (WS-Management)`

If this doesn't work verify the command that is causing this problem, for example following command
tries to get firewall rules from GPO and will produce this problem:

```powershell
Get-NetFirewallRule -PolicyStore [system.environment]::MachineName
```

In this example to fix the problem modify bad command to the following and it should work:

```powershell
Get-NetFirewallRule -PolicyStore ([system.environment]::MachineName)
```

Otherwise if you're trying to deploy or manage firewall remotely, make sure at a minimum
following is configured on **remote** machine:

1. WinRM - `Windows Remote Management (WS-Management)` service is `Running` and optionally set to
`Automatic` startup.
2. "PowerShell remoting" is configured and enabled, for more information about PowerShell remoting see:
    - [Enable-PSRemoting][psremoting]
    - [Running Remote Commands][remote commands]

If none of this works even after reboot of all involved computers, following link might help:

- [Computer Name Won't Resolve on Network][name resolution issue]

## Does this firewall project give me the right (or better) protection

Good firewall setup is essential for computer security, and, if not misused then the answer is yes
but only for the firewall part of protection.

For maximum security you'll need way more than just good firewall, here is a minimum list:

1. Using non Administrative Windows account for almost all use.\
Administrative account should be used for administration only, preferably offline.

2. Installing and running only digitally signed software, and only those publishers you trust.\
Installing cracks, warez and similar is the most common way to let hackers in.

3. Visit only known trusted web sites, preferably HTTPS, and check links before clicking them.\
To visit odd sites and freely click around please do it in virtual machine,\
(isolated browser session is OK too, as long as you don't misconfigure it)

4. Use password manager capable of auto typing passwords and with the support of virtual keyboard.\
Don't use hardware keyboard to type passwords.
Your passwords should meet length and complexity requirements.\
Never use same password to log in to multiple places, use unique password for each login.

5. Don't let your email program or web interface auto load email content.\
Also important not to open attachments you don't recognize or didn't ask for.

6. Never disable antivirus or firewall except to troubleshoot issues.\
Btw. Troubleshooting doesn't include installing software or visiting some web site.

7. VPN is not recommended except for business or to bypass your IP or geolocation ban.\
Even if VPN provider is considered "trusted".

8. Protect your web browser maximum possible by restrictively adjusting settings, and
avoid using addons except one to block ads, which is known to be trusted by online community.

9. When it comes to privacy, briefly, there 2 very different defense categories:

   - Prevent identity theft, this is worse than loosing data, being hacked or just being spied on.\
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
Usually the purpose of a firewall, anti virus or a paid expert is to protect you from your own mistakes.\

Remember, the most common ways for hackers "getting in" and stealing data is when **YOU** make a mistake!
(not because of their skills)

If you recognize your mistakes from this list on regular basis, your system or network simply cannot
be trusted, only hard drive reformat, network reset and clean reinstall of operating systems can regain
trust to original value.

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
- What system and environment modifications are done to setup firewall?
- Is there anything I should be aware of?

There is a lot of scripts and you might not have the time to investigate them all.\
So here is an overview to help you see what they do hopefully answering all of your concerns.

1. Group policy firewall and all of it's settings are modifed and/or overridden completely.

    - If you make modifications to GPO firewall, re-running scripts again may override your modifications.

2. Some global firewall settings are modified as explained here [Set-NetFirewallSetting][netfirewallsetting]

    - For details on which settings are modified see `Scripts\Complete-Firewall.ps1`

3. PowerShell module path is updated for current session only

    - Running any script will add modules from this repository to module path for current PS session
    only.
    - Once you close down (or open new) PowerShell session, module path modifications are lost.

4. Required system services are started and set to automatic startup

    - Inside `Logs` you'll find `Services-DATE.LOG` to help you restore defaults

5. All other system or session settings are left alone **by default** unless you demand or accept
them as follows:

    - Adjust console buffer size (valid until you close down PowerShell)
    - Modify network profile for currently connected network adapter (ex. public or private)
    - Update PowerShell module help files (only if you enable development mode)
    - Install or update dependent PowerShell modules (only if you enable development mode)
    - Install recommended VSCode extensions (if you accpet VSCode recommendation)
    - Modify file system permissions (ex. After setting firewall to log into this repository)
    - Modify settings for specific software (Process monitor, mTail and Windows Performance Analyzer
    only)

    All of these modifications in point 4 are done in following situations:

    - VScode might ask you to install recommended extensions
    - Some script might ask you to confirm whether you want to do this or that, and you're free to
    deny by default.
    - You have enabled "development mode" project setting
    - You run some script on demand that is not run by default (ex. `Set-Permission.ps1`)
    - You manually load software configuration from `Config` folder
    - You run experimental or dangerous tests from `Test` folder (default action for these tests is `No`)

6. Here is a list of scripts that may behave unexpectedly because these are either experimental,
   not intended for end user or hard to get right, therefore you should review them first to learn
   their purpose

    - `Scripts\Grant-Logs.ps1`
    - `Scripts\Reset-Firewall.ps1`
    - `Test\Ruleset.Utility\Set-Permission.ps1`
    - `...\Initialize-Module.ps1`
    - `...\Initialize-Provider.ps1`
    - `...\Uninstall-DuplicateModule.ps1`
    - `...\Ruleset.Firewall\Remove-FirewallRule.ps1`
    - `...\Ruleset.Firewall\Export-FirewallRule.ps1`
    - `...\Ruleset.Firewall\Import-FirewallRule.ps1`
    - `...\Ruleset.Utility\Set-NetworkProfile.ps1`

    By default none of these scripts run on their own, except as explained in point 4.\
    Those scripts listed above which begin with `...\` exist in at least `Modules` and `Test` subdirectories.

7. Following is a list of external executables that are run by some scripts

    - [gpupdate.exe][gpupdate] (Apply GPO to avoid system restart)
    - [reg.exe][reg] (To load offline registry hive)
    - [code.cmd][vscode] (To learn VSCode version)
    - [git.exe][git] (To learn git version)
    - [makecab.exe][makecab] (To make online help content)

8. There is nothing harmful here

   - Some scripts such as `initialize-module.ps1` will contact online PowerShell repository
   to download or update modules, however this happens only if you manually enable setting
   - Some scripts are potentially dangerous due to their experimental state such as
   `Uninstall-DuplicateModule.ps1` which may fail and leave you with broken modules that you would
   have to to fix with your own intervention.
   - "development mode" may be enabled by default on `develop` branch but never on `master` branch,
   which means defaults described so far may no longer be defaults
   - The scripts will gather all sorts of system information but only as required to configure firewall,
   none of this information is ever sent anywhere and once you close down PowerShell it's all cleared.
   - If you publish your code modifications online (ex. to your fork) make sure your modifications
   don't include any personal information such as user names, email or system details.
   - Bugs may exist which could break things, while I do my best to avoid bugs you might want to
   report your findings to be fixed.

## Why do I get "Access is denied" errors

You might see this error while loading firewall rules.

In almost all cases this happens when you use one of the management consoles such as `gpedit.msc` or
`secpol.msc`, especially if you do something with them (ex. refreshing group policy, viewing or
modifying settings/rules)

To minimize the chance of this error from appearing close down all management consoles and all
software that is not essential to deploy firewall and try again.

## I'm missing network profile settings in Settings App

In `Settings -> Network & Internet -> Status -> Properties` there should be options to set private or
public profile for your adapter, but what if these options are gone and how to get them back?

These profile settings go missing when some privileged process has modified network profile such
as 3rd party firewalls.

Here in this case this will happen when you run `Set-NetworkProfile.ps1` which runs only on demand,
however you won't notice this problem until system is rebooted.

There are many options to troubleshoot this problem, most of which are just a workaround but don't
actually bring these options back, so here are my favorites that should fix it instead:

1. First open up Control Panel firewall and see if there is a message that says:\
`For your security, some setting are controlled by Group Policy`

   - If you do see this message, next step is to open up GPO firewall and quickly export your firewall
   rules and settings because once the problem is resolved importing them back will be easy and quick.
   - Next step is to reset GPO firewall to defaults by using `Scripts\Reset-Firewall.ps1`,
   but don't do anything to firewall in Control Panel.
   - When done reboot system and see if this message was gone and also whether profile options are back.
   - If the message is still there, you can try to recall any security policies you did in GPO, it
   doesn't have to be related to firewall, ex. anti virus, network options or anything similar can
   be the cause for this message.

2. If you can't get rid of a message and profile options are not back even after reboot, next step
is to verify following location in GPO:\
`Computer Configuration\Windows Settings\Security Settings\Network List Manager Policies`

    - Here make sure everything is set to `Not Configured`, and if you change something reboot
    system to verify.

3. If profile options are still not back there is only one option left which is resetting
network settings as follows:

   - `Settings -> Network & Internet -> Network Reset`
   - Make sure not to reboot until required time has passed, usually 5 minutes, let it reboot on
   it's own and profile options should re-appear.

- Finally you may want to import your exported firewall policy, this will not bring problem back.
- Next time make sure not to run `Set-NetworkProfile` if there is no valid reason.

[name resolution issue]: https://www.infopackets.com/news/10369/how-fix-computer-name-wont-resolve-network-april-update
[netfirewallsetting]: https://docs.microsoft.com/en-us/powershell/module/netsecurity/set-netfirewallsetting?view=win10-ps "Visit Microsoft docs"
[gpupdate]: https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/gpupdate "Visit Microsoft docs"
[reg]: https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/reg "Visit Microsoft docs"
[vscode]: https://code.visualstudio.com "Visual Studio Code"
[git]: https://git-scm.com "Visit git homepage"
[makecab]: https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/makecab "Visit Microsoft docs"
[psremoting]: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/enable-psremoting?view=powershell-7.1 "Visit Microsoft docs"
[remote commands]: https://docs.microsoft.com/en-us/powershell/scripting/learn/remoting/running-remote-commands?view=powershell-7.1 "Visit Microsoft docs"
