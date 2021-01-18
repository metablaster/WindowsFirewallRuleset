
# Ruleset.Compatibility

## about_Ruleset.Compatibility

## SHORT DESCRIPTION

Windows PowerShell Compatibility Pack

## LONG DESCRIPTION

This module provides PowerShell Core 6 compatibility with existing Windows PowerShell scripts

## EXAMPLES

```powershell
Add-WindowsPSModulePath
```

Appends the existing Windows PowerShell PSModulePath to existing PSModulePath

```powershell
Add-WinFunction
```

This command defines a global function that always runs in the compatibility session

```powershell
Compare-WinModule
```

Compare the set of modules against those in the compatibility session

```powershell
Copy-WinModule
```

Copy modules from the compatibility session that are directly usable in PowerShell Core

```powershell
Get-WinModule
```

Get a list of the available modules from the compatibility session

```powershell
Import-WinModule
```

Import a compatibility module

```powershell
Initialize-WinSession
```

Initialize the connection to the compatibility session

```powershell
Invoke-WinCommand
```

Invoke a ScriptBlock that runs in the compatibility runspace

## ALIASES

Add-WinPSModulePath -> Add-WindowsPSModulePath

## KEYWORDS

- Compatibility
- WindowsPowerShell
- Core

## SEE ALSO

https://github.com/metablaster/WindowsFirewallRuleset/tree/master/Modules/Ruleset.Compatibility/Help/en-US
https://github.com/PowerShell/WindowsCompatibility
