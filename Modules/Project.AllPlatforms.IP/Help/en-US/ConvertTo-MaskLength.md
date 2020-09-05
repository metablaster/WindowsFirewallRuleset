---
external help file: Project.AllPlatforms.IP-help.xml
Module Name: Project.AllPlatforms.IP
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/develop/Modules/Project.AllPlatforms.IP/Help/en-US/ConvertTo-MaskLength.md
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
Type: System.Net.IPAddress
Parameter Sets: (All)
Aliases: Mask

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
