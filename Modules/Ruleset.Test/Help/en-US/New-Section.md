---
external help file: Ruleset.Test-help.xml
Module Name: Ruleset.Test
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Test/Help/en-US/New-Section.md
schema: 2.0.0
---

# New-Section

## SYNOPSIS

Print new unit test section

## SYNTAX

```powershell
New-Section [-Message] <String> [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

New-Section prints new section to group multiple test cases.
Useful for unit test with a lof of test cases, for readability.

## EXAMPLES

### EXAMPLE 1

```powershell
New-Section "This is new section"
```

## PARAMETERS

### -Message

Section title

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

### None. You cannot pipe objects to New-Section

## OUTPUTS

### None. New-Section does not generate any output

## NOTES

TODO: Write-Information instead of Write-Output

## RELATED LINKS
