---
external help file: Ruleset.Test-help.xml
Module Name: Ruleset.Test
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Test/Help/en-US/Exit-Test.md
schema: 2.0.0
---

# Exit-Test

## SYNOPSIS

Un-initialize and exit unit test

## SYNTAX

```powershell
Exit-Test [-Private] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Exit-Test performs finishing steps after unit test is done, ie.
to restore previous state
Must be called in pair with Enter-Test and after all test cases are done in single unit test

## EXAMPLES

### EXAMPLE 1

```powershell
Exit-Test
```

### EXAMPLE 2

```powershell
Exit-Test -Private
```

## PARAMETERS

### -Private

Should be specified to exit test that was entered with Enter-Test -Private

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

### [string]

## NOTES

TODO: Write-Information instead of Write-Output, but problem is that is may be logged

## RELATED LINKS
