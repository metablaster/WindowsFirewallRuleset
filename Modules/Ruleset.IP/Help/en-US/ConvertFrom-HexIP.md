---
external help file: Ruleset.IP-help.xml
Module Name: Ruleset.IP
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.IP/Help/en-US/ConvertFrom-HexIP.md
schema: 2.0.0
---

# ConvertFrom-HexIP

## SYNOPSIS

Converts a hexadecimal IP address into a dotted decimal string.

## SYNTAX

```powershell
ConvertFrom-HexIP [-IPAddress] <String> [<CommonParameters>]
```

## DESCRIPTION

ConvertFrom-HexIP takes a hexadecimal string and returns a dotted decimal IP address.
An intermediate call is made to ConvertTo-DottedDecimalIP.

## EXAMPLES

### EXAMPLE 1

```powershell
ConvertFrom-HexIP c0a80001
```

Returns the IP address 192.168.0.1.

## PARAMETERS

### -IPAddress

An IP Address to convert.

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

### [string] Hexadecimal IP address

## OUTPUTS

### [IPAddress] A dotted decimal IP address

## NOTES

Modifications by metablaster year 2019, 2020:

- Include licenses and move comment based help outside of functions
- For code to be consistent with project code formatting and symbol casing.
- Removed unnecessary position arguments, added default argument values explicitly.

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.IP/Help/en-US/ConvertFrom-HexIP.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.IP/Help/en-US/ConvertFrom-HexIP.md)

[https://github.com/indented-automation/Indented.Net.IP](https://github.com/indented-automation/Indented.Net.IP)
