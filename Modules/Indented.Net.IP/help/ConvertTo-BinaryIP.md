---
external help file: Indented.Net.IP-help.xml
Module Name: Indented.Net.IP
online version:
schema: 2.0.0
---

# ConvertTo-BinaryIP

## SYNOPSIS
Converts a Decimal IP address into a binary format.

## SYNTAX

```
ConvertTo-BinaryIP [-IPAddress] <IPAddress> [<CommonParameters>]
```

## DESCRIPTION
ConvertTo-BinaryIP uses System.Convert to switch between decimal and binary format.
The output from this function is dotted binary.

## EXAMPLES

### EXAMPLE 1
```
ConvertTo-BinaryIP 1.2.3.4
```

Convert an IP address to a binary format.

## PARAMETERS

### -IPAddress
An IP Address to convert.

```yaml
Type: IPAddress
Parameter Sets: (All)
Aliases:

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

### System.String
## NOTES

## RELATED LINKS
