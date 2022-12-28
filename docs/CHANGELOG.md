
# Changelog

Here is a list of changes for each of the releases.

## Table of Contents

- [Changelog](#changelog)
  - [Table of Contents](#table-of-contents)
  - [v0.15.0 (develop branch)](#v0150-develop-branch)
  - [v0.14.0 (current release)](#v0140-current-release)
  - [v0.13.1](#v0131)
  - [v0.13.0](#v0130)
  - [v0.12.0](#v0120)
  - [v0.11.0](#v0110)
  - [v0.10.0](#v0100)
  - [v0.9.0](#v090)
  - [v0.8.0](#v080)
  - [v0.7.0](#v070)
  - [v0.6.0](#v060)
  - [v0.5.0](#v050)
  - [v0.4.1](#v041)
  - [v0.4.0](#v040)
  - [v0.3.0](#v030)
  - [v0.2](#v02)

## v0.15.0 (develop branch)

To see unreleased changes please do so on `develop` branch [HERE][changelog]\
**NOTE:** Changes for unreleased version may change or be announced upfront

- Rules

  - Updated rules for Visual Studio
  - Made rules for store apps respect `DefaultGroup` global variable
  - Updated rules for network discovery and network sharing so that only those are enabled for which
  network profile is currently active.

- Modules

  - Improved or updated module functions

    - `Initialize-Service` now handles paused services
    - `Test-VirusTotal` now offers to download sigcheck if it doesn't exist on target computer
    - `Get-GroupPrincipal` added `-Unique` switch to get unique principals

  - Implemented remoting for the following functions and scripts

    - `Set-NetworkProfile`
    - `Deploy-Firewall.ps1`
    - `Complete-Firewall.ps1`

  - Fixed a bug with `Initialize-Service` which asked to configure service that was already configured
  - Fixed a bug with `Initialize-Service` which configured services which should not be configured\
  **NOTE:** If you used Windows Firewall Ruleset version up to and including v0.14.0 run the
  following code to restore these system managed services to system defaults:

    ```powershell
    sc.exe config AFD start= system
    sc.exe config http start= demand
    sc.exe config Srv2 start= demand
    sc.exe config MRxSmb20 start= demand
    sc.exe config Bowser start= demand
    ```

  - Fixed a bug with `Test-Service` and `Find-UnsignedFile` which reported false positives for
    digital signature test.
  - Fixed an issue with `Test-FileSystemPath` which ignored and didn't report certain path errors
  - Fixed an issue with logging of rule scripts, which didn't log script generated errors and warnings

- Scripts

  - Updated `Grant-Logs` script to better detect log file location change
  - `Find-UnsignedFile` now offers to download sigcheck if it doesn't exist on computer
  - You can now deploy, reset, backup and restore firewall on single remote computer (experimental)

- Unit test

  - Fixed pester test `ConvertTo-Network.Tests.ps1`

## v0.14.0 (current release)

- Rules

  - Updated rules for mail apps from Windows store so that ports for `POP3`, `IMAP` and `SMTP` etc.
  are specified
  - Display name of rules for store apps are now title case, ex. `Microsoft.Xboxapp` instead of `microsoft.xboxapp`
  - Updated rules for Simple DNS crypt, there was issue on systems with virtual adapters
  - Added rules for Azure Cloud Shell present in Windows Terminal
  - PowerShell and git
  - Sysinternals
  - Nvidia
  - Rule for VSCode extension - "XML Red Hat"
  - Fixed a typo in rule for WarThunder game

- Modules

  - `FDResPub` and `fdPHost` services are now required for remote deployment to rule out host
  discovery issues
  - `Merge-SDDL` Added `-Unique` switch to be able to merge SDDL's excluding duplicate ones
  - Update of module help is now done with a new function `Update-ModuleHelp` which updates
  all modules on system which are updatable, reducing update errors to 0
  - Implemented remoting functionality for the following public functions:

    - `ConvertFrom-SDDL`
    - `Get-InterfaceBroadcast`
    - `Get-InterfaceAlias`
    - `Select-IPInterface`
    - `Invoke-Process`
    - `Get-OneDrive`
    - `Edit-Table`
    - `Update-Table`

  - Fixed a bug with `Get-UserSoftware` which didn't target a specified user
  - Fixed a bug in `Get-AppCapability` producing no result for remote session due to virtual admin
  - Fixed a bug in `Test-ExecutableFile` which falsely flaged executable as unsigned in PS Core
  - Fixed a bug in `Test-WinRM` which didn't pass credentials for HTTPS and mishandled CertThumbprint
  - Fixed a bug in `Set-Permission` which couldn't adjust permissions on registry keys
  - Fixed a bug in `Initialize-Service` which reported false failures
  - Fixed a bug in `Test-VirusTotal` which failed to scan executables with environment variable
  - Fixed a bug in `Test-VirusTotal` which failed to find `sigcheck.exe` in certain cases
  - Fixed a bug in `Import-FirewallRule` which caused imported rules to not work
  - Fixed an error in `Get-SqlServerInstance` produced due to `Set-StrictMode`
  - Fixed an error in `Test-Computer` which passed invalid parameter to commandlet
  - Made possible to import and remove modules manually outside deployment process
  - Updated `Ruleset.IP` module according to changes from upstream repository

  - Improved or updated module functions

    - `ConvertFrom-SID`
    - `Test-Computer`
    - `Resolve-Host`
    - `Get-TypeName`
    - `Start-Test` added `-Force` switch to silence errors for intentionall failures
    - `Stop-Test` renamed to `Restore-Test` now used to restore unit test error reporting
    - `Test-Output` Improved to handled functions which might return multiple types
    - `Uninstall-DuplicateModule` used to uninstall outdated modules
    - `Publish-SshKey` Improved for Remote-SSH VSCode extension
    - `Register-SslCertificate` improved to handle multiple certificates with same CN entry
    - `Get-AppSID` added pipeline support
    - `Initialize-Provider`

  - New functionalities

    - `Test-SDDL` function to validate SDDL syntax
    - Added `PolicyFileEditor` new 3rd party module to help with GPO management and renamed to
    `Ruleset.PolicyFileEditor`
    - `Set-Privacy` new script to adjust Windows privacy in a restrictive way
    - `Find-DuplicateModule` function to detect duplicate (outdated) modules on system
    - `Connect-IPInterface` experimental script to troubleshoot obtaining IP from DHCP
    - `Write-ColorMessage` function to write colored messsages as a replacement for `Write-Host`

- Scripts

  - Made possible to specify `localhost` and `.` for deployment (experimental)
  - Made possible to deploy rules for groups other than `Users`, this otherwise means it's now
  possible to deploy rules for Administrators which is useful for Windows Server without any
  standard account
  - `Restart-Network.ps1` script updated, didn't work perfectly due to regression

- Development

  - Added github workflows to:

    - Run PSScriptAnalyzer
    - Generate sitemap xml
    - Publish generated sitemap to google for crawling

  - improved spellcheking with custom dictionaries and configuration of spell check extension
  - Workspace settings and settings for extensions vastly revisited for better coding experience.
  - Resolved almost all issuses reporeted by markdown, xml and yaml linter and PSScriptAnalyzer
  - Replaced `XML tools` extension with `XML Red Hat`
  - Added `YAML` extension to workspace recommendations for YAML support
  - Added `Sort Lines` extension to workspace recommendations
  - Added `Select Line Status Bar` extension to workspace recommendations
  - Added `Toggle Quotes` extension to workspace recommendations
  - Removed `Fix Json` extension from workspace recomendations
  - Removed `Json` extension from workspace recommendations
  - Added debugging configuration for all module functions and scripts to be able to use debugger

- Unit test

  - `Test-FileEncoding.ps1` new test script to verify encoding of all files in repository
  - `Invoke-CodeAnalysis.ps1` (renamed) test script significantly improved with the ability to log issues
  - `Test-ModuleExports.ps1` new test script to ensure all expected symbols are exported
  - `Test-ModuleManifest.ps1` (renamed) script improved to handle more entries for correctness in manifest files
  - `Test-ScriptInfo.ps1` improved for better reporting of issues with script info section
  - New test module `PssaTest.Module` used to test PSScryptAnalyzer rules in `Config\PSScriptAnalyzer.ps1`

[Table of Contents](#table-of-contents)

## v0.13.1

- Modules

  - Updated `Test-ExecutableFile` so that digital signature mismatch is always reported
  - Fixed a bug in `Edit-Table` which didn't account for paths with environment variables
  - Fixed a bug in `Unblock-NetProfile` which threw exceptions without catching them
  - Renamed function `Build-ServiceList` to `Write-ServiceList` to avoid warning about unapproved
  verb in Windows PowerShell

- Scripts

  - `Reset-Firewall` added `-Service` switch which restores modified system services to system defaults
  - Resolved some annoying warnings
  - Converted some errors about unfound programs (registry keys) to warnings

[Table of Contents](#table-of-contents)

## v0.13.0

- Rules

  - Added rules for:

    - Microsoft Edge WebView2
    - Sysinternals sigcheck
    - Microsoft Network Realtime Inspection Service
    - Psiphon censorship circumvention system
    - Added rule for wsmprovhost.exe
    - Open space project

  - Updated rules for:

    - OS built-in programs
    - Multicast
    - Path of Exile game
    - OpenTTD game
    - One Drive
    - Store apps

- Modules

  - Fixed a bug in `Ruleset.Firewall\Find-RulePrincipal` causing wrong output
  - Fixed a bug in `Ruleset.Remote\TestWinRM` causing invalid result
  - Fixed a bug in `Ruleset.UserInfo\Get-GroupPrincipal` causing unexpected SID value
  - Fixed a bug in `Ruleset.Remote` module which prevented deployment with Microsoft account
  - Implemented remoting functionality for the following public functions:

    - `Get-SystemSKU`
    - `Get-GroupPrincipal`
    - `Get-GroupSID`
    - `Get-PrincipalSID`
    - `Get-SDDL`
    - `Get-PathSDDL`
    - `Get-AppCapability`
    - `Get-UserApp`
    - `Get-SystemApp`
    - `Test-FileSystemPath`
    - `Search-Installation`
    - `Confirm-Installation`
    - `Test-ExecutableFile`
    - `Test-Service`
    - `Select-EnvironmentVariable`

  - `Enable-WinRMServer` and `Disable-WinRMServer` added `-KeepDefault` switch to leave default
  session configurations active, needed to be able to specify `-ComputerName` parameter
  instead of `-CimInstance` as exclusive.
  - `Enable-WinRMServer` added `-Loopback` switch to be able to configure loopback only server
  - Most functions in `Ruleset.Remote` improved
  - Added separate PS session configuration for localhost deployment
  - Make `Ruleset.Compatibility` functions show verbose output is set globally

  - Improved module functions

    - `Test-Computer`
    - `Test-Credential`
    - `Test-ExecutableFile` will now perform VirusTotal check if digital signature is missing
    - `Get-NetFramework`

  - Updated module functions

    - `Convert-FromOSBuild` to handle 22H2
    - `Select-EnvironmentVariable` to blacklist `%HOMEDRIVE%` because it's it's incompatible with
    Windows firewall

- New features

  - `Find-WeakRule` new function which finds weak (not restrictive enough) firewall rules
  - `Find-UnsignedFile.ps1` self contained script to scan digital signatures of programs and drivers
  - `Deploy-ASR.ps1` new script used to deploy attack surface reduction rules
  - `Show-ASR.ps1` new script used to display ASR configuration
  - `Set-ATP.ps1` new script used to configure Microsoft Defender Antivirus
  - `Confirm-Firewall.ps1` new experimental script used to validate firewall configuration
  - `Test-RemoteRegistry` new function to test for functioning remote registry
  - `Test-VirusTotal` new module function used to perform VirusTotal analysis on executable
  - `Format-ComputerName` new module function to format computer name to NETBIOS name

- Scripts

  - Specifying remote domain or changing domain no longer requires PS restart
  - Specifying HTTP for remoting is now possible in `Config\ProjectSettings`
  - Added script info to scripts, `REQUIREDSCRIPTS` and `EXTERNALMODULEDEPENDENCIES`
  - Fixed `Get-NetworkStats.ps1` scripts so that it's functional for local and remote

- Documentation

  - Added new documentation concerning security and privacy

[Table of Contents](#table-of-contents)

## v0.12.0

- Rules

  - Added rules for:

    - ColorMania color picker
    - Azure Data studio
    - MS-Edge IRC

  - Updated rules for:

    - Windows System
    - Simple DNS Crypt
    - KMS Connection broker (SppExtComObj.exe)
    - MSI
    - Store apps
    - Intel XTU

  - Rule scripts, consistent rule formatting for all scripts
  - Rule scripts now support Interactive and Quiet switches

- Scripts

  - Firewall deployment with `Deploy-Firewall.ps1` script can be fully automated by using `-Force`,
  `-Confirm` and `-Quiet` switches, ex. `.\Scripts\Deploy-Firewall -Force -Quiet -Confirm:$false`
  won't ask you any questions

- Modules

  - Fixed a bug in `Ruleset.Firewall\ConvertListTo-Multiline` causing bad rule export
  - Improved private functions of `Ruleset.Firewall` module
  - Improved or updated functions:
    - `ConvertFrom-SID`
    - `Split-Principal`
    - `ConvertFrom-SDDL`
    - `Get-SDDL`
    - `Export-FirewallRule`
    - `Import-FirewallRule`
    - `Remove-FirewallRule`
    - `Find-RulePrincipal`
    - `Get-AppCapability`
    - `Get-SystemApps`
    - `Get-UserApps`
    - `ConvertFrom-WildCard`

  - Improved or updated scripts:

    - `Backup-Firewall`
    - `Restore-Firewall`
    - `Reset-Firewall`
    - `Deploy-Firewall`

- New features

  - `Get-RegistryRule` new function which gets firewall rules directly from registry for faster
  rule processing ex. to speed up export\import of rules
  - `Export-RegistryRule` new function which exports firewall rules to file from registry, which
  is much faster compared to `Export-FirewallRule` which uses standard commandlets
  - `Restore-IfBlank` new private helper function to help with generic default values in caller code
  - `ConvertFrom-Protocol` new private help function to convert TPC\IP protocol numbers to string
  representation

- Development

  - Added new recommended extensions:

    - `VSCode Json`
    - `Fix JSON`
    - `Sort JSON objects`

  - Warnings messages now also include function name which is generating the warning

- Documentation

  - Revisited and updated for missing changes introduced since v0.10.0

[Table of Contents](#table-of-contents)

## v0.11.0

- Rules

  - Updated rules for:

    - SQL server,
    - PokerStars,
    - SysInternals,
    - CMake,
    - vcpkg,
    - EpicGames,
    - Visual Studio,
    - Store Apps,
    - MS Office
    - MS Edge (pokerist web app)

  - Added rules for PowerShell remoting
  - Added rules for VSCode remote debugging trough SSH
  - Added rule for UAC

- Scripts

  - Reworked `Config\ProjectSettings` for remoting

- New features

  - A new module used for remoting configuration using WinRM, CIM and remote registry with the
  following functions:
  - `Connect-Computer` function to initialize connection to remote computer
  - `Disable-RemoteRegistry` function to disable remote registry enabled by Enable-RemoteRegistry
  - `Disable-WinRMServer` function to disable WinRM remoting
  - `Disconnect-Computer` function to release resources and disconnect remote host
  - `Enable-RemoteRegistry` function to enable drilling registry remotely
  - `Enable-WinRMServer` function to configure WinRM server for remoting
  - `Export-WinRM` function to export WinRM configuration to file (not implemented)
  - `Publish-SshKey` function to upload and set SSH key to server for remote debugging with VSCode
    over SSH
  - `Register-SslCertificate` function to create, install and export SSL certificate for remoting
  - `Reset-WinRM` function to reset WinRM service and configuration to system defaults
  - `Set-WinRMClient` function to configure client for remoting
  - `Show-WinRMConfig` function to list detailed WinRM configuration
  - `Test-WinRM` function to test and discover issues with remoting configuration
  - `Unregister-SslCertificate` function to uninstall certificate installed by
    Register-SslCertificate

- Modules

  - `Test-TargetComputer` renamed to `Test-Computer` now experimental and no longer useful
  - `Resolve-Host` function improved, removed deprecated API, duplicate code etc.
  - Registry drilling functions updated for remote registry
  - `ConvertFrom-OSBuild` updated for 21H1 and 21H2 OS version (including Windows 11 and server 2022)

- Documentation

  - Revisited few docs for clarity
  - Added document `Remote.md` to breakdown remoting functionality used by this repository

- Bugfix

  - Fixed bug with `WpsPushUserService` rule when applied to multiple standard users
  - Fixed issue with `Test-Computer` when used in Windows PowerShell for NetBIOS name resolution
  - Checking for null of registry keys opened trough registry hive key.

- Other

  - Use old syntax highlighting thanks to workaround after unwanted changes introduced in PS extension
  - Added settings and extensions for remote SSH development
  - Added SSH configuration files and syntax highlighting setting for `*config` files
  - Updated `todo-tree` extension settings for markdown support
  - Improved process monitor configuration files for network activity optionally for TCP or UDP

[Table of Contents](#table-of-contents)

## v0.10.0

- Modules

  - Most module functions significantly improved
  - Several functions were renamed to be more descriptive of their purpose
  - Removed functions: `Update-Context` and `Get-ComputerName`
  - For better pipeline support functions now output objects right away instead of creating an array
  - For consistency, most outputs now follow same custom object property layout and naming convention.

- Rules

  - Updated rule script for git and GitHub Desktop
  - Rules load into firewall if target executable exists and only if it's digitally signed
  - Rules based on services will have services tested for digital signature in addition to
  service existence test
  - GPO is automatically updated if running individual rule scripts manually

- New features

  - `Get-ParameterAlias` script to help harvest function parameter aliases for all installed modules
  - `Set-Shortcut` function to set desktop shortcut to personalized firewall management console
  - `Test-MarkdownLink` function to find dead links in markdown files
  - `Resolve-FileSystem` function to resolve path wildcard pattern or relative paths to `System.IO.*Info`
  - `Reset-TestDrive` function to safely clear test drive directory for cleaner and smoother unit testing
  - `Resolve-Host` function used to resolve host to IP or an IP to host.
  - `Test-UPN` function used to validate syntax of UPN (Universal Principal Name)
  - `Convert-FromSDDL` function to resolve SDDL strings into principal, user name, SID and domain
  - `Test-NetBiosName` function to validate syntax of NETBIOS name
  - `Test-UNC` function to validate syntax of UNC (Universal Naming Convention) name
  - `ConvertFrom-Wildcard` function to convert wildcard pattern to regex
  - `Test-Credential` function to validate credentials
  - `Get-ExportedType.ps1` utility script to list exported types in current session
  - `Get-PropertyType.ps1` utility script to get .NET types of properties
  - `Out-DataTable` utility function to convert object to data table
  - `Get-NetworkStatistics.ps1` utility script to run netstat remotely and parse data into object
  - `Initialize-Development.ps1` utility script to quickly set up git, gpg and development environment

- Tests

  - Unit tests have consistent test drive defined

- Scripts

  - Added PSScriptInfo comment to scripts that are not part of modules
  - Added CmdletBinding to scripts and `-Force` switch to skip prompt
  - Added `-Trusted` switch to rule scripts to ignore missing digital signature or signature mismatch
  - Master script `SetupFirewall.ps1` was renamed to `Deploy-Firewall.ps1`, improved and redesigned
  for automatic firewall deployment in addition to manual procedure selection
  - Most scripts were renamed to better describe their intended future purpose

- Documentation

  - `NamingConvention.md` new document to explain naming convention used by project code

- Design

  - Pramenter names and aliases follow naming convention according to community development
  guidelines
  - 3rd party scripts from `External` directories merged into the rest of project code, there is no
  point to separate code based on contributors involved.
  - Revisited Write-* commandlets to be consistent and more detailed.

- Bugfix

  - Function and script outputs are formatted with the help of `Format.ps1xml` file for consistent
  output
  - Running individual functions and scripts with common parameters such as `-Debug` or `-Verbose`
  switch did not respect the switch, fixed

[Table of Contents](#table-of-contents)

## v0.9.0

- Rules

  - Added rules for "Bing walpaper" app
  - Added rules for PSPing from sysinternals
  - Fixed rules and search for Adobe reader and Acrobat
  - Updated rules for Java runtime

  - Partially improved the following rules:
    - ICMPv6
    - CoreNetworking
    - Multicast
    - NetworkDiscovery
    - NetworkSharing
    - DNSCrypt
    - Broadcast

  - Network profile and interface type defaults are now controlable via global variable

- Modules

  - Added new module `Ruleset.Compatibility` because `Appx` module no longer works since PowerShell
  Core 7.1
  - Improved functions:
    - `Approve-Execute`
    - `Test-TargetComputer`
    - `Get-GroupPrincipal`
    - `ConvertFrom-SID`
    - `Get-AppSID` big thanks to @ljani for awesome solution [solution][appsid-issue]
    - `Get-SystemSKU`
  - Logging without the need for parameter splating, `@Logs` variable was removed
  - Improved program search algorithm
  - Inheritance of preference variables into module reworked and now valid for manifest modules only,
  and only as defined in `ProjectSettings.ps1`, no inheritance from caller scope
  - Various funny looking messages appearing in the console are now simplified or removed
  - Added `Write-FileLog` to write logs on demand in addition to automated logging

- Documentation

  - Updated/improved all docs
  - Links in markdown are now reference links instead of inline links
  - Added comment based help for rule scripts

- New features

  - Experimental scripts to start/stop packet trace and capture.
  - `Select-HiddenProperty` Utility script to list "hidden" rule properties
  - More control and utilization of preference variables, see `ProjectSettings.ps1`
  - `ProjectSettings` script reworked to declare variables only as needed and to show variable status
  on demand for current scope
  - Script to quickly collect audit entries to help track down packet drop reason
  - Changes done to services as part of prerequisite are now logged

- Test

  - Unit tests will write logs to separate directory
  - Fixed some pester tests

- Bugfix

  - `Restart-Network.ps1` script didn't work for virtual adapters
  - Rules for `WORKGROUP` didn't work
  - Maximum valid .NET Framework limitation in Windows PowerShell is 4.5 (4.8 not recognized)
  - Error starting dependent services because of invalid parameter name
  - Getting One Drive installation directory would fail
  - Connection errors when using Windows PowerShell because dependent service was not checked
  - No longer asking to set network profile, because it results in missing profile settings in
  `Settings -> "Network & Internet"`
  - Update of help files would fail on system that never run `Update-Help`
  - `Backup-Firewall` would fail exporting by rule DisplayGroup
  - Force loading rules for GitHub Desktop would result in error
  - Force loading rules for NVIDIA resulted in error if no drivers are installed

[Table of Contents](#table-of-contents)

## v0.8.0

- Rules

  - Added rules for DHCP client and server
  - Added rule to allow router configuration

- Modules

  - Improved script for setting permission to read firewall logs as standard user
  - Improved Test-Environment function to handle more contexts for path validity detection
  - Improved Format-Path function to be more efficient
  - Improved Get-TypeName function to get precise type of an object such as function output.
  - Removed Get-UserProfile function.
  - Other minor module improvements
  - Renamed modules to `Ruleset.<ModuleName>` because not time for other platforms.

- New features

  - Added script to restart/reset network and network configuration with no need for reboot
  - Added function Set-Permission to set ownership and file saystem premissions
  - Added function Get-EnvironmentVariable to retrieve multiple variables of specific "group"
  - Added function to compare 2 paths for equality or similarity
  - Added script Set-Privilege to let add or remove privileges to PowerShell process

- Documentation

  - Comment based help, update formatting according to community quidelines
  - Comment based help, check .INPUTS, .OUTPUTS and OutputType are specified and up to date
  - Updated help notices for LAN setup, including workaround to make it work with this firewall.

- Bugfix

  - Grant-Logs.ps1 did not set permission to create firewall log filter file
  - Checking for requirements would run for every script in development mode
  - DHCP configured computer won't connect to internet
  - Fixed various minor mistakes

- Test

  - Added Test-Output function to compare function outputs with OutputType attribute
  - Added New-Section function to print new sections to separate test cases for readability

- Other

  - Calls to icacls, takeown and file system permission code replaced with call to Set-Permission
  - Add `Scripts` directory to path for current session

[Table of Contents](#table-of-contents)

## v0.7.0

- Modules

  - Improved SID conversion function
  - Added function to learn store app capabilities (ex. to see which store apps have networking capability)
  - Module manifests: replaced 1 duplicate and 1 wrong GUID, added required assembly entry,
  replaced single with double quotes, reordered file list alphabetically, uncomment required entries,
  all modules are now recognized as manifest modules.
  - Reordered external module code and removed non file licenses
  - Indented.Net.IP: integrate into project, rename module, make variables casing consistent
  - Improved search algorithm for Microsoft office installation root
  - Improved Test-Environment function to test for invalid environment variables
  - "Contacting computer" messages are now part of verbose stream
  - Improved provider and module initialization

- Rules

  - Fix rules for store apps that apply to multiple apps (ex. Administrators and temporary rules)
  - Rules for store apps are now created only for apps that have networking capabilities and
  remote address is adjusted according to app capabilities.
  - Added rule for curl shipped with system
  - Updated rules for Visual Studio
  - Added initial rule for dotnet.exe
  - Added new rules for Windows version "20H2"
  - Added rule for Microsoft account
  - Search algorithm and rule creation choice for OneDrive now includes all users,
  including those not logged into machine

- New features

  - Command line help is now fully functional, for each prompt you can type `?` to get more information
  - New function "Get-ProcessOutput" to wait for and capture process (command) output when run in PS
  - Project code is now tested also on these editions: Education, Server 2019 Datacenter

- Development

  - Updated templates and small portion of scripts according to templates
  - Updated project and module initialization functions
  - Added platyPS module to list of recommended modules to be able to generate online help files
  - Added new recommended extensions and extension settings to tail firewall logs with VSCode

- Documentation

  - Generated online help files in markdown format for modules, can be accessed with `Get-Help -Online`
  - Revisited comment based help for mistakes, added missing comment based help for scripts

- Bugfix

  - Fix bug with Initialize-Module failing to update module due to invalid parameter
  - Fix bug with Initialize-Module failing to update PowerShellGet due to unset variable
  - Fix bug with Get-FileEncoding due to overridden variable
  - Don't show path correction message if there was no change to program path
  - Show warning instead of code error if target machine not connected to network
  - Registering PowerShell repository would fail due to unknown trust policy

[Table of Contents](#table-of-contents)

## v0.6.0

- New features

  - Added functionality to import/export rules into CSV/JSON file and delete rules according to file
  - Module for requirements renamed to "Initialize" and significantly improved to automatically
    enable system services, check module updates, package providers and core project requirement checks.
    Note that some of this functionality must be manually enabled.
  - Added new variables to control requirements checks, and to reduce module imports and code bloat
  - All file input/output uses same encoding and file read operation is checked for encoding before read

- Rules

  - Updated rules for GitHub Desktop and Epic games

- Development

  - Updated analyzer settings for newest version and latest fixes
  - Added new extensions to recommended list and improved workspace settings
  - All tests were updated for clean run
  - revisited todo list and removed duplicates for global todo list
  - Non module scripts are separated into "Scripts" folder

- Documentation

  - Added steps to [disable Firewall](DisableFirewall.md)
  - Added steps for [general network troubleshooting](NetworkTroubleshooting.md)
  - Documentation updated, spellchecked and formatted in full

- Modules

  - Improved SID conversion function
  - Added function to detect file encoding, needed to verify rules before importing them, and also
  to be able to share logs and other project files between Windows PowerShell and Core edition.
  - Renamed modules to better fit with project naming convention
  - Moved few functions to different modules
  - Reorganized module file and directory structure according to community best practices
  - Added function to convert to or query system SKU
  - Several minor module code changes

[Table of Contents](#table-of-contents)

## v0.5.0

- Modules

  - Updated user query functions and tests to make possible querying store app identities
  - Improved network adapter query to optionally query disconnected, hidden and virtual interfaces
  - State changing functions will ask for confirmation if impact high enough
  - Added function to query for OneDrive instances installation search

- Rules

  - Added rules for store apps to allow web authentication
  - Minor updates to some rules
  - Added temporary troubleshooting rules (purpose to make log file clean)
  - Added address space variables
  - Rules for OneDrive now correctly load and don't need manual adjustment
  - Added rules for League of Legends game
  - Rules for Nvidia now load conditionally based on presence of GeForce experience (needs improvements)

- Bugfixes

  - Prevent generating errors is removing rules from empty firewall
  - Fix error resetting global firewall settings

- Development

  - Resolve all analyzer warnings (some functions were renamed)
  - Updated template scripts
  - Updated test scripts for ComputerInfo and UserInfo modules
  - Added test rules based on interface alias for all network interface types
  - Removed deprecated scripts, home group rules were retained but are not used

- Documentation

  - Add instructions for LAN setup
  - Random updates to docs, fixed dead links and formatting
  - Done some spell checking

- New features

  - Added mTail configuration and sound alert files
  - Firewall log files are not separated for each profile (public, private, domain)
  - Set network profile for each connected hardware interface
  - Set/reset global firewall settings
  - Reset-Firewall script also deletes IPSec rules
  - Script to unblock all files in project, for scripts that were downloaded from GitHub
    to prevent spamming YES/NO questions while executing them.
  - Updated some informational messages to be more descriptive and less annoying.

[Table of Contents](#table-of-contents)

## v0.4.1

- Modules

  - Updated version numbers
  - Updated informational messages to include label for "System" module
  - Added more system requirements checks required for clean run

- Rules

  - Make possible to load rules for multiple valid Visual Studio instances, including VS Preview
  - Hardcoded path for Visual Studio rule replaced with dynamic path

- Development

  - Disabled false positive PSScriptAnalyzer warning

- Documentation

  - Added `FAQ.md`
  - Updated main page `README.md`

[Table of Contents](#table-of-contents)

## v0.4.0

- Rules

  - Updated rules for qBittorrent to be more restrictive
  - Added new rules for intel
  - Update updater rule for OneDrive and git according to task scheduler
  - Update rules for NVIDIA, still needs improvements
  - Update rules for Tor browser, add rule for Edge-chromium FTP
  - Updated rules for, VS, steam, Epic games, qbittorrent

- Bugfixes

  - Informational messages from modules would be hidden in non "Develop" mode
  - User prompt for multiple installation directory would be skipped causing script hang
  - System requirements check was disabled, also added checks for additional required services,
    which were causing errors.

- Development

  - Added PSScriptAnalyzer rules and settings
  - Added workspace settings for Visual Studio code
  - Added JSON settings for recommended extensions
  - Added initial launch configurations for debugger
  - Code formatted and updated according to PSScriptAnalyzer rules
  - todo list categorized according to area and priority, duplicates removed
  - Markdown formatted according to markdownlint rules
  - Entire project spellchecked
  - Added regex samples to query rules in scripts for bulk operations

- Documentation

  - Updated various documentation and notices about project

[Table of Contents](#table-of-contents)

## v0.3.0

- New features

  - Scripts now work on PowerShell core 7, with the goal to expand to other operating systems
    (ie. linux)
  - Better configurable logging and much more streams, this will help to see what the code does in
    real time.
  - Project wide settings `Config\ProjectSettings.ps1` are updated for changes and significantly
    improved.
  - Improved program installation search + more registry drilling functions
  - Improved and new functions to query users and groups on multiple computers

- Bug fixes

  - Modules are renamed to avoid name clashes with other modules
  - Format-Path function would index into empty array if environment variable not found
  - Minor errors resolved thanks to strict mode
  - Format-Path would return bad result if there is only a single environment variable
  - Update-Table would produce an error if Get-InstallProperties fails to get a list of programs from
    registry

- Performance

  - Minor improvements in searching registry

- Development

  - Symbols and keywords have their casing consistent and updated
  - Strict mode is now on, latest level
  - Support for both editions of PowerShell, Desktop and Core
  - Modules, comments, todo list, help and readme files are updated
  - All files converted to UTF-8 and Tabs-4 (CRLF), gitattributes updated few new file types

[Table of Contents](#table-of-contents)

## v0.2

- New features

  - Support for Windows Server in addition to Windows 10
  - Rebalanced rules for administrators, disabled where not needed, added where needed
  - More and updated temporary rules
  - Updated documentation, specifically main readme.md, `FirewallParameters.md` and more PS command
    samples.
  - Add functions to query SQL Instances on network and SQL related software cmdlets.
  - Move configuration specific global variables into a separate file

- Bugfixes

  - Executing rules for store apps would fail for new Windows accounts
  - Store apps rule for administrators did not work
  - Update some rules which were incorrect
  - Fixed Show-SDDL function, bug in borrowed code
  - Reduce required .NET to 4.5, which is minimum for PowerShell 5.1, and maximum allowed for module
    requirement.

- Development

  - Make all files use tabs instead of spaces
  - Expand modules to include correct comments, help and manifest files
  - A few more todo's, notes and relevant comments
  - Reorganize and split scripts with rules for multiple targets

[Table of Contents](#table-of-contents)

[changelog]: https://github.com/metablaster/WindowsFirewallRuleset/blob/develop/docs/CHANGELOG.md "Visit latest changelog"
[appsid-issue]: https://github.com/metablaster/WindowsFirewallRuleset/issues/6 "See issue"
