
# Changelog v0.2

# New features
1. Support for Windows Server in addition to Windows 10
2. Rebalance rules for administrators, disabled where not needed, added where needed
3. More and updated temporary rules
4. Updated documentation, specifically main readme.md, FirewallParameters.md and more PS command samples.
5. Add functions to query SQL Instances on network and SQL related software cmdlets.
6. Move configuration specific global variables into a separate file

# Bugfixes
1. Executing rules for store apps would fail for new Windows accounts
2. Store apps rule for administrators did not work
3. Update some rules which were incorrect
4. Fixed Show-SDDL function, bug in borrowed code
5. Reduce required .NET to 4.5, which is minimum for PowerShell 5.1, and maximum allowed for module requirement.

# Development
1. Make all files use tabs instead of spaces
2. Expand modules to include correct comments, help and manifest files
3. A few more TODO's, notes and relevant comments
4. Reorganize and split scripts with rules for multiple targets

# Changelog v0.3

# New fetures
1. Scripts now work on PowerShell core 7, with the goal to expand to other operating systems. (ie. linux)
2. Better configurable logging and much more streams, this will help to see what the code does in real time.
3. Project wide settings (ProjectSettings.ps1) are updated for changes and significally improved.

# Bug fixes
1. Modules are renamed to avoid name clashes with other modules

# Development
1. Symbols and keywords have their casing consistent
