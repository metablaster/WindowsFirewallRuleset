---
external help file: Ruleset.IP-help.xml
Module Name: Ruleset.IP
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.IP/Help/en-US/Resolve-IPAddress.md
schema: 2.0.0
---

# Resolve-IPAddress

## SYNOPSIS

Resolves an IP address expression using wildcard expressions to individual IP addresses.

## SYNTAX

```none
Resolve-IPAddress [-IPAddress] <String> [<CommonParameters>]
```

## DESCRIPTION

Resolves an IP address expression using wildcard expressions to individual IP addresses.
Resolve-IPAddress expands groups and values in square brackets to generate a list of IP addresses or networks using CIDR-notation.
Ranges of values may be specified using a start and end value using "-" to separate the values.
Specific values may be listed as a comma separated list.

## EXAMPLES

### EXAMPLE 1

```none
Resolve-IPAddress "10.[1,2].[0-2].0/24"
```

Returns the addresses 10.1.0.0/24, 10.1.1.0/24, 10.1.2.0/24, 10.2.0.0/24, and so on.

## PARAMETERS

### -IPAddress

The IPAddress expression to resolve.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String

## OUTPUTS

### TODO: describe outputs, define OutputType

## NOTES

Following changes by metablaster:
- Include licenses and move comment based help outside of functions
- For code to be consistent with project code formatting and symbol casing.
- Removed unnecessary position arguments, added default argument values explicitly.

## RELATED LINKS
