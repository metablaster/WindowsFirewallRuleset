---
external help file: Ruleset.IP-help.xml
Module Name: Ruleset.IP
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.IP/Help/en-US/Get-Subnet.md
schema: 2.0.0
---

# Get-Subnet

## SYNOPSIS

Get a list of subnets of a given size within a defined supernet

## SYNTAX

```powershell
Get-Subnet [-IPAddress] <String> [[-SubnetMask] <String>] -NewSubnetMask <String> [<CommonParameters>]
```

## DESCRIPTION

Generates a list of subnets for a given network range using either
the address class or a user-specified value.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-Subnet 10.0.0.0 255.255.255.0 -NewSubnetMask 255.255.255.192
```

Four /26 networks are returned.

### EXAMPLE 2

```powershell
Get-Subnet 0/22 -NewSubnetMask 24
```

64 /24 networks are returned.

## PARAMETERS

### -IPAddress

Any address in the super-net range.
Either a literal IP address,
a network range expressed as CIDR notation, or an IP address and subnet mask in a string.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SubnetMask

The subnet mask of the network to split.
Mandatory if the subnet mask is not included in the IPAddress parameter.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NewSubnetMask

Split the existing network described by the IPAddress and subnet mask using this mask.

```yaml
Type: System.String
Parameter Sets: (All)
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

### None. You cannot pipe objects to Get-Subnet

## OUTPUTS

### "Ruleset.IP.Subnet" [PSCustomObject]

## NOTES

Change log:

- 07/03/2016 - Chris Dent - Cleaned up code, added tests.
- 12/12/2015 - Chris Dent - Redesigned.
- 13/10/2011 - Chris Dent - Created.

Modifications by metablaster year 2019, 2020:

- Include licenses and move comment based help outside of functions
- For code to be consistent with project code formatting and symbol casing.
- Removed unnecessary position arguments, added default argument values explicitly.

January 2021:

- Added parameter debugging stream

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.IP/Help/en-US/Get-Subnet.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.IP/Help/en-US/Get-Subnet.md)

[https://github.com/indented-automation/Indented.Net.IP](https://github.com/indented-automation/Indented.Net.IP)
