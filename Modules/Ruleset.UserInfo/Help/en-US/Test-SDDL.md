---
external help file: Ruleset.UserInfo-help.xml
Module Name: Ruleset.UserInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.UserInfo/Help/en-US/Test-SDDL.md
schema: 2.0.0
---

# Test-SDDL

## SYNOPSIS

Validate SDDL string

## SYNTAX

```powershell
Test-SDDL [-SDDL] <String[]> [-PassThru] [<CommonParameters>]
```

## DESCRIPTION

Test-SDDL checks the syntax of a SDDL string.
It does not check the existence of a principal which the SDDL represents.

## EXAMPLES

### EXAMPLE 1

```powershell
Test-SDDL D:(A;;CC;;;S-1-5-21-2050798540-3232431180-3229034493-1002)(A;;CC;;;S-1-5-21-2050798540-3232341180-3229034493-1001)
```

## PARAMETERS

### -SDDL

SDDL strings which to test

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

### -PassThru

If specified, the return value is SDDL string if it's valid, otherwise null.
By default boolean test is performed.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You cannot pipe objects to Test-SDDL

## OUTPUTS

### [bool] true if SDDL string is valid, false otherwise

### [string] If SDDL string is valid it's returned, otherwise null

## NOTES

None.

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.UserInfo/Help/en-US/Test-SDDL.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.UserInfo/Help/en-US/Test-SDDL.md)
