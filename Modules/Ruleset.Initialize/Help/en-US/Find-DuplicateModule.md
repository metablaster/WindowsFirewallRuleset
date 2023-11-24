---
external help file: Ruleset.Initialize-help.xml
Module Name: Ruleset.Initialize
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Initialize/Help/en-US/Find-DuplicateModule.md
schema: 2.0.0
---

# Find-DuplicateModule

## SYNOPSIS

Finds duplicate modules

## SYNTAX

```powershell
Find-DuplicateModule [[-Name] <String[]>] [[-Scope] <String[]>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION

Finds duplicate modules installed on system taking care of PS edition being used.

To find duplicate modules for Windows PowerShell, Desktop edition should be used,
otherwise to find duplicates for PS Core, Core edition should be used.

## EXAMPLES

### EXAMPLE 1

```powershell
Find-DuplicateModule
```

ModuleType Version    Name                  ExportedCommands
Binary     1.0.0.1    PackageManagement     {Find-Package, Get-Package, Get-PackageProvider, Get-PackageSource...}
Script     1.4.8.1    PackageManagement     {Find-Package, Get-Package, Get-PackageProvider, Get-PackageSource...}
Script     3.4.0      Pester                {Describe, Context, It, Should...}
Script     5.3.3      Pester                {Invoke-Pester, Describe, Context, It...}
Script     1.0.0.1    PowerShellGet         {Install-Module, Find-Module, Save-Module, Update-Module...}
Script     2.2.5      PowerShellGet         {Find-Command, Find-DSCResource, Find-Module, Find-RoleCapability...}
Script     2.0.0      PSReadline            {Get-PSReadLineKeyHandler, Get-PSReadLineOption...}
Script     2.2.6      PSReadline            {Get-PSReadLineKeyHandler, Get-PSReadLineOption...}

### EXAMPLE 2

```powershell
Find-DuplicateModule -Name PackageMan* -Scope System
```

ModuleType Version    Name                  ExportedCommands
Binary     1.0.0.1    PackageManagement     {Find-Package, Get-Package, Get-PackageProvider, Get-PackageSource...}
Script     1.4.8.1    PackageManagement     {Find-Package, Get-Package, Get-PackageProvider, Get-PackageSource...}

## PARAMETERS

### -Name

One or more module names which to check for duplicates.
Wildcard characters are supported.

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: *
Accept pipeline input: False
Accept wildcard characters: True
```

### -Scope

Specifies one or more scopes (installation locations) in which to search for duplicate modules,
possible values are:
Shipping: Modules which are part of PowerShell installation
System: Modules installed for all users
User: Modules installed for current user

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProgressAction

{{ Fill ProgressAction Description }}

```yaml
Type: System.Management.Automation.ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You cannot pipe objects to Find-DuplicateModule

## OUTPUTS

### [PSModuleInfo]

## NOTES

None.

## RELATED LINKS
