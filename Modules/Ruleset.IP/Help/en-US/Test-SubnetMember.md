---
external help file: Ruleset.IP-help.xml
Module Name: Ruleset.IP
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.IP/Help/en-US/Test-SubnetMember.md
schema: 2.0.0
---

# Test-SubnetMember

## SYNOPSIS

Tests an IP address to determine if it falls within IP address range

## SYNTAX

```powershell
Test-SubnetMember [-SubjectIPAddress] <String> [-ObjectIPAddress] <String> [-SubjectSubnetMask <String>]
 [-ObjectSubnetMask <String>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION

Test-SubnetMember attempts to determine whether or not an address or range falls within another range.
The network and broadcast address are calculated the converted to decimal then
compared to the decimal form of the submitted address.

## EXAMPLES

### EXAMPLE 1

```powershell
Test-SubnetMember -SubjectIPAddress 10.0.0.0/24 -ObjectIPAddress 10.0.0.0/16
```

Returns true as the subject network can be contained within the object network.

### EXAMPLE 2

```powershell
Test-SubnetMember -SubjectIPAddress 192.168.0.0/16 -ObjectIPAddress 192.168.0.0/24
```

Returns false as the subject network is larger the object network.

### EXAMPLE 3

```powershell
Test-SubnetMember -SubjectIPAddress 10.2.3.4/32 -ObjectIPAddress 10.0.0.0/8
```

Returns true as the subject IP address is within the object network.

### EXAMPLE 4

```powershell
Test-SubnetMember -SubjectIPAddress 255.255.255.255 -ObjectIPAddress 0/0
```

Returns true as the subject IP address is the last in the object network range.

## PARAMETERS

### -SubjectIPAddress

A representation of the subject, the network to be tested.
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

### -ObjectIPAddress

A representation of the object, the network to test against.
Either a literal IP address,
a network range expressed as CIDR notation, or an IP address and subnet mask in a string.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SubjectSubnetMask

A subnet mask as an IP address.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ObjectSubnetMask

A subnet mask as an IP address.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProgressAction

{{ Fill ProgressAction Description }}

```yaml
Type: System.Management.Automation.ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You cannot pipe objects to Test-SubnetMember

## OUTPUTS

### [bool]

## NOTES

Modifications by metablaster year 2019, 2020:

- Include licenses and move comment based help outside of functions
- For code to be consistent with project code formatting and symbol casing.
- Removed unnecessary position arguments, added default argument values explicitly.

January 2021:

- Added parameter debugging stream

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.IP/Help/en-US/Test-SubnetMember.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.IP/Help/en-US/Test-SubnetMember.md)

[https://github.com/indented-automation/Indented.Net.IP](https://github.com/indented-automation/Indented.Net.IP)
