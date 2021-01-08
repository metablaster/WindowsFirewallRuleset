---
external help file: Ruleset.UserInfo-help.xml
Module Name: Ruleset.UserInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.UserInfo/Help/en-US/ConvertFrom-SDDL.md
schema: 2.0.0
---

# ConvertFrom-SDDL

## SYNOPSIS

Convert SDDL string to Principal

## SYNTAX

```powershell
ConvertFrom-SDDL [-SDDL] <String[]> [<CommonParameters>]
```

## DESCRIPTION

Convert one or multiple SDDL strings to Principals

## EXAMPLES

### EXAMPLE 1

```powershell
ConvertFrom-SDDL $SomeSDDL, $SDDL2, "D:(A;;CC;;;S-1-5-84-0-0-0-0-0)"
```

### EXAMPLE 2

```
$SomeSDDL, $SDDL2, "D:(A;;CC;;;S-1-5-84-0-0-0-0-0)" | ConvertFrom-SDDL
```

## PARAMETERS

### -SDDL

String array of one or more strings of SDDL syntax

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [string[]]

## OUTPUTS

### [PSCustomObject]

## NOTES

None.

## RELATED LINKS
