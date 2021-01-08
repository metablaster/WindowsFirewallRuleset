---
external help file: Ruleset.ComputerInfo-help.xml
Module Name: Ruleset.ComputerInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ComputerInfo/Help/en-US/ConvertFrom-OSBuild.md
schema: 2.0.0
---

# ConvertFrom-OSBuild

## SYNOPSIS

Convert from OS build number to OS version

## SYNTAX

```powershell
ConvertFrom-OSBuild [-Build] <Decimal> [<CommonParameters>]
```

## DESCRIPTION

Convert from OS build number to OS version associated with build.
Note that "OS version" is not the same as "OS release version"

## EXAMPLES

### EXAMPLE 1

```powershell
ConvertFrom-OSBuild 18363.1049
```

1909

## PARAMETERS

### -Build

Operating system build number

```yaml
Type: System.Decimal
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You cannot pipe objects to ConvertFrom-OSBuild

## OUTPUTS

### [string]

## NOTES

The ValidatePattern attribute matches decimal part as (,\d{2,5})?
instead of (\.\d{3,5})?
because
ex.
19041.450 will convert to 19041,45, last zeroes will be dropped and dot is converted to coma.

## RELATED LINKS
