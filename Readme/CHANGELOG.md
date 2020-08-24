
# Changelog

Here is a list of changes for each of the releases

## Table of contents

- [Changelog](#changelog)
  - [Table of contents](#table-of-contents)
  - [v0.6.0 (develop branch)](#v060-develop-branch)
  - [v0.5.0 (current release)](#v050-current-release)
  - [v0.4.1](#v041)
  - [v0.4.0](#v040)
  - [v0.3.0](#v030)
  - [v0.2](#v02)

## v0.6.0 (develop branch)

- New features

  - Added functionality to import/export rules into CSV/JSON file and delete rules according to file
  - Module for requirements renamed to "Initialize" and significantly improved to automatically enable
    system services, check module updates, package providers and core project requirement checks
    Note that some of this functionality must be manually enabled.
  - Added new variables to control requirements checks, and to reduce module imports and code bloat

- Rules

  - Updated rules for GitHub Desktop and Epic games

- Development

  - Updated analyzer settings for newest version and latest fixes
  - Added new extensions to recommended list and improved workspace settings

- Documentation

  - Added steps to [disable firewall](https://github.com/metablaster/WindowsFirewallRuleset/blob/develop/Readme/DisableFirewall.md)
  - Added steps for [general network troubleshooting](https://github.com/metablaster/WindowsFirewallRuleset/blob/develop/Readme/NetworkTroubleshooting.md)
  - Documentation updated, spellchecked and formatted in full

- Modules

  - Improved SID conversion function
  - Added function to detect file encoding, needed to verify rules before importing them, and also
  to be able to share logs and other project files between Windows PowerShell and Core edition.
  - Renamed modules to better fit with project naming convention
  - Moved few functions to different modules
  - Reorganized module structure according to community best practices
  - Added function to convert to or query system SKU
  - Several minor module code changes

## v0.5.0 (current release)

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
  - ResetFirewall script also deletes IPSec rules
  - Script to unblock all files in project, for scripts that were downloaded from GitHub
    to prevent spamming YES/NO questions while executing them.
  - Updated some informational messages to be more descriptive and less annoying.

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
  - Entry project spellchecked
  - Added regex samples to query rules inside scripts for bulk operations

- Documentation

  - Updated various documentation and notices about project

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
  - Update-Table would produce an error if Get-AllUserSoftware fails to get a list of programs from
    registry

- Performance

  - Minor improvements in searching registry

- Development

  - Symbols and keywords have their casing consistent and updated
  - Strict mode is now on, latest level
  - Support for both editions of PowerShell, Desktop and Core
  - Modules, comments, todo list, help and readme files are updated
  - All files converted to UTF-8 and Tabs-4 (CRLF), gitattributes updated few new file types

## v0.2

- New features

  - Support for Windows Server in addition to Windows 10
  - Rebalanced rules for administrators, disabled where not needed, added where needed
  - More and updated temporary rules
  - Updated documentation, specifically main readme.md, FirewallParameters.md and more PS command
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
