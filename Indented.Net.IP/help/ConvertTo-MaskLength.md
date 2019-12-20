---
external help file: Indented.Net.IP-help.xml
Module Name: Indented.Net.IP
online version:
schema: 2.0.0
---

# ConvertTo-MaskLength

## SYNOPSIS
Convert a dotted-decimal subnet mask to a mask length.

## SYNTAX

```
ConvertTo-MaskLength [-SubnetMask] <IPAddress> [<CommonParameters>]
```

## DESCRIPTION
A count of the number of 1's in a binary string.

## EXAMPLES

### EXAMPLE 1
```
ConvertTo-MaskLength 255.255.255.0
```

Returns 24, the length of the mask in bits.

## PARAMETERS

### -SubnetMask
A subnet mask to convert into length.

```yaml
Type: IPAddress
Parameter Sets: (All)
Aliases: Mask

Required: True
Position: 2
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Net.IPAddress
## OUTPUTS

### System.Int32
## NOTES

## RELATED LINKS
