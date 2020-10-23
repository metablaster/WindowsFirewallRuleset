---
external help file: Project.AllPlatforms.Utility-help.xml
Module Name: Project.AllPlatforms.Utility
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/develop/Modules/Project.AllPlatforms.Utility/Help/en-US/Set-NetworkProfile.md
schema: 2.0.0
---

# Set-NetworkProfile

## SYNOPSIS

Set network profile for physical network interfaces

## SYNTAX

```none
Set-NetworkProfile [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Set network profile for each physical/hardware network interfaces
Recommended is 'Public' profile for maximum security, unless 'Private' is needed

## EXAMPLES

### EXAMPLE 1

```none
Set-NetworkProfile
```

## PARAMETERS

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

### None. You cannot pipe objects to Set-NetworkProfile

## OUTPUTS

### None.

## NOTES

None.

## RELATED LINKS
