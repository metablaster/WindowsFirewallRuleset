---
external help file: Project.AllPlatforms.IP-help.xml
Module Name: Project.AllPlatforms.IP
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/develop/Modules/Project.AllPlatforms.IP/Help/en-US/ConvertTo-BinaryIP.md
schema: 2.0.0
---

# ConvertTo-BinaryIP

## SYNOPSIS

Converts a Decimal IP address into a binary format.

## SYNTAX

```none
ConvertTo-BinaryIP [-IPAddress] <IPAddress> [<CommonParameters>]
```

## DESCRIPTION

ConvertTo-BinaryIP uses System.Convert to switch between decimal and binary format.
The output from this function is dotted binary.

## EXAMPLES

### EXAMPLE 1

```none
ConvertTo-BinaryIP 1.2.3.4
```

Convert an IP address to a binary format.

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

### System.Net.IPAddress

## OUTPUTS

### TODO: describe outputs

## NOTES

Following changes by metablaster:
- Include licenses and move comment based help outside of functions
- For code to be consistent with project code formatting and symbol casing.
- Removed unnecessary position arguments, added default argument values explicitly.

## RELATED LINKS

