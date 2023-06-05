
# Windows Firewall Ruleset

![Alt Text][corporate firewall]

## Table of Contents

- [Windows Firewall Ruleset](#windows-firewall-ruleset)
  - [Table of Contents](#table-of-contents)
  - [About Windows Firewall Ruleset](#about-windows-firewall-ruleset)
    - [Firewall rules](#firewall-rules)
    - [Firewall framework](#firewall-framework)
  - [The vision of this firewall](#the-vision-of-this-firewall)
  - [License](#license)
  - [Requirements](#requirements)
    - [Requirements details](#requirements-details)
    - [I don't meet the requirements](#i-dont-meet-the-requirements)
  - [First time user](#first-time-user)
    - [Warning](#warning)
    - [Note](#note)
    - [Quick start](#quick-start)
  - [Firewall management](#firewall-management)
    - [Automated and interactive firewall deployment](#automated-and-interactive-firewall-deployment)
    - [Manage GPO rules](#manage-gpo-rules)
    - [Deploying individual rulesets](#deploying-individual-rulesets)
    - [Deleting rules](#deleting-rules)
    - [Export/Import rules](#exportimport-rules)
  - [Remote firewall deployment](#remote-firewall-deployment)
  - [Support, updates and documentation](#support-updates-and-documentation)
  - [The future](#the-future)

## About Windows Firewall Ruleset

[![Alpha release][badge status]][alpha]

A fully automated solution for Windows firewall with PowerShell

`Windows Firewall Ruleset` configures Windows firewall automatically and applies restrictive
firewall rules specific for target system and software installed on the system.

Status of this project is still alpha, click on "status" badge above to learn more.\
This project consists of two major parts, firewall rules and firewall framework as follows:

### Firewall rules

Windows firewall rules sorted into individual PowerShell scripts according to:

- Rule group
- Traffic direction (ex. inbound, outbound or IPSec)
- Software type and publisher
- IP version (IPv4 / IPv6)

Such as for example:

- ICMP traffic
- Browser rules
- Built in OS software
- Store apps
- Windows services
- Multiplayer Games
- Microsoft programs
- 3rd party programs
- broadcast traffic
- multicast traffic

### Firewall framework

- Firewall framework consists of a number of PowerShell modules, scripts and documentation used to
gather environment information relevant to build and deploy firewall specialized for target system
such as:

  - Computers on network
  - Installed programs
  - IP subnet math
  - Remote or local system users
  - Network configuration
  - GPO configuration
  - Firewall management
  - Quick analysis of packet trace and audit logs
  - Various troubleshooting, firewall, system and network utility functions

- Thus this repository is a good starting point to easily extend your firewall to include more rules
and functionalities as desired.
- Currently there are some 800+ firewall rules, 10+ modules with 100+ functions, several scripts
and a good portion of useful documentation.
- You can interactively choose which rules you want, and deploy only those or you could automate the
process and deploy all the necessary rules and settings to your firewall.

[Table of Contents](#table-of-contents)

## The vision of this firewall

[![Managed in VSCode][badge vscode]][vscode]
[![PowerShell][badge language]][powershell]

1. Detailed firewall configuration is time consuming process, takes a lot of troubleshooting,
changes require testing and security auditing and it only gets worse if you need to deploy firewall
to hundreds or thousands of remote computers, for example not all computers might have same software
or restriction requirements.

2. Unlike firewall rules in control panel, these rules are loaded into GPO firewall
(Local Group Policy), meaning system settings changes or random programs which install rules as
part of their installation process will have no effect on firewall unless you explicitly make an
exception.

3. Rules based on programs and services will have their specified executable file checked for
digital signature and will be scanned on VirusTotal if digital signature is missing,
for security reasons rule is not created or loaded into firewall if this verification fails.
(can be forced)

4. Default outbound is "block" unless there is a rule to allow network traffic, in most firewalls
this is not possible unless you maintain rules for every possible program or service,
thanks to this collection of rules, setting default outbound to block requires very little or no
additional work.

5. Unlike in usual scenario, you will know which rules no longer have an effect or are redundant
due to ex. uninstalled program, a missing system service which no longer exists, renamed
executable after Windows update and similar reasons.

6. Unlike predefined Windows firewall rules, these rules are more restrictive such as,
tied to explicit user accounts, rules apply to specific ports, network interfaces, specific
executables, services etc. all of which is learned automatically from target system.

7. Updating, filtering or searching rules and attributes such as ports, addresses and similar is
much easier since these rules are in scripts, you can use editor tools such as [regex](/docs/Regex.md),
[multicursor][multicursor] or `CTRL + F` to perform bulk operations on your rules, doing this in
any firewall UI is not possible due to user interface limitations.

8. A good portion of code is dedicated to provide automated solution to build and define firewall
specialized for target system and users, minimizing the need to do something manually thus saving
you much valuable administration time.

[Table of Contents](#table-of-contents)

## License

[![MIT license][badge license]](/LICENSE "View license")

This project `Windows Firewall Ruleset` is licensed under the `MIT` license.

Some scripts, files or modules are not `MIT` licensed or may have their own Copyright holders
for this reason license and Copyright notices are maintained **"per file"**.

## Requirements

[![Windows][badge system]][windows]

The following table lists operating systems on which `Windows Firewall Ruleset` has been tested

| OS                  | Edition       | Version     | Architecture |
| ------------------- | ------------- | ----------- | ------------ |
| Windows 10          | Pro           | 1809 - 22H2 | x64          |
| Windows 10          | Pro Education | 20H2        | x64          |
| Windows 10          | Enterprise    | 1809 - 20H2 | x64          |
| Windows 10          | Education     | 20H2 - 22H2 | x64          |
| Windows 11          | Pro Education | 21H2        | x64          |
| Windows 11          | Pro           | 22H2        | x64          |
| Windows 11          | Enterprise    | 22H2        | x64          |
| Windows Server 2019 | Essentials    | 1809        | x64          |
| Windows Server 2019 | Standard      | 1809        | x64          |
| Windows Server 2019 | Datacenter    | 1809        | x64          |
| Windows Server 2022 | Standard      | 21H2        | x64          |
| Windows Server 2022 | Datacenter    | 21H2        | x64          |

***

1. Windows PowerShell 5.1 or PowerShell Core 7.3.x [Download PowerShell Core][download core]
2. .NET Framework 4.5 (Windows PowerShell only) [Download Net Framework][download .net]
3. `sigcheck64.exe` (Highly recommended) [Download sigcheck][sigcheck]
4. Git (Optional) [Download Git][download git]
5. Visual Studio Code (Recommended) [Download VSCode][vscode]
6. PowerShell Support for VSCode (Recommended) [Download extension][download powershell extension]
7. PSScriptAnalyzer (Recommended) [Download PSScriptAnalyzer][module psscriptanalyzer]

[Table of Contents](#table-of-contents)

### Requirements details

- All Windows 10.0 systems (Major 10, Minor 0) and above except `Home` editions are supported,
but only those editions listed in the table above have been tested.\
The "Version" column lists tested releases, however only latest OS builds continue to be tested.\
A list of other untested but supported systems and features is in [The future](#the-future)

- `PowerShell Core` is not built into Windows, you will need to install it separately or use
[Windows PowerShell](/docs/WindowsPowerShell.md) which is part of operating system.

- `.NET Framework` min. version 4.5 is required if using Windows PowerShell (Desktop edition)
instead of PowerShell Core.\
Windows 10 ships with min .NET 4.6 (which includes .NET 4.5), and Windows 11 ships with min .NET 4.8

- `sigcheck64.exe` (or 32 bit `sigcheck.exe`) is a digital signature verification tool which you can
download from Microsoft site and should be placed either into `C:\tools` directory or to `%PATH%`
environment variable.\
`Windows Firewall Ruleset` will use it to perform hash based online malware analysis on VirusTotal
for every executable that is not digitally signed before a firewall rule is made for that executable.\
This is only a recommendation, if there is no `sigcheck64.exe` in `PATH` you're offered to download
it and if you decline no malware analysis is made.\
By using this functionality you're agree to [VirusTotal Terms of Service][virustotal terms],
[VirusTotal Privacy Policy][virustotal privacy] and [Sysinternals Software License Terms][sysinternals terms]

- You might want to have git to check out for updates,
to easily switch between branches or to contribute code.

- VS Code is preferred and recommended editor to navigate code and or to edit scripts for your
own needs or contribution.

- If you get VSCode, you'll also need PowerShell extension for code navigation and PowerShell
language features.

- To navigate and edit code with VSCode `PSScriptAnalyzer` is highly recommended, otherwise editing
experience may behave odd due to various repository settings.

- There are no hardware requirements, but if you plan to write and debug code recommendation is min.
8GB of memory and SSD drive to comfortably work on project, otherwise to just deploy rules to your
personal firewall less than that will work just fine.

[Table of Contents](#table-of-contents)

### I don't meet the requirements

At the moment this firewall is tested and designed for most recent Windows Desktop/Servers and that
is known to work, to make use of it on older systems requires additional work.

Testing is done on 64 bit Windows, a small fraction of rules won't work for 32 bit system and
need adjustment, full functionality for 32 bit system is work in progress.\
For now you can load rules on 32 bit system just fine with the exception of few rules probably not
relevant at all for your configuration.

For information on how to make use of this firewall on older Windows systems such as Windows 7 or
Windows Server 2008 see [Legacy Support](/docs/LegacySupport.md)

[Table of Contents](#table-of-contents)

## First time user

The following are brief warnings and notices first time user should be aware of before deploying firewall

### Warning

- You might loose internet connectivity for some of your programs or in rare cases even lose
internet connectivity completely, if that happens, you can either temporarily allow outbound network
in GPO or run\
`.\Scripts\Reset-Firewall.ps1 -Remoting -Service`, to reset GPO firewall to system defaults,
remove all rules and restore WinRM and modified services to system defaults.
(afterwards PowerShell restart is required)

- Inside `docs` directory there is a `ResetFirewall.md`, a guide on how to do it manually, by hand,
if for some reason you're unable to run the script, or the script doesn't solve your problems.

- Your existing rules will not be deleted unless you have rules in GPO with exact same group names
as rules from this ruleset, however **this does not apply to** `Scripts\Reset-Firewall.ps1` which
will clear GPO rules completely and leave only those in control panel.

- If you want to be 100% sure please export your GPO rules as explained in
[Export\Import rules](#exportimport-rules)

- You will be asked which rules to load (if you select interactive deployment, see later),
to minimize internet connectivity trouble you should deploy at least all generic networking and OS
related rules called "CoreNetworking", "ICMP", "WindowsSystem", "WindowsServices", "Multicast"
including all rules for which you have programs installed on system, also do not ignore IPv6,
Windows needs IPv6 even if you're on IPv4 network.\
It will be easy to delete what you don't need in GPO, rather than later digging through code finding
what you have missed.

- Default configuration will set global firewall behavior which is not configurable in GPO,
such as `Stateful FTP` and `PPTP` or global `IPSec` settings, if you need specific setup please
visit `Scripts\Complete-Firewall.ps1` and take a look at `Set-NetFirewallSetting`.\
Note that `Scripts\Complete-Firewall.ps1` is automatically called by `Scripts\Deploy-Firewall.ps1`

- Some scripts require you (network adapter) to be connected to network, for example to determine
IPv4 broadcast address. (Otherwise errors may be generated)

[Table of Contents](#table-of-contents)

### Note

- Loading rules into an empty GPO should be very fast, however loading into GPO which already
contains rules will be significantly slower (depends on number of existing rules in GPO)

- All errors and warnings will be saved to `Logs` directory, you can review these logs later if you
whish to fix some problem, most warnings and even some errors can be safely ignored, in certain cases
you might want to resolve errors if possible.

- Any rule that results in "Access is denied" while loading should be reloaded by executing specific
script again, see [FAQ](/docs/FAQ.md) for more information on why this may happen.

- If the repository was manually downloaded, transferred from another computer or media then you should\
unblock all files in repository first to avoid YES/NO spam questions for every executing script,
by running `Scripts\Unblock-Project.ps1`\
Master script `Scripts\Deploy-Firewall.ps1` does this in case if you forget, but initial YES/NO
questions will still be present in that case.

- If you download code to location that is under "Ransomware protection" (in Windows Defender),
make sure to whitelist either `pwsh.exe` (Core edition) or `powershell.exe` (Desktop edition)
otherwise doing anything may be blocked.\
PowerShell console might need to be restarted for "Controlled folder access" changes to take effect.

- By default rules are made for `Users` group while for `Administrators` group only if necessary,
recommendation is to have standard user account which you use for every day computing for security
reasons.\
If you're Administrator and are not willing to create standard account on your computer you'll have
to modify `DefaultGroup` variable in `Config\ProjectSettings.ps1` and specify `Administrators`.

  See [SecurityAndPrivacy.md](/docs/SecurityAndPrivacy.md#standard-user-account) for more
  information why using Administrator account is not recommended for security reasons.\
  Your administrative account used to deploy firewall must have a password set.

- Software or Windows updates may rename executables or their locations, also user accounts may be
renamed by Administrator, therefore it's important to reload specific rules from time to time as
needed to update firewall for system changes that may happen at any time.
This behavior is called [Software regression][regression]

- Before deploying firewall it is recommended to update system and user programs on target computer
including Windows store apps, especially if system is fresh installed because updating later may
require to reload some rules.

[Table of Contents](#table-of-contents)

### Quick start

1. If you don't have ssh keys and other setup required to clone via SSH then either clone with HTTPS
or just download released zip file from [Releases][releases], and then for the latest
release under "assets" download zip file.\
These steps here assume you have downloaded a zip file from "assets" section under "Releases".

2. Extract downloaded archive somewhere, these steps assume you've extracted the zip file
(repository root directory) into `C:\` root drive directly.

3. If you would like to use Windows PowerShell, see [How to open Windows PowerShell](WindowsPowerShell.md)
Otherwise the procedure for both PowerShell Core and Windows PowerShell is similar:\
Open up extracted folder, right click into an empty space and there is an option to run
PowerShell Core as Administrator (Assumes you enabled context menu during installment of PowerShell
Core) if not open it manually.

4. If you don't have PowerShell context menu then move to `C:\` root drive by executing the
following two lines (type or copy/paste the commands and hit enter for each),
this is where you extracted your downloaded zip file

    ```powershell
    c:
    cd \
    ```

5. cd into downloaded folder:

    ```powershell
    cd WindowsFirewallRuleset*
    ```

6. To see current execution policy type the following command and hit enter:\
(**hint:** *you can use `TAB` key to auto complete as you type*)

    ```powershell
    Get-ExecutionPolicy
    ```

    Remember the output of the above command, note that PowerShell Core defaults to
    `RemoteSigned` while Windows PowerShell defaults to `Restricted` on non server editions.

7. Set execution policy to unrestricted to be able to unblock project files,
(Note that `RemoteSigned` will work only once scripts are unblocked)

    ```powershell
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Unrestricted
    ```

    You may be prompted to accept execution policy change, if so type `Y` and press enter to accept.\
    For more information see [About Execution Policies][about execution policies]

8. At this point you should "unblock" all repository files first by executing a script called\
`Scripts\Unblock-Project.ps1`, btw. repository files were blocked by Windows to prevent users from
running untrusted script code downloaded from internet:

    ```powershell
    .\Scripts\Unblock-Project.ps1
    ```

    If asked, make sure your answer is `R` that is `[R] Run once` as many times as needed to unblock
    project. (approx. up to 8 times)

9. Once repository files are unblocked change execution policy to `RemoteSigned`:

    ```powershell
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
    ```

    You may be again prompted to accept execution policy change, type `Y` and press enter to accept.

10. Rules for programs such as your web browser, games etc. depend on installation variables.\
Most paths are auto-searched and variables are updated transparently, otherwise you get warning and
description on how to fix the problem.\
If needed, you can find these installation variables in individual scripts inside `Rules` directory.\
It is recommended to close down all `MMC` management consoles such as `gpedit.msc` or `secpol.msc`
before running master script in the next step.

11. Back to PowerShell console and run one of the two `Deploy-Firewall` commands below:

    To deploy firewall automatically  with as few prompts as possible run:

    ```powershell
    .\Scripts\Deploy-Firewall.ps1 -Force
    ```

    Otherwise to be interactively prompted which rules to load run:

    ```powershell
    .\Scripts\Deploy-Firewall.ps1
    ```

    Hit enter and you'll be asked questions such as what kind of rulesets you want.\
    If you need help to decide whether to run some ruleset or not, type `?` when prompted to run
    ruleset and press enter to get more info.\
    If for what ever reason you want to interrupt and abort deployment (ex. to start a new) press
    `CTRL + C` on your keyboard while PowerShell is in focus and restart PowerShell console.

12. Follow prompt output, (ex. hit enter to accept default action),
it will take some 15 minutes of your attention.

    **NOTE:** If Administrator account is using Microsoft account to log in to computer you will be
    asked for credentials, which needs to be Microsoft email and password regardless if you're
    using Windows hello or not, specifying PIN ie. will not work and other Windows hello
    authentication methods are not supported.

    If invalid credentials are supplied you'll get an error saying `Access is denied`.\
    If this happens you'll need to restart PowerShell console and try again.

    For more information why this is necessary see [FAQ](/docs/FAQ.md#why-do-i-need-to-specify-my-microsoft-account-credentials)

13. If you encounter errors, you can either ignore errors or update script that produced the error
then rerun that specific script once again later.

14. When done you might want to adjust some of the rules in Local Group Policy,
not all rules are enabled by default or you might want to toggle default Allow/Block behavior.\
Rules may not cover all programs installed on your system, in which case missing rules need to be
made.

15. Now go ahead and test your internet connection (ex. with a web browser or some other program),
If you're unable to connect to internet after deploying these rules you have several options:

    - Temporarily open outbound firewall in GPO or [Disable Firewall](/docs/DisableFirewall.md)
    - Troubleshoot problems: [Network troubleshooting detailed guide](/docs/NetworkTroubleshooting.md)
    - You can [Reset Firewall to previous state](/docs/ResetFirewall.md)
    - Take a look into `docs` directory for more troubleshooting options and documentation

16. As a prerequisite to deploy firewall, some system services have been started and set to
automatic start, inside `Logs` directory you'll find `Services_<DATE>.log` to help you restore these
services to default if desired.\
For example `Windows Remote Management` service should not run if not needed
(the default is "Manual" startup)

[Table of Contents](#table-of-contents)

## Firewall management

The following section gives some hints to manage firewall with ease

### Automated and interactive firewall deployment

`Deploy-Firewall.ps1` script supports several parameters to let you customize deployment automation
as follows:

- To automatically run all rules without prompt and concise output but only for programs which exist
on system run:

```powershell
.\Scripts\Deploy-Firewall.ps1 -Force -Quiet
```

- To go step by step and be prompted for confirmation on which rulesets to load
and to attempt to resolve issues on the fly run:

```powershell
.\Scripts\Deploy-Firewall.ps1 -Interactive
```

- To be prompted only for ruleset selection run `Deploy-Firewall` without any parameters:

```powershell
.\Scripts\Deploy-Firewall.ps1
```

To learn the meaning of parmaters to be able to combine them on your own see `Deploy-Firewall.ps1`
script comment or run the following command:

```powershell
Get-Help .\Scripts\Deploy-Firewall.ps1 -Detailed
```

### Manage GPO rules

There are two mothods to manage GPO rules:

1. Using Local Group Policy, this method gives you limited freedom on what you can do with rules
from this repository, such as disabling them, changing some attributes or adding new rules.\
For more information see: [Manage GPO Firewall](/docs/ManageGPOFirewall.md)

2. Editing PowerShell scripts, this method gives you full control, you can change or remove existing
rules with no restriction or add new ones.

What ever your plan or setup is, you will surely want to perform additional work such as customizing
rules, or adding new rules for programs not yet covered by this firewall.

Rules are loaded into local group policy, if during firewall setup you accepted creating a shortcut
to personalized firewall management console you can run the schortcut, otherwise follow steps
mentioned in [Manage GPO Firewall](/docs/ManageGPOFirewall.md)

For more information about GPO see:
[Configure security policy settings][configure security policy settings]

[Table of Contents](#table-of-contents)

### Deploying individual rulesets

If you want to deploy only specific rules there are two ways to do this:

1. Execute `Scripts\Deploy-Firewall.ps1` and chose `Yes` only for rulesets you want, otherwise chose
`No` and hit enter to skip current ruleset.

2. In PowerShell console navigate `cd` to directory containing ruleset script you want and execute
individual script.\
For example `cd .\Rules\IPv4\Outbound\Software` followed by `.\Adobe.ps1` to load rules for Adobe.

You might want to run `Scripts\Complete-Firewall.ps1` afterwards to apply default firewall behavior
if it's not already set, or you can do it manually in GPO but with limited power.
"limited power" means `Scripts\Complete-Firewall.ps1` configures some firewall parameters which
can't be adjusted in firewall GUI.

In both cases all rules that match ruleset group, `DisplayGroup`, will be deleted before loading
rules into GPO.

[Table of Contents](#table-of-contents)

### Deleting rules

At the moment there are three options to delete firewall rules:

1. The easiest way is to select all rules you want to delete in GPO, right click and delete.

2. To delete rules according to file there is a function for this purpose, located in:\
`Modules\Ruleset.Firewall\Public\Remove-FirewallRule.ps1`\
however you first need to export firewall to file before using it.

3. To revert to your old firewall state (the one in control panel), you'll need to delete all
rules from GPO, and set all properties to `Not configured` after right click on node:\
`Windows Defender Firewall with Advanced Security - Local Group Policy Object`

Deleting all rules or revetting to previous state can also be done with `Scripts\Reset-Firewall.ps1`\
Note that you'll also need to re-import your exported GPO rules if you had them.

[Table of Contents](#table-of-contents)

### Export/Import rules

If you want to export rules from GPO there are two methods available:

1. Export in local group policy by clicking on `Export Policy...` menu, after right click on node:\
`Windows Defender Firewall with Advanced Security - Local Group Policy Object`

2. To export using PowerShell run `Scripts\Backup-Firewall.ps1`\
If you want to customize your export see `Export-RegistryRule` function located in `Ruleset.Firewall`
module, which let's you customize your export in almost any way you want.

If you want to import rules, importing by using GPO is same as for export, and to import with
PowerShell just run `Scripts\Restore-Firewall.ps1` which will pick up your previous export files.

To customize your export\import please take a look into `Modules\Ruleset.Firewall\Public`,
which is where you'll find description on how to use export\import module functions.

**NOTE:** `Export-FirewallRule` function is really slow, you're advised to run `Export-RegistryRule`
function instead which is as fast as it can be.

[Table of Contents](#table-of-contents)

## Remote firewall deployment

This section and functionality is currently experimental and not fully complete,
at the moment deployment to single remote computer is supported.

![Under construction](/docs/Screenshots/UnderConstruction.gif)

In remote firewall deployment there are at least two computers involved,\
one is called management computer (client) and all others are called managed computers (servers).

Scripts are executed by administrator on management computer, and firewall is then deployed to or
configured on multiple server computers simultaneously.

For implementation details see `Modules\Ruleset.Remote` module

**NOTE:** Remoting functionality is not exclusive to remote firewall deployment, deployment to
localhost by design requires working WinRM and PS remoting configuration as well.

Before remote deployment can be performed, remote computer (server) needs to be configured to accept
connection, example on how to establish SSL connection is as follows:

To allow execution, configure WinRM service and remote registry on server computer by running:

**NOTE:** If using PowerShell core omit `-Protocol HTTPS` from `Enable-WinRMServer` below, this will
enable both HTTP and HTTPS which is a temporary workaround for compatibility module to work in
remote session.

```powershell
# On server computer
Set-ExecutionPolicy -Scope LocalMachine RemoteSigned
Set-Location C:\Path\to\WindowsFirewallRuleset
Import-Module .\Modules\Ruleset.Remote
Enable-WinRMServer -Protocol HTTPS -KeepDefault -Confirm:$false
Enable-RemoteRegistry -Confirm:$false
```

After performing these steps, inside `\Exports` directory you'll find SSL certificate (*.cer) file
which needs to be copied to management computer also into `\Exports` directory.\
By default self signed SSL certificate is created if the server computer does not already have one.

**NOTE:** Configuring server computer manually is performed only once for initial setup,
you don't need to repeat it for subsequent deployments.

Next step is to move on to management computer and run scripts as wanted, for example:

```powershell
# On management computer
cd C:\Path\to\WindowsFirewallRuleset\Scripts
Deploy-Firewall -Domain "RemoteComputerName"
```

Both sets of commands above need to be run in same edition of PowerShell, ex. if server was
configured in PowerShell Core then client computer also needs PowerShell core for deployment.\
If either the server or management computer is a workstation (ex. not Windows server or part of domain)
then it's network profile must be set to private profile.

Remote deployment can be customized in a great detail in the following locations:

- To customize WinRM service see: `Modules\Ruleset.Remote\Scripts\WinRMSettings.ps1`
- To customize WSMan session configuration see: `Modules\Ruleset.Remote\Scripts\*Firewall.pssc`
- To customize self signed SSL certificate see: `Modules\Ruleset.Remote\Public\Register-SslCertificate.ps1`
- To customize PS and CIM session configuration see: `Modules\Ruleset.Remote\Scripts\SessionSettings.ps1`

For additional information and troubleshooting tips see also [Remoting help](/docs/Remote.md)

[Table of Contents](#table-of-contents)

## Support, updates and documentation

For support, issue reports, suggestions or customization of this repository and methods to
periodically update this firewall please refer to [SUPPORT.md](SUPPORT.md)

[Table of Contents](#table-of-contents)

## The future

The following features are desired and might be available at some point in the future:

1. Remote firewall administration

    - Deploying firewall configuration to multiple remote computers on domain or home networks

2. Comprehensive firewall rulesets for Windows Server editions and dedicated gateway systems.

3. On demand or scheduled registry scan to validate integrity of active firewall filtering policy
and firewall settings

    - Any firewall rule or setting in the registry that is not part of this repository is reported
    for review.
    - Because, malware, hackers and even trusted software can attempt to bypass firewall at any time

4. Full functionality for the following not yet tested editions of Windows 10.0
   - Windows 10 & 11 Pro for Workstations
   - Windows 10 & 11 IoT Core Blast
   - Windows 10 & 11 IoT Enterprise
   - Windows 10 & 11 S

5. Functionality for x86 systems

[Table of Contents](#table-of-contents)

[corporate firewall]: https://bitbucket.org/SuperAAAAA/shack/raw/60508e0e23d73aeb8f9a4fdc75b13ea94e56e62b/corporate.jpg "Corporate Firewall"
[download core]: https://github.com/PowerShell/PowerShell "Download PowerShell Core"
[download .net]: https://dotnet.microsoft.com/download/dotnet-framework "Download .NET Framework"
[download git]: https://git-scm.com/downloads "Visit Git downloads page"
[vscode]: https://code.visualstudio.com "Visit Visual Studio Code home page"
[download powershell extension]: https://marketplace.visualstudio.com/items?itemName=ms-vscode.PowerShell "Visit Marketplace"
[module psscriptanalyzer]: https://github.com/PowerShell/PSScriptAnalyzer "Visit PSScriptAnalyzer repository"
[about execution policies]: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies "About Execution Policies"
[configure security policy settings]: https://docs.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/how-to-configure-security-policy-settings "Configure Security Policy Settings"
[releases]: https://github.com/metablaster/WindowsFirewallRuleset/releases "Visit releases page now"
[powershell]: https://docs.microsoft.com/en-us/powershell/scripting/overview "What is PowerShell anyway?"
[windows]: https://learn.microsoft.com/en-us/windows/resources "Visit Windows client documentation for IT Pros"
[alpha]: https://en.wikipedia.org/wiki/Software_release_life_cycle#Alpha "What is alpha software? - Wikipedia"
[badge status]: https://img.shields.io/static/v1?label=Status&message=Alpha&color=red&style=plastic
[badge system]: https://img.shields.io/static/v1?label=OS&message=Windows&color=informational&style=plastic&logo=Windows
[badge language]: https://img.shields.io/static/v1?label=Language&message=PowerShell&color=informational&style=plastic&logo=PowerShell
[badge vscode]: https://img.shields.io/static/v1?label=Managed%20in&message=VSCode&color=informational&style=plastic&logo=Visual-Studio-Code
[regression]: https://en.wikipedia.org/wiki/Software_regression "What is software regresssion?"
[sigcheck]: https://learn.microsoft.com/en-us/sysinternals/downloads/sigcheck "Download sigcheck from Microsoft"
[multicursor]: https://code.visualstudio.com/Docs/editor/codebasics#_multiple-selections-multicursor "Visit VSCode documentation"
[virustotal terms]: https://support.virustotal.com/hc/en-us/articles/115002145529-Terms-of-Service "Visit VirusTotal site"
[virustotal privacy]: https://support.virustotal.com/hc/en-us/articles/115002168385-Privacy-Policy "Visit VirusTotal site"
<!-- unused link or image reference false positive-->
<!-- markdownlint-disable MD053 -->
[badge license]: https://img.shields.io/static/v1?label=License&message=MIT&color=success&style=plastic
<!-- markdownlint-enable MD053 -->
[sysinternals terms]: https://learn.microsoft.com/en-us/sysinternals/license-terms "Visit Microsoft site"
