---
external help file: Ruleset.Test-help.xml
Module Name: Ruleset.Test
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Test/Help/en-US/Start-Test.md
schema: 2.0.0
---

# Start-Test

## SYNOPSIS

Start test case

## SYNTAX

```powershell
Start-Test [-Message] <String> [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Start-Test writes output to host to separate test cases.
Formatted message block is shown in the console.
This function must be called before single test case starts executing

## EXAMPLES

### EXAMPLE 1

```powershell
Start-Test "Get-Something"
```

**************************
* Testing: Get-Something *
**************************

## PARAMETERS

### -Message

Message to format and print before test case begins

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
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

### None. You cannot pipe objects to Start-Test

## OUTPUTS

### None. Start-Test does not generate any output

## NOTES

TODO: switch for no new line, some tests will produce redundant new lines, ex.
Format-Table in pipeline
TODO: Doesn't work starting tests inside dynamic modules

## RELATED LINKS
