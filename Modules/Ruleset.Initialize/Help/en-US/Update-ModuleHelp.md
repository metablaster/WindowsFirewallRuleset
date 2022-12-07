---
external help file: Ruleset.Initialize-help.xml
Module Name: Ruleset.Initialize
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Initialize/Help/en-US/Update-ModuleHelp.md
schema: 2.0.0
---

# Update-ModuleHelp

## SYNOPSIS

Update PowerShell help files

## SYNTAX

### Name (Default)

```powershell
Update-ModuleHelp [[-Name] <String[]>] [-UICulture <CultureInfo[]>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Full

```powershell
Update-ModuleHelp [[-FullyQualifiedName] <ModuleSpecification[]>] [-UICulture <CultureInfo[]>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Update-ModuleHelp updates help files for modules installed with PowerShell edition
which is used to run this function.
Unlike conventional Update-Help commandlet Update-ModuleHelp updates only those modules
for which update is possible without generating errors with update.

## EXAMPLES

### EXAMPLE 1

```powershell
Update-ModuleModuleHelp
```

### EXAMPLE 2

```powershell
Update-ModuleHelp "PowerShellGet" -UICulture ja-JP, en-US
```

## PARAMETERS

### -Name

Updates help for the specified modules.
Enter one or more module names or name patterns in a comma-separated list.
Wildcard characters are supported.

```yaml
Type: System.String[]
Parameter Sets: Name
Aliases: Module

Required: False
Position: 1
Default value: *
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: True
```

### -FullyQualifiedName

The value can be a module name, a full module specification, or a path to a module file.

When the value is a path, the path can be fully qualified or relative.
A relative path is resolved relative to the script that contains the using statement.

When the value is a name or module specification, PowerShell searches the PSModulePath for the specified module.
A module specification is a hashtable that has the following keys:

ModuleName - Required Specifies the module name.
GUID - Optional Specifies the GUID of the module.
It's also Required to specify at least one of the three below keys.
ModuleVersion - Specifies a minimum acceptable version of the module.
MaximumVersion - Specifies the maximum acceptable version of the module.
RequiredVersion - Specifies an exact, required version of the module.
This can't be used with the other Version keys.

```yaml
Type: Microsoft.PowerShell.Commands.ModuleSpecification[]
Parameter Sets: Full
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -UICulture

If specified, only modules supporting the specified UI culture are updated.
The default value is en-US

```yaml
Type: System.Globalization.CultureInfo[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: $DefaultUICulture
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf

Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm

Prompts you for confirmation before running the cmdlet.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You cannot pipe objects to Update-ModuleModuleHelp

## OUTPUTS

### None. Update-ModuleModuleHelp does not generate any output

## NOTES

TODO: Not using ValueFromPipeline because an array isn't distinguished from hashtable to select
proper parameter set name

## RELATED LINKS
