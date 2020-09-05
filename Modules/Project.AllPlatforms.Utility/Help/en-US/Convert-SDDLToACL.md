---
external help file: Project.AllPlatforms.Utility-help.xml
Module Name: Project.AllPlatforms.Utility
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/develop/Modules/Project.AllPlatforms.Utility/Help/en-US/Convert-SDDLToACL.md
schema: 2.0.0
---

# Convert-SDDLToACL

## SYNOPSIS
Convert SDDL entries to computer accounts

## SYNTAX

```
Convert-SDDLToACL [-SDDL] <String[]> [<CommonParameters>]
```

## DESCRIPTION
TODO: add description

## EXAMPLES

### EXAMPLE 1
```
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

### [string[]] Array of computer accounts
## NOTES
None.

## RELATED LINKS
