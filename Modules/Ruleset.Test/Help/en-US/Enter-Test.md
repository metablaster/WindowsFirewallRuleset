---
external help file: Ruleset.Test-help.xml
Module Name: Ruleset.Test
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Test/Help/en-US/Enter-Test.md
schema: 2.0.0
---

# Enter-Test

## SYNOPSIS

Initialize unit test

## SYNTAX

```none
Enter-Test [-Private] [-Pester] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Enter-Test initializes unit test, ie.
to enable logging
This function must be called before first test case in single unit test

## EXAMPLES

### EXAMPLE 1

```none
Enter-Test "Get-Something.ps1"
```

## PARAMETERS

### -Private

If specified temporarily exports private module functions into global scope

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

### -Pester

Should be specified to enter private function pester test

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

### None. You cannot pipe objects to Enter-Test

## OUTPUTS

### None. Enter-Test does not generate any output

## NOTES

TODO: Get file name of unit test automatically

## RELATED LINKS
