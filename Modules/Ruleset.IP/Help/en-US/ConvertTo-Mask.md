---
external help file: Ruleset.IP-help.xml
Module Name: Ruleset.IP
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.IP/Help/en-US/ConvertTo-Mask.md
schema: 2.0.0
---

# ConvertTo-Mask

## SYNOPSIS

Convert a mask length to a dotted-decimal subnet mask

## SYNTAX

```powershell
ConvertTo-Mask [-MaskLength] <Byte> [<CommonParameters>]
```

## DESCRIPTION

ConvertTo-Mask returns a subnet mask in dotted decimal format from an integer value ranging between 0 and 32.
ConvertTo-Mask creates a binary string from the length,
converts the string to an unsigned 32-bit integer then calls ConvertTo-DottedDecimalIP to complete the operation.

## EXAMPLES

### EXAMPLE 1

```powershell
ConvertTo-Mask 24
```

Returns the dotted-decimal form of the mask, 255.255.255.0

## PARAMETERS

### -MaskLength

The number of bits which must be masked.

```yaml
Type: System.Byte
Parameter Sets: (All)
Aliases: Length

Required: True
Position: 1
Default value: 0
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [byte] A mask length ranging between 0 and 32

## OUTPUTS

### [IPAddress] A dotted-decimal subnet mask

## NOTES

Modifications by metablaster year 2019, 2020:

- Include licenses and move comment based help outside of functions
- For code to be consistent with project code formatting and symbol casing.
- Removed unnecessary position arguments, added default argument values explicitly.

January 2021:

- Added parameter debugging stream

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.IP/Help/en-US/ConvertTo-Mask.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.IP/Help/en-US/ConvertTo-Mask.md)

[https://github.com/indented-automation/Indented.Net.IP](https://github.com/indented-automation/Indented.Net.IP)
