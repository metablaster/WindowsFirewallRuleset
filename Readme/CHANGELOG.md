
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
