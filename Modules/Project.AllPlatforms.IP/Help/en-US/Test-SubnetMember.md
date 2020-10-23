---
external help file: Project.AllPlatforms.IP-help.xml
Module Name: Project.AllPlatforms.IP
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/develop/Modules/Project.AllPlatforms.IP/Help/en-US/Test-SubnetMember.md
schema: 2.0.0
---

# Test-SubnetMember

## SYNOPSIS

Tests an IP address to determine if it falls within IP address range.

## SYNTAX

```none
Test-SubnetMember [-SubjectIPAddress] <String> [-ObjectIPAddress] <String> [-SubjectSubnetMask <String>]
 [-ObjectSubnetMask <String>] [<CommonParameters>]
```

## DESCRIPTION

Test-SubnetMember attempts to determine whether or not an address or range falls within another range.
The network and broadcast address are calculated the converted to decimal then
compared to the decimal form of the submitted address.

## EXAMPLES

### EXAMPLE 1

```none
Test-SubnetMember -SubjectIPAddress 10.0.0.0/24 -ObjectIPAddress 10.0.0.0/16
```

Returns true as the subject network can be contained within the object network.

### EXAMPLE 2

```none
Test-SubnetMember -SubjectIPAddress 192.168.0.0/16 -ObjectIPAddress 192.168.0.0/24
```

Returns false as the subject network is larger the object network.

### EXAMPLE 3

```none
Test-SubnetMember -SubjectIPAddress 10.2.3.4/32 -ObjectIPAddress 10.0.0.0/8
```

Returns true as the subject IP address is within the object network.

### EXAMPLE 4

```none
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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You cannot pipe objects to Test-SubnetMember

## OUTPUTS

### TODO: describe outputs

## NOTES

Following changes by metablaster:
- Include licenses and move comment based help outside of functions
- For code to be consistent with project code formatting and symbol casing.
- Removed unnecessary position arguments, added default argument values explicitly.

## RELATED LINKS
