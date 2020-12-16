---
external help file: Ruleset.IP-help.xml
Module Name: Ruleset.IP
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.IP/Help/en-US/ConvertTo-Subnet.md
schema: 2.0.0
---

# ConvertTo-Subnet

## SYNOPSIS

Convert a start and end IP address to the closest matching subnet.

## SYNTAX

### FromIPAndMask (Default)

```powershell
ConvertTo-Subnet [-IPAddress] <String> [[-SubnetMask] <String>] [<CommonParameters>]
```

### FromStartAndEnd

```powershell
ConvertTo-Subnet -Start <IPAddress> -End <IPAddress> [<CommonParameters>]
```

## DESCRIPTION

ConvertTo-Subnet attempts to convert a starting and ending IP address from a range to the closest subnet.

## EXAMPLES

### EXAMPLE 1

```powershell
ConvertTo-Subnet -Start 0.0.0.0 -End 255.255.255.255
```

### EXAMPLE 2

```powershell
ConvertTo-Subnet -Start 192.168.0.1 -End 192.168.0.129
```

### EXAMPLE 3

```powershell
ConvertTo-Subnet 10.0.0.23/24
```

### EXAMPLE 4

```powershell
ConvertTo-Subnet 10.0.0.23 255.255.255.0
```

## PARAMETERS

### -IPAddress

Any IP address in the subnet.

```yaml
Type: System.String
Parameter Sets: FromIPAndMask
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SubnetMask

A subnet mask.

```yaml
Type: System.String
Parameter Sets: FromIPAndMask
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Start

The first IP address from a range.

```yaml
Type: System.Net.IPAddress
Parameter Sets: FromStartAndEnd
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -End

The last IP address from a range.

```yaml
Type: System.Net.IPAddress
Parameter Sets: FromStartAndEnd
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You cannot pipe objects to ConvertTo-Subnet

## OUTPUTS

### "Ruleset.IP.Subnet" Custom object

## NOTES

Modifications by metablaster year 2019, 2020:
- Include licenses and move comment based help outside of functions
- For code to be consistent with project code formatting and symbol casing.
- Removed unnecessary position arguments, added default argument values explicitly.

## RELATED LINKS
