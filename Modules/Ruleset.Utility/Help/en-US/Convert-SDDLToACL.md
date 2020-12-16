---
external help file: Ruleset.Utility-help.xml
Module Name: Ruleset.Utility
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Convert-SDDLToACL.md
schema: 2.0.0
---

# Convert-SDDLToACL

## SYNOPSIS

Convert SDDL string to ACL

## SYNTAX

```powershell
Convert-SDDLToACL [-SDDL] <String[]> [<CommonParameters>]
```

## DESCRIPTION

Convert SDDL strings to ACL entries

## EXAMPLES

### EXAMPLE 1

```powershell
Convert-SDDLToACL $SomeSDDL, $SDDL2, "D:(A;;CC;;;S-1-5-84-0-0-0-0-0)"
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
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You cannot pipe objects to Convert-SDDLToACL

## OUTPUTS

### [string]

## NOTES

This is experimental function and needs a lot of improvements.

## RELATED LINKS
