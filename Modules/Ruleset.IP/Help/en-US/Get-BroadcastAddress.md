---
external help file: Ruleset.IP-help.xml
Module Name: Ruleset.IP
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.IP/Help/en-US/Get-BroadcastAddress.md
schema: 2.0.0
---

# Get-BroadcastAddress

## SYNOPSIS

Get the broadcast address for a network range

## SYNTAX

```powershell
Get-BroadcastAddress [-IPAddress] <String> [[-SubnetMask] <String>] [<CommonParameters>]
```

## DESCRIPTION

Get-BroadcastAddress returns the broadcast address for a subnet by performing a bitwise AND
operation against the decimal forms of the IP address and inverted subnet mask.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-BroadcastAddress 192.168.0.243 255.255.255.0
```

Returns the address 192.168.0.255.

### EXAMPLE 2

```powershell
Get-BroadcastAddress 10.0.9/22
```

Returns the address 10.0.11.255.

### EXAMPLE 3

```powershell
Get-BroadcastAddress 0/0
```

Returns the address 255.255.255.255.

### EXAMPLE 4

```powershell
Get-BroadcastAddress "10.0.0.42 255.255.255.252"
```

Input values are automatically split into IP address and subnet mask.
Returns the address 10.0.0.43.

## PARAMETERS

### -IPAddress

Either a literal IP address, a network range expressed as CIDR notation,
or an IP address and subnet mask in a string.

```yaml
Type: System.String
Parameter Sets: (All)
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
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [string]

## OUTPUTS

### [IPAddress] The broadcast address

## NOTES

Modifications by metablaster year 2019, 2020:

- Include licenses and move comment based help outside of functions
- For code to be consistent with project code formatting and symbol casing.
- Removed unnecessary position arguments, added default argument values explicitly.

January 2021:

- Added parameter debugging stream

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.IP/Help/en-US/Get-BroadcastAddress.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.IP/Help/en-US/Get-BroadcastAddress.md)

[https://github.com/indented-automation/Indented.Net.IP](https://github.com/indented-automation/Indented.Net.IP)
