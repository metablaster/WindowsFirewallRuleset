---
external help file: Ruleset.ProgramInfo-help.xml
Module Name: Ruleset.ProgramInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Format-Path.md
schema: 2.0.0
---

# Format-Path

## SYNOPSIS

Format path into firewall compatible path

## SYNTAX

```powershell
Format-Path [[-FilePath] <String>] [<CommonParameters>]
```

## DESCRIPTION

Various paths drilled out of registry, and those specified by the user must be
checked and properly formatted.
Formatted paths will also help sorting rules in firewall GUI based on path.

## EXAMPLES

### EXAMPLE 1

```powershell
Format-Path "C:\Program Files\\Dir\"
```

## PARAMETERS

### -FilePath

File path to format, can have environment variables, or consists of trailing slashes.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [string] File path to format

## OUTPUTS

### [string] formatted path, includes environment variables, stripped off of junk

## NOTES

TODO: This should proably be inside utility module,
it's here since only this module uses this function.

## RELATED LINKS
