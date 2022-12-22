
# Frequently Asked Questions

Here are the most common problems running PowerShell scripts from this repository and how to resolve
them.\
In addition, general questions and answers regarding this firewall.

## Table of Contents

- [Frequently Asked Questions](#frequently-asked-questions)
  - [Table of Contents](#table-of-contents)
  - [Firewall rule doesn't work, program "some-program.exe" fails to connect to internet](#firewall-rule-doesnt-work-program-some-programexe-fails-to-connect-to-internet)
  - [I get an error "Network path not found", "Unable to contact computer" or "The client cannot connect"](#i-get-an-error-network-path-not-found-unable-to-contact-computer-or-the-client-cannot-connect)
  - [Does this firewall project give me the right protection](#does-this-firewall-project-give-me-the-right-protection)
  - [Windows Firewall does not write logs](#windows-firewall-does-not-write-logs)
  - [Can I trust scripts from this repository](#can-i-trust-scripts-from-this-repository)
  - [Why do I get "Access is denied" errors](#why-do-i-get-access-is-denied-errors)
  - [I'm missing network profile settings in Settings App](#im-missing-network-profile-settings-in-settings-app)
  - [The maximum number of concurrent operations for this user has been exceeded](#the-maximum-number-of-concurrent-operations-for-this-user-has-been-exceeded)
  - [Why do I need to specify my Microsoft account credentials](#why-do-i-need-to-specify-my-microsoft-account-credentials)
  - [Network icon in taskbar says "No Network"](#network-icon-in-taskbar-says-no-network)
  - [PowerShell Core throws a black console window](#powershell-core-throws-a-black-console-window)
  - [Duplicate log entries](#duplicate-log-entries)
  - [For your security, some setting are controlled by Group Policy](#for-your-security-some-setting-are-controlled-by-group-policy)

## Firewall rule doesn't work, program "some-program.exe" fails to connect to internet

First step is to open PowerShell as Administrator and run `gpupdate.exe`, if not working then:

1. Close down the program which is unable to connect to network completely, including system tray.
2. In GPO firewall `SHIFT` select each rule that applies to this program, right click and disable,
   wait two seconds then enable again.
3. Open program in question and try again, in most cases this should work.
4. If not try rebooting system, Windows firewall sometimes just doesn't instantly respect rules.
5. If still no luck, open rule properties in GPO and under `Advanced` tab allow all interface types
and allow all users under `Local Principals` tab, however allowing all interfaces or users should be
only a temporary measure for troubleshooting.

**NOTE**: In addition to interfaces shown in GPO there are some hidden network interfaces,
until I figure out how to make rules based on those allow them all to rule out problem with
interfaces.\
To troubleshoot hidden adapters see [Problematic Traffic](ProblematicTraffic.md)

If steps above do no solve the problem, reload rules which do not work, sometimes system or
program changes make existing GPO rules ineffective.

Other than this, if problem persists, you'll have to debug the problem, to get started see [MonitoringFirewall.md](MonitoringFirewall.md)

[Table of Contents](#table-of-contents)

## I get an error "Network path not found", "Unable to contact computer" or "The client cannot connect"

First verify the following network adapter items are enabled (checked) and if not restart adapter
for any changes to take effect:

1. Client for Microsoft Networks
2. File and Printer Sharing for Microsoft Networks
3. Internet Protocol version 4 (TCP/IPv4)
4. Internet Protocol version 6 (TCP/IPv6)
5. Link-Layer Topology Discovery Responder
6. Link-Layer Topology Discovery I/O Driver

For more information about these items and how to manage them see [AdapterItems.md](LAN%20Setup/AdapterItems.md)

Next ensure at the minimum the following network services are `Running` and optionally set to
`Automatic` startup

1. LanmanWorkstation: `Workstation`
2. LanmanServer: `Server`
3. lmhosts: `TCP/IP NetBIOS Helper service`
4. WinRM: `Windows Remote Management (WS-Management)`
5. RemoteRegistry `Remote Registry`
6. FDResPub `Function Discovery Resource Publication`
7. fdPHost `Function Discovery Provider host`

Next ensure that on computer which you're trying to access the following is enabled for private
network profile:

1. Turn on network discovery
2. Turn on file and printer sharing

This can be enabled in the following location:\
`Start->System->Network & Internet->Network and Sharing Center->Change advanced sharing settings`

If this doesn't work verify the command that is causing this problem, for example the following
command tries to get firewall rules from GPO and will produce this problem:

```powershell
Get-NetFirewallRule -PolicyStore [System.Environment]::MachineName
```

In this example to fix the problem modify command above to the following and it should work:

```powershell
Get-NetFirewallRule -PolicyStore ([System.Environment]::MachineName)
```

If you're trying to deploy or manage firewall remotely see this document [Remote.md](Remote.md)

If none of this works even after reboot of all involved computers, the following link might help:

- [Computer Name Won't Resolve on Network][name resolution issue]

[Table of Contents](#table-of-contents)

## Does this firewall project give me the right protection

Good firewall setup is essential for computer security, and if not misused then the answer is yes
but only for the firewall part of protection.

Keep in mind that this project is still alpha software, not yet ready for production use, see
[What's alpha software][alpha]

For maximum security you'll need much more than just good firewall, for start you can read trough [SecurityAndPrivacy.md](SecurityAndPrivacy.md)

[Table of Contents](#table-of-contents)

## Windows Firewall does not write logs

This could happen if you change default log file location in Windows Firewall settings

To resolve this issue ensure the following:

1. Verify current logging setting is enabled and is pointing to expected log file location.

    To verify this, open firewall properties in GPO and select current network profile tab:

    - Under logging section click on `Customize...` button
    - Under `Name` verify location to log file is correct
    - Under `Log dropped packet` make sure it's set to `Yes`

2. Ensure that log files were generated in the specified location.

    - If log files were not generated go to step 3 below to grant permission to specified directory
    and then get back here to step 2
    - If you applied write permission to specified directory and log files aren't generated temporarily
    toggle setting to log successful connections and apply it, this should force generating logs.

3. Verify that both the target directory and all the logs inside that directory grant write\
permission for Windows Firewall service which is `NT SERVICE\mpssvc`

4. For changes to take effect save your modifications and restart firewall or reboot system.

Keep in mind that setting additional permissions afterwards will be reset by Windows firewall
service on every system boot or firewall setting change for security reasons.\
If this doesn't resolve the problem remove all log files inside target directory, to be able to do
this, you'll have to instruct firewall to write to different location to set your logs free,
then reboot system.

Also keep in mind that firewall service can't be stopped or manipulated in any way except trough UI
followed by reboot.

[Table of Contents](#table-of-contents)

## Can I trust scripts from this repository

- You might be wondering, what happens to my system if I run scripts from this repository?
- Can these scripts do any kind of harm to my computer or privacy?
- What system and environment modifications are done to setup firewall?
- Is there anything else I should be aware of?

There is a lot of scripts and you might not have the time to investigate them all.\
So here is an overview to help you see what they do hopefully answering all of your concerns.

1. Group policy firewall and all of it's settings are modifed and/or overridden completely.

    - If you make modifications to GPO firewall, rerunning scripts again may override your modifications.

2. Some global firewall settings are modified as explained here [Set-NetFirewallSetting][netfirewallsetting]

    - For details on which settings are modified see `Scripts\Complete-Firewall.ps1`

3. PowerShell module path is updated for current session only

    - Running any script will add modules from this repository to module path for current PS session
    only.
    - Once you close down (or open new) PowerShell session, module path modifications are undone.

4. Required system services are started and set to automatic startup

    - Inside `Logs` you'll find `Services-<DATE>.log` to help you restore defaults

5. WS-Management service (Windows Remote Management) configuration is modified

    - WinRM configuration is completely modified
    - PowerShell remoting may be enabled either for loopback or remote sessions which does the following:
      - Starts the WinRM service.
      - Sets the startup type on the WinRM service to Automatic.
      - Creates a listener to accept requests on loopback IP address.
      - Temporarily enables firewall exception for WS-Management communications.
      - Creates the simple and long name session endpoint configurations if needed.
      - Enables all session configurations.
      - Optionally changes the security descriptor of all session configurations to allow remote access.

    - Default PowerShell session configurations are recreated and optionally disabled
    - Custom session configurations are created which is used for local and remote firewall deployment
    - Your own PowerShell session configurations if you made them will be removed

6. The following default firewall rules are recreated or removed in control panel firewall

    - Rules for Network Discovery, File and Printer Sharing, WinRM and WinRM compatibility rules

7. All other system or session settings are left alone **by default** unless you demand or accept
them as follows:

    - Adjust console buffer size (valid until you close down PowerShell)
    - Update PowerShell module help files (only if you enable development mode)
    - Install or update dependent PowerShell modules (only if you enable development mode or if you
    set `ModulesCheck` variable to `$true` manually)
    - Install recommended VSCode extensions (if you accpet VSCode recommendation)
    - Modify file system permissions (ex. after setting firewall to log into this repository)
    - Modify settings for specific software (Process monitor, mTail and Windows Performance Analyzer
    only)

    All of modifications above are done in the following situations:

    - VScode might ask you to install recommended extensions
    - Some script might ask you to confirm whether you want to do this or that, and you're free to
    deny by default.
    - You have enabled "development mode" project setting
    - You run some script on demand that is not run by default (ex. `Set-Permission.ps1`)
    - You manually load software configuration from `Config` directory
    - You run experimental or dangerous tests from `Test` directory (default action for these tests
    is `No`)

8. Here is a list of scripts that may behave unexpectedly or do things which are potentially not
   desired because these are either experimental, not intended for end user or hard to get right,
   therefore you might want to review them first to learn their purpose:

    - `Scripts\Grant-Logs.ps1`
    - `Scripts\Set-ATP.ps1`
    - `Scripts\Set-Privacy.ps1`
    - `...\Ruleset.Utility\Set-Privilege.ps1`
    - `...\Ruleset.Utility\Set-Permission.ps1`
    - `...\Ruleset.Initialize\Initialize-Module.ps1`
    - `...\Ruleset.Initialize\Initialize-Provider.ps1`
    - `...\Ruleset.Initialize\Uninstall-DuplicateModule.ps1`
    - `...\Ruleset.Remote\*.ps1`

    By default none of these scripts (except scripts in `Ruleset.Remote`) run on their own,
    except as explained in point 5.\
    Those scripts listed above which begin with `...\` exist in `Modules` and `Test` subdirectories.

9. The following is a list of external executables that are run by some scripts

    - [gpupdate.exe][gpupdate] (Apply GPO to avoid system restart)
    - [reg.exe][reg] (To load offline registry hive)
    - [code.cmd][vscode] (To learn VSCode version)
    - [git.exe][git] (To learn git version or to set up git)
    - [makecab.exe][makecab] (To make online help content)
    - [netstat.exe][netstat] (Used to get network statistics)
    - [sigcheck64.exe][sigcheck] (Used to scan digital signature of executable files)

10. There is nothing harmful to privacy or system security

    - Some scripts such as `initialize-module.ps1` will contact online PowerShell repository
    to download or update modules, however this happens only if you manually enable setting
    - Some scripts are potentially dangerous due to their experimental state such as
    `Uninstall-DuplicateModule.ps1` which may fail and leave you with broken modules which you would
    have to to fix with your own intervention.
    - "development mode" may be enabled by default on `develop` branch but never on `master` branch,
    which means defaults described so far may no longer be defaults
    - Scripts will gather all sorts of system information but only as required to configure firewall,
    none of this information is ever sent anywhere and once you close down PowerShell it's all cleared.
    - If you publish your code modifications online (ex. to your fork) make sure your modifications
    don't include any personal information such as user names, email or system details.
    - Bugs may exist which could break things, while I do my best to avoid bugs you might want to
    report your findings to be fixed.
    - If you believe there is security or privacy issue please see [Security.md](../SECURITY.md)

[Table of Contents](#table-of-contents)

## Why do I get "Access is denied" errors

You might see this error while loading firewall rules.

In almost all cases this happens when you use one of the management consoles such as `gpedit.msc` or
`secpol.msc`, especially if you do something with them (ex. refreshing group policy, viewing or
modifying settings/rules)

To minimize the chance of this error from appearing close down all management consoles and all
software that is not essential to deploy firewall and try again.

The "Access is denied" error may also be reported by WinRM or CIM, see [Remote.md](Remote.md) to
resolve these kinds of "Access is denied".

[Table of Contents](#table-of-contents)

## I'm missing network profile settings in Settings App

In `Settings -> Network & Internet -> Status -> Properties` there should be options to set private
or public profile for your adapter, but what if these options are gone and how to get them back?

These profile settings go missing when sharing your physical NIC with virtual switch with virtual
machine.\
If you have configured external switch in your Hyper-V there is nothing you can do to except to
stop sharing your hardware NIC with virtual switch.

There are many options to troubleshoot this problem, most of which are just a workaround but don't
actually bring these options back, so here are my favorites that should fix it instead:

1. First open up Control Panel firewall and see if there is a message that says:\
   `For your security, some setting are controlled by Group Policy`

    - If you see this message, next step is to open up GPO firewall and export your firewall
    rules and settings because once the problem is resolved importing them back will be easy and quick.
    - When done refer to [For your security, some setting are controlled by Group Policy](#for-your-security-some-setting-are-controlled-by-group-policy)
    section below and then come back here.

2. If you can't get rid of the message and profile options are not back even after reboot, next step
   is to verify the following location in GPO:\
   `Computer Configuration\Windows Settings\Security Settings\Network List Manager Policies`

    Here make sure everything is set to `Not Configured`, and if you change something reboot
    system to verify.

3. If profile options are still not back there is only one option left which is resetting
   network settings as follows:

   - `Settings -> Network & Internet -> Network Reset`
   - Make sure not to reboot until required time has passed, usually 5 minutes, let it reboot on
   it's own and profile options should re-appear.

## The maximum number of concurrent operations for this user has been exceeded

This error may happen when using PS Core to deploy firewall because in PS Core up to 3 sessions may
be created during initial configuration while using single PS Core console.\
This means if second console is opened it will exceed the default value of 5 sessions.

There are few solutions:

1. Close down all PS Core consoles (including ghost windows), wait some time and try again with
single PS Core console.

2. You can increase the limit in `Modules\Ruleset.Remote\Scripts\WinRMSettings.ps1`, here search for
`MaxShellsPerUser` and increase the value to 10, 20 or more, the default value is 5.

3. If nothing works the easiest workaround is either reboot system or use Windows PowerShell for
the time being.

[Table of Contents](#table-of-contents)

## Why do I need to specify my Microsoft account credentials

If you're using Microsoft account to log in to your computer you will be asked for
credentials, which needs to be your Microsoft email and password used to log into computer
regardless if you're using Windows hello or not, specifying PIN ie. will not work and other Windows
hello authentication methods are not supported.

If invalid credentials are supplied you'll get an error saying `Access is denied`.\
If this happens you'll need to restart PowerShell console and try again.

The reason why this is necessary is because this firewall uses PowerShell remoting and WinRM service
to deploy rules, by default PS Remoting will use your NTLM username\password, however this method
does not work if Microsoft account is used because NTLM username is not the same as Microsoft account
username, which results in an error saying that such user does not exist.

Thus the only way for proper authentication is to ask user for valid Microsoft account credentials,
which needs to be of an Administrative account on computer.\
The credentials are securely stored in an object of type [PSCredential][pscredential] and once you
close down PowerShell the credential object is destroyed.

Windows hello is neither supported nor necessary by PowerShell remoting or WinRM.

## Network icon in taskbar says "No Network"

You might stumble upon the following icon in your taskbar:

![Alternate text](Screenshots/Disconnected.png)

Internet might or might not work but the icon says "No Network".

If your internet connections works this problem happens either due to something with DHCP or DNS:

- If you're using DHCP to resolve this problem run:

```powershell
ipconfig /release
Clear-DnsClientCache
ipconfig /renew
```

And then disable and re-enable your network adapter.

- If you use custom DNS software such as dnscrypt-proxy which modifies DNS entry of a NIC you'll
need to add alternate DNS server that is not using DNS encryption to the NIC.

- If you're sharing your NIC with virtual switch in VM (ex. Hyper-V), you might need to release
physical NIC in Hyper-V and re-share it again.

- If you use VPN it might have to be re-applied or reconfigured as well.

[Table of Contents](#table-of-contents)

## PowerShell Core throws a black console window

When using PowerShell Core a blank black windows is created, this is known issue which has not
yet been resolved, you can track the issue here: [New-PSSession throws a black window][ps core issue]

[Table of Contents](#table-of-contents)

## Duplicate log entries

Duplicate log entries appear if a script is dotsourced, it should be called rather than dotsourced.\
If scripts are run with PS debugger or with `Run -> Run Without Debugging` duplicate log entries will
appear because script will get dotsourced.\
See also this issue [Configuration option to debug or run a script without dot sourcing it][debugger suggestion]

[Table of Contents](#table-of-contents)

## For your security, some setting are controlled by Group Policy

This message is present in control panel firewall when at least one option in GPO firewall is
modified or when at least one rule exists in GPO firewall.\
To get rid of this message GPO firewall needs to be cleared to system defaults.

- First step is to reset GPO firewall to defaults by using `Scripts\Reset-Firewall.ps1`,
  but don't do anything to firewall in Control Panel.
- When done reboot system and see if this message has gone and also whether profile options are back.
- If the message is still there, you can try to recall any security policies you did in GPO, it
  doesn't have to be related to firewall, ex. anti virus, network options or anything similar can
  be the cause for this message.
- If nothing helps, in GPO firewall right click on node:
  `Windows Defender Firewall with Advanced Security - Local Group Policy Object` and select
  `Clear Policy`

[Table of Contents](#table-of-contents)

[name resolution issue]: https://www.infopackets.com/news/10369/how-fix-computer-name-wont-resolve-network-april-update "Visit external site"
[netfirewallsetting]: https://docs.microsoft.com/en-us/powershell/module/netsecurity/set-netfirewallsetting "Visit Microsoft docs"
[gpupdate]: https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/gpupdate "Visit Microsoft docs"
[reg]: https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/reg "Visit Microsoft docs"
[vscode]: https://code.visualstudio.com "Visual Studio Code"
[git]: https://git-scm.com "Visit git homepage"
[makecab]: https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/makecab "Visit Microsoft docs"
[netstat]: https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/netstat "Visit Microsoft docs"
[sigcheck]: https://docs.microsoft.com/en-us/sysinternals/downloads/sigcheck "Visit Microsoft docs"
[alpha]: https://en.wikipedia.org/wiki/Software_release_life_cycle#Alpha "What is alpha software? - Wikipedia"
[pscredential]: https://learn.microsoft.com/en-us/dotnet/api/system.management.automation.pscredential "What is PSCredential?"
[ps core issue]: https://github.com/PowerShell/PowerShell/issues/16763 "Visit GitHub issue"
[debugger suggestion]: https://github.com/PowerShell/vscode-powershell/issues/4327 "Visit GitHub issue"
