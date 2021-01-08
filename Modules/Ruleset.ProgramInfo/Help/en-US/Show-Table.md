---
external help file: Ruleset.ProgramInfo-help.xml
Module Name: Ruleset.ProgramInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Show-Table.md
schema: 2.0.0
---

# Show-Table

## SYNOPSIS

Print installation directories to console

## SYNTAX

```powershell
Show-Table [[-Caption] <String>] [<CommonParameters>]
```

## DESCRIPTION

Prints found program data which includes program name, program ID, install location etc.

## EXAMPLES

### EXAMPLE 1

```powershell
Show-Table "Table data"
```

## PARAMETERS

### -Caption

Single line string to print before printing the table

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You cannot pipe objects to Show-Table

## OUTPUTS

### None. Show-Table does not generate any output

## NOTES

This function is needed to avoid warning of write-host inside non "Show" function

## RELATED LINKS
