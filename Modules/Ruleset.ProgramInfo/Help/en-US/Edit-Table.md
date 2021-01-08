---
external help file: Ruleset.ProgramInfo-help.xml
Module Name: Ruleset.ProgramInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Edit-Table.md
schema: 2.0.0
---

# Edit-Table

## SYNOPSIS

Manually add new program installation directory to the table

## SYNTAX

```powershell
Edit-Table [-Path] <String> [<CommonParameters>]
```

## DESCRIPTION

Based on path and if it's valid path fill the table with it and add principals and other information
Module scope installation table is updated

## EXAMPLES

### EXAMPLE 1

```powershell
Edit-Table "%ProgramFiles(x86)%\TeamViewer"
```

## PARAMETERS

### -Path

Program installation directory

```yaml
Type: System.String
Parameter Sets: (All)
Aliases: InstallLocation

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You cannot pipe objects to Edit-Table

## OUTPUTS

### None. Edit-Table does not generate any output

## NOTES

TODO: principal parameter?
TODO: search executable paths

## RELATED LINKS
