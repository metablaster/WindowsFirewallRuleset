---
external help file: Ruleset.IP-help.xml
Module Name: Ruleset.IP
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.IP/Help/en-US/Get-NetworkRange.md
schema: 2.0.0
---

# Get-NetworkRange

## SYNOPSIS

Get a list of IP addresses within the specified network.

## SYNTAX

### FromIPAndMask (Default)

```none
Get-NetworkRange [-IPAddress] <String> [[-SubnetMask] <String>] [-IncludeNetworkAndBroadcast]
 [<CommonParameters>]
```

### FromStartAndEnd

```none
Get-NetworkRange -Start <IPAddress> -End <IPAddress> [<CommonParameters>]
```

## DESCRIPTION

Get-NetworkRange finds the network and broadcast address as decimal values
then starts a counter between the two, returning IPAddress for each.

## EXAMPLES

### EXAMPLE 1

```none
Get-NetworkRange 192.168.0.0 255.255.255.0
```

Returns all IP addresses in the range 192.168.0.0/24.

### EXAMPLE 2

```none
Get-NetworkRange 10.0.8.0/22
```

Returns all IP addresses in the range 192.168.0.0 255.255.252.0.

## PARAMETERS

### -IPAddress

Either a literal IP address, a network range expressed as CIDR notation,
or an IP address and subnet mask in a string.

```yaml
Type: System.String
Parameter Sets: FromIPAndMask
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -SubnetMask

A subnet mask as an IP address.

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

### -IncludeNetworkAndBroadcast

Include the network and broadcast addresses when generating a network address range.

```yaml
Type: System.Management.Automation.SwitchParameter
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

The end address of a range.

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

### [string]

## OUTPUTS

### [ipaddress]

## NOTES

Following changes by metablaster:
- Include licenses and move comment based help outside of functions
- For code to be consistent with project code formatting and symbol casing.
- Removed unnecessary position arguments, added default argument values explicitly.

## RELATED LINKS
