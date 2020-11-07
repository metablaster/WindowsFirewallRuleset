---
external help file: Ruleset.ProgramInfo-help.xml
Module Name: Ruleset.ProgramInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Find-Installation.md
schema: 2.0.0
---

# Find-Installation

## SYNOPSIS

Find installation directory for given predefined program name

## SYNTAX

```none
Find-Installation [-Program] <String> [[-ComputerName] <String>] [<CommonParameters>]
```

## DESCRIPTION

Find-Installation is called by Test-Installation, ie.
only if test for existing path
fails then this method kicks in

## EXAMPLES

### EXAMPLE 1

```none
Find-Installation "Office"
```

## PARAMETERS

### -Program

Predefined program name

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

### -ComputerName

Computer name on which to look for program installation

```yaml
Type: System.String
Parameter Sets: (All)
Aliases: Computer, Server, Domain, Host, Machine

Required: False
Position: 2
Default value: [System.Environment]::MachineName
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You cannot pipe objects to Find-Installation

## OUTPUTS

### [bool] true or false if installation directory if found, installation table is updated

## NOTES

None.

## RELATED LINKS
