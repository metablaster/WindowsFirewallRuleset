---
external help file: Ruleset.Compatibility-help.xml
Module Name: Ruleset.Compatibility
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Compatibility/Help/en-US/Copy-WinModule.md
schema: 2.0.0
---

# Copy-WinModule

## SYNOPSIS

Copy modules from the compatibility session that are directly usable in PowerShell Core.

## SYNTAX

```none
Copy-WinModule [[-Name] <String[]>] [-ComputerName <String>] [-ConfigurationName <String>]
 [-Credential <PSCredential>] [-Destination <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Copy modules from the compatibility session that are directly usable in PowerShell Core.
By default, these modules will be copied to $Home/Documents/PowerShell/Modules.
This can be overridden using the -Destination parameter.
Once these modules have been copied,
they will be available just like the other native modules for PowerShell Core.

Note that if there already is a module in the destination corresponding to the module
to be copied's name, it will not be copied.

## EXAMPLES

### EXAMPLE 1

```powershell
Copy-WinModule hyper-v -WhatIf -Verbose
```

Run the copy command with -WhatIf to see what would be copied to $PSHome/Modules.
Also show Verbose information.

### EXAMPLE 2

```powershell
Copy-WinModule hyper-v -Destination ~/Documents/PowerShell/Modules
```

Copy the specified module to your user module directory.

## PARAMETERS

### -Name

Specifies names or name patterns of modules that will be copied.
Wildcard characters are permitted.

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: *
Accept pipeline input: False
Accept wildcard characters: False
```

### -ComputerName

If you don't want to use the default compatibility session,
use this parameter to specify the name of the computer on which to create the compatibility session.
(Defaults to 'localhost')

```yaml
Type: System.String
Parameter Sets: (All)
Aliases: cn

Required: False
Position: Named
Default value: localhost
Accept pipeline input: False
Accept wildcard characters: False
```

### -ConfigurationName

Specifies the configuration to connect to when creating the compatibility session
(Defaults to 'Microsoft.PowerShell')

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Microsoft.PowerShell
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential

If needed, use this parameter to specify credentials for the compatibility session

```yaml
Type: System.Management.Automation.PSCredential
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Destination

The location where compatible modules should be copied to

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
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

### None. You cannot pipe objects to Copy-WinModule

## OUTPUTS

### None. Copy-WinModule does not generate any output

## NOTES

## RELATED LINKS
