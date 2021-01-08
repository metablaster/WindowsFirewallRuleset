---
external help file: Ruleset.ProgramInfo-help.xml
Module Name: Ruleset.ProgramInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Initialize-Table.md
schema: 2.0.0
---

# Initialize-Table

## SYNOPSIS

Create data table used to hold information for a list of programs

## SYNTAX

```powershell
Initialize-Table [[-Name] <String>] [<CommonParameters>]
```

## DESCRIPTION

Create data table which is filled with data about programs and principals such
as users or groups and their SID for which given firewall rule applies
This method is primarily used to reset the table
Each entry in the table also has an ID to help choosing entries by ID

## EXAMPLES

### EXAMPLE 1

```powershell
Initialize-Table
```

## PARAMETERS

### -Name

Table name

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: InstallTable
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You cannot pipe objects to Initialize-Table

## OUTPUTS

### None. Initialize-Table does not generate any output

## NOTES

TODO: There should be a better way to drop the table instead of recreating it
TODO: We should initialize table with complete list of programs and principals and
return the table by reference

## RELATED LINKS
