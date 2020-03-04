
# Here is a list of changes for each of releases

# Changelog v0.3.x

## Development

- Added PSScriptAnalyzer rules and settings
- Added workspace settings for Visual Studio code
- Added JSON settings for recommended extensions
- Added initial launch configurations for debugger
- Code formatted and updated according to PSScriptAnalyzer rules
- TODO list categorized according to area and priority, duplicates removed
- Markdown formatted according to markdownlint rules
- Entry project spellchecked
- Added regex samples to query rules inside scripts for bulk operations

# Changelog v0.3.0

## New features

- Scripts now work on PowerShell core 7, with the goal to expand to other operating systems
  (ie. linux)
- Better configurable logging and much more streams, this will help to see what the code does in
  real time.
- Project wide settings `Config\ProjectSettings.ps1` are updated for changes and significantly
  improved.
- Improved program installation search + more registry drilling functions
- Improved and new functions to query users and groups on multiple computers

## Bug fixes

- Modules are renamed to avoid name clashes with other modules
- Format-Path function would index into empty array if environment variable not found
- Minor errors resolved thanks to strict mode
- Format-Path would return bad result if there is only a single environment variable
- Update-Table would produce an error if Get-AllUserPrograms fails to get a list of programs from
  registry

## Performance

- Minor improvements in searching registry

## Development

- Symbols and keywords have their casing consistent and updated
- Strict mode is now on, latest level
- Support for both editions of PowerShell, Desktop and Core
- Modules, comments, TODO list, help and readme files are updated
- All files converted to UTF-8 and Tabs-4 (CRLF), gitattributes updated few new file types

# Changelog v0.2

## New features

- Support for Windows Server in addition to Windows 10
- Rebalanced rules for administrators, disabled where not needed, added where needed
- More and updated temporary rules
- Updated documentation, specifically main readme.md, FirewallParameters.md and more PS command
  samples.
- Add functions to query SQL Instances on network and SQL related software cmdlets.
- Move configuration specific global variables into a separate file

## Bugfixes

- Executing rules for store apps would fail for new Windows accounts
- Store apps rule for administrators did not work
- Update some rules which were incorrect
- Fixed Show-SDDL function, bug in borrowed code
- Reduce required .NET to 4.5, which is minimum for PowerShell 5.1, and maximum allowed for module
  requirement.

## Development

- Make all files use tabs instead of spaces
- Expand modules to include correct comments, help and manifest files
- A few more TODO's, notes and relevant comments
- Reorganize and split scripts with rules for multiple targets
