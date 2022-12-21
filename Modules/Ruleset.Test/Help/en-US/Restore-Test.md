---
external help file: Ruleset.Test-help.xml
Module Name: Ruleset.Test
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Test/Help/en-US/Restore-Test.md
schema: 2.0.0
---

# Restore-Test

## SYNOPSIS

Stop test case

## SYNTAX

```powershell
Restore-Test [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Restore-Test writes output to console after test case is done
This function must be called after single test case is done executing

## EXAMPLES

### EXAMPLE 1

```powershell
Restore-Test
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

### None. You cannot pipe objects to Restore-Test

## OUTPUTS

### None. Restore-Test does not generate any output

## NOTES

None.

## RELATED LINKS
