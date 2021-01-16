---
external help file: Ruleset.Test-help.xml
Module Name: Ruleset.Test
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Test/Help/en-US/Stop-Test.md
schema: 2.0.0
---

# Stop-Test

## SYNOPSIS

Stop test case

## SYNTAX

```powershell
Stop-Test [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Stop-Test writes output to console after test case is done
This function must be called after single test case is done executing

## EXAMPLES

### EXAMPLE 1

```powershell
Stop-Test
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

### None. You cannot pipe objects to Stop-Test

## OUTPUTS

### None. Stop-Test does not generate any output

## NOTES

This function is not used for now.
TODO: Start-Test should set error action preference to SilentlyContinue for failure tests,
then this function could restore it.

## RELATED LINKS
