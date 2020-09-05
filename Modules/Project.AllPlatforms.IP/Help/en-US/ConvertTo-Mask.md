---
external help file: Project.AllPlatforms.IP-help.xml
Module Name: Project.AllPlatforms.IP
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/develop/Modules/Project.AllPlatforms.IP/Help/en-US/ConvertTo-Mask.md
schema: 2.0.0
---

# ConvertTo-Mask

## SYNOPSIS

Convert a mask length to a dotted-decimal subnet mask.

## SYNTAX

```none
ConvertTo-Mask [-MaskLength] <Byte> [<CommonParameters>]
```

## DESCRIPTION

ConvertTo-Mask returns a subnet mask in dotted decimal format from an integer value ranging between 0 and 32.
ConvertTo-Mask creates a binary string from the length,
converts the string to an unsigned 32-bit integer then calls ConvertTo-DottedDecimalIP to complete the operation.

## EXAMPLES

### EXAMPLE 1

```none
ConvertTo-Mask 24
```

Returns the dotted-decimal form of the mask, 255.255.255.0.

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

### System.Int32

## OUTPUTS

### TODO: describe outputs

## NOTES

Following changes by metablaster:
- Include licenses and move comment based help outside of functions
- For code to be consistent with project code formatting and symbol casing.
- Removed unnecessary position arguments, added default argument values explicitly.

## RELATED LINKS

