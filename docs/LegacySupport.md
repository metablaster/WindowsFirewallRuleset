
# How to make use of this project on older Windows systems

**First, note that Home versions of Windows do not ship with GPO (Local Group Policy),
therefore not supported by this project.**

There are workarounds for home editions however, but no help is provided here

These notices here are valid for the following Windows versions:

1. Windows vista up to Windows 8.1
2. Windows server 2008 up to Windows server 2016

There is no support or help here for systems older than that.

To be able to apply rules to these systems you'll need to modify code.\
At a bare minimum you should do the modifications described here

## Table of Contents

- [How to make use of this project on older Windows systems](#how-to-make-use-of-this-project-on-older-windows-systems)
  - [Table of Contents](#table-of-contents)
  - [Initialization module](#initialization-module)
  - [Project settings](#project-settings)
  - [Target platform variable](#target-platform-variable)
  - [OS software](#os-software)
  - [Testing](#testing)

## Initialization module

Edit the module named `Ruleset.Initialize` to allow execution for older system.

## Project settings

Edit script `Config\ProjectSettings.ps1` and define new variable that defines your system version,\
the following variable is defined to target Windows 10.0 versions and above by default for all rules.\
```New-Variable -Name Platform -Option Constant -Scope Global -Value "10.0+""```

For example for Windows 7, define a new variable that looks like this:\
```New-Variable -Name PlatformWin7 -Option Constant -Scope Global -Value "6.1"```

`Platform` variable specifies which version of Windows the associated rule applies.\
The acceptable format for this parameter is a number in the `Major.Minor` format.

For more information about other Windows systems and their version numbers see link below:\
[Operating System Version][os version]

There are other variables in `Config\ProjectSettings.ps1` that are worth changing, at a minimum
set `Develop` to `$true` and restart PowerShell to enable debugging features and
additional requirement checks.

## Target platform variable

Edit individual ruleset scripts, and take a look which rules you want or need to be loaded on
target system,\
then simply replace ```-Platform $Platform``` with ie. ```-Platform $PlatformWin7```
for each rule you want.

In VS Code for example you can also simply (CTRL + F) for each script and replace all instances.\
If you miss something you can delete, add or modify rules in GPO later.

Note that if you define your platform globally (ie. ```$Platform = "6.1"```) instead of making your
own variable, just replacing the string, but do not exclude unrelated rules,
most of the rules should work, but ie. rules for Store Apps might fail to load.

Also ie. rules for programs and services that don't exist on system will be most likely applied
but redundant.

What this means, is, just edit the GPO later to refine your imports if you go that route,
or alternatively revisit your edits and rerun individual scripts again.

## OS software

It's hard to tell what software or module dependencies might be required for your target environment,
and once you learn that you should modify version requirements in `Config\ProjectSettings.ps1`

For example .NET framework version 4.5 for Windows PowerShell may be required to be able to use some
commandlets from modules, either those which ship with Windows or those which are part of this
repository.

## Testing

To save yourself some time debugging you should also run code analysis with
[PSScriptAnalyzer][module psscriptanalyzer] with the following rules enabled:

1. PSUseCompatibleCmdlets
2. PSUseCompatibleSyntax

Visit `Test` directory and run all tests individually to confirm modules and their functions work as
expected, any failure should be fixed before loading rules to save yourself from frustration.

[Table of Contents](#table-of-contents)

[os version]: https://docs.microsoft.com/en-us/windows/win32/sysinfo/operating-system-version "Visit Microsoft docs"
[module psscriptanalyzer]: https://github.com/PowerShell/PSScriptAnalyzer "Visit PSScriptAnalyzer repository"
