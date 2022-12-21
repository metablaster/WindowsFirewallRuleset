---
external help file: Ruleset.Initialize-help.xml
Module Name: Ruleset.Initialize
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Initialize/Help/en-US/Uninstall-DuplicateModule.md
schema: 2.0.0
---

# Uninstall-DuplicateModule

## SYNOPSIS

Uninstall duplicate modules

## SYNTAX

```powershell
Uninstall-DuplicateModule [[-Name] <String[]>] [-Scope <String[]>] [-Force] [<CommonParameters>]
```

## DESCRIPTION

Uninstall-DuplicateModule uninstalls duplicate modules per PS edition leaving only the most
recent versions of a module.

Sometimes uninstalling a module in a conventional way is not possible, example cases are:
1.
Modules which ship with system
2.
Modules locked by other modules
3.
Modules which prevent updating them

Updating modules which ship with system can't be done, only side by side installation is
possible, with the help of this function those outdated and useless modules are removed from system.

Case from point 2 above is recommended only when there are 2 exactly same modules installed,
but the duplicate you are trying to remove is used (locked) instead of first one.

## EXAMPLES

### EXAMPLE 1

```powershell
Uninstall-DuplicateModule -Name PowerShellGet, PackageManagement -Scope Shipping, System -Force
```

Removes outdated PowerShellGet and PackageManagement modules excluding those installed per user

### EXAMPLE 2

```powershell
Get-Module -FullyQualifiedName @{ModuleName = "PackageManagement"; RequiredVersion = "1.0.0.1" } |
Uninstall-DuplicateModule
```

First get module you know should be removed and pass it to pipeline

## PARAMETERS

### -Name

One or more module names which to uninstall if duplicates are found.
If not specified all duplicates are processed.
Wildcard characters are supported.

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases: Module

Required: False
Position: 1
Default value: *
Accept pipeline input: True (ByValue)
Accept wildcard characters: True
```

### -Scope

Specifies one or more scopes (installation locations) from which to uninstall duplicate modules,
possible values are:
Shipping: Modules which are part of PowerShell installation
System: Modules installed for all users
User: Modules installed for current user

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force

If specified, all duplicate modules specified by -Name are removed without further prompt.
This parameter also forces recursive actions on module installation directory,
ex taking ownership and setting file system permissions required for module uninstallation.
It also forces removing read only modules.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [string] module name

### [PSModuleInfo] module object by property Name

## OUTPUTS

### None. Uninstall-DuplicateModule does not generate any output

## NOTES

Module which is to be uninstalled must not be in use by:
1.
Other PowerShell session
2.
Some system process
3.
Session in VSCode
4.
Current session prompt must not point to anywhere in target module path
TODO: Should support ShouldProcess

## RELATED LINKS
