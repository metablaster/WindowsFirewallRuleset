---
external help file: Project.AllPlatforms.Test-help.xml
Module Name: Project.AllPlatforms.Test
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/develop/Modules/Project.AllPlatforms.Test/Help/en-US/Exit-Test.md
schema: 2.0.0
---

# Exit-Test

## SYNOPSIS

Exit unit test

## SYNTAX

```none
Exit-Test [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Exit-Test performs finishing steps after unit test is done, ie.
to restore previous state
This function must be called after all test cases are done in single unit test

## EXAMPLES

### EXAMPLE 1

```none
Exit-Test
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

### None. You cannot pipe objects to Exit-Test

## OUTPUTS

### None.

## NOTES

None.

## RELATED LINKS

