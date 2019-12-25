---
external help file: Indented.Net.IP-help.xml
Module Name: Indented.Net.IP
online version:
schema: 2.0.0
---

# Get-NetworkRange

## SYNOPSIS
Get a list of IP addresses within the specified network.

## SYNTAX

### FromIPAndMask (Default)
```
Get-NetworkRange [-IPAddress] <String> [[-SubnetMask] <String>] [-IncludeNetworkAndBroadcast]
 [<CommonParameters>]
```

### FromStartAndEnd
```
Get-NetworkRange -Start <IPAddress> -End <IPAddress> [<CommonParameters>]
```

## DESCRIPTION
Get-NetworkRange finds the network and broadcast address as decimal values then starts a counter between the two, returning IPAddress for each.

## EXAMPLES

### EXAMPLE 1
```
Get-NetworkRange 192.168.0.0 255.255.255.0
```

Returns all IP addresses in the range 192.168.0.0/24.

### EXAMPLE 2
```
Get-NetworkRange 10.0.8.0/22
```

Returns all IP addresses in the range 192.168.0.0 255.255.252.0.

## PARAMETERS

### -IPAddress
Either a literal IP address, a network range expressed as CIDR notation, or an IP address and subnet mask in a string.

```yaml
Type: String
Parameter Sets: FromIPAndMask
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -SubnetMask
A subnet mask as an IP address.

```yaml
Type: String
Parameter Sets: FromIPAndMask
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeNetworkAndBroadcast
Include the network and broadcast addresses when generating a network address range.

```yaml
Type: SwitchParameter
Parameter Sets: FromIPAndMask
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Start
The start address of a range.

```yaml
Type: IPAddress
Parameter Sets: FromStartAndEnd
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -End
The end address of a range.

```yaml
Type: IPAddress
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

### System.String
## OUTPUTS

### System.Net.IPAddress
## NOTES

## RELATED LINKS
