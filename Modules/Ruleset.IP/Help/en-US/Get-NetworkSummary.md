---
external help file: Ruleset.IP-help.xml
Module Name: Ruleset.IP
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.IP/Help/en-US/Get-NetworkSummary.md
schema: 2.0.0
---

# Get-NetworkSummary

## SYNOPSIS

Generates a summary describing several properties of a network range

## SYNTAX

```powershell
Get-NetworkSummary [-IPAddress] <String> [[-SubnetMask] <String>] [<CommonParameters>]
```

## DESCRIPTION

Get-NetworkSummary uses many of the IP conversion commands to provide a summary of a
network range from any IP address in the range and a subnet mask.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-NetworkSummary 192.168.0.1 255.255.255.0
```

### EXAMPLE 2

```powershell
Get-NetworkSummary 10.0.9.43/22
```

### EXAMPLE 3

```powershell
Get-NetworkSummary 0/0
```

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

### "Ruleset.IP.NetworkSummary" [PSCustomObject]

## NOTES

Modifications by metablaster year 2019, 2020:

- Include licenses and move comment based help outside of functions
- For code to be consistent with project code formatting and symbol casing.
- Removed unnecessary position arguments, added default argument values explicitly.

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.IP/Help/en-US/Get-NetworkSummary.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.IP/Help/en-US/Get-NetworkSummary.md)

[https://github.com/indented-automation/Indented.Net.IP](https://github.com/indented-automation/Indented.Net.IP)
