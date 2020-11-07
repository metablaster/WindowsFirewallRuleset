---
external help file: Ruleset.IP-help.xml
Module Name: Ruleset.IP
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.IP/Help/en-US/ConvertTo-HexIP.md
schema: 2.0.0
---

# ConvertTo-HexIP

## SYNOPSIS

Convert a dotted decimal IP address into a hexadecimal string.

## SYNTAX

```none
ConvertTo-HexIP [-IPAddress] <IPAddress> [<CommonParameters>]
```

## DESCRIPTION

ConvertTo-HexIP takes a dotted decimal IP and returns a single hexadecimal string value.

## EXAMPLES

### EXAMPLE 1

```none
ConvertTo-HexIP 192.168.0.1
```

Returns the hexadecimal string c0a80001.

## PARAMETERS

### -IPAddress

An IP Address to convert.

```yaml
Type: System.Net.IPAddress
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

### [ipaddress]

## OUTPUTS

### [string] A hexadecimal string

## NOTES

Following changes by metablaster:
- Include licenses and move comment based help outside of functions
- For code to be consistent with project code formatting and symbol casing.
- Removed unnecessary position arguments, added default argument values explicitly.

## RELATED LINKS
