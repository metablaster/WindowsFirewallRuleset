---
external help file: Ruleset.IP-help.xml
Module Name: Ruleset.IP
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.IP/Help/en-US/ConvertTo-DottedDecimalIP.md
schema: 2.0.0
---

# ConvertTo-DottedDecimalIP

## SYNOPSIS

Converts either an unsigned 32-bit integer or a dotted binary string to an IP Address

## SYNTAX

```powershell
ConvertTo-DottedDecimalIP [-IPAddress] <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION

ConvertTo-DottedDecimalIP uses a regular expression match on the input string to convert to an IP address.

## EXAMPLES

### EXAMPLE 1

```powershell
ConvertTo-DottedDecimalIP 11000000.10101000.00000000.00000001
```

Convert the binary form back to dotted decimal, resulting in 192.168.0.1.

### EXAMPLE 2

```powershell
ConvertTo-DottedDecimalIP 3232235521
```

Convert the decimal form back to dotted decimal, resulting in 192.168.0.1.

## PARAMETERS

### -IPAddress

A string representation of an IP address from either UInt32 or dotted binary.

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

### -ProgressAction

{{ Fill ProgressAction Description }}

```yaml
Type: System.Management.Automation.ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [string] IP address

## OUTPUTS

### [IPAddress] IP address

## NOTES

Modifications by metablaster year 2019, 2020:

- Include licenses and move comment based help outside of functions
- For code to be consistent with project code formatting and symbol casing.
- Removed unnecessary position arguments, added default argument values explicitly.

January 2021:

- Added parameter debugging stream

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.IP/Help/en-US/ConvertTo-DottedDecimalIP.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.IP/Help/en-US/ConvertTo-DottedDecimalIP.md)

[https://github.com/indented-automation/Indented.Net.IP](https://github.com/indented-automation/Indented.Net.IP)
