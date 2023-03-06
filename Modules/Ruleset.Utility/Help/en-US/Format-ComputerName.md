---
external help file: Ruleset.Utility-help.xml
Module Name: Ruleset.Utility
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Format-ComputerName.md
schema: 2.0.0
---

# Format-ComputerName

## SYNOPSIS

Format computer name to NETBIOS format

## SYNTAX

```powershell
Format-ComputerName [-Domain] <String> [<CommonParameters>]
```

## DESCRIPTION

Format-ComputerName formats computer name string to NETBIOS format

## EXAMPLES

### EXAMPLE 1

```powershell
Format-ComputerName localhost
```

NETBIOSNAME

### EXAMPLE 2

```powershell
Format-ComputerName server01
```

SERVER01

## PARAMETERS

### -Domain

Computer name which to format

```yaml
Type: System.String
Parameter Sets: (All)
Aliases: ComputerName, CN

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [string]

## OUTPUTS

### None. Format-ComputerName does not generate any output

## NOTES

TODO: Need to handle FQDN

## RELATED LINKS
