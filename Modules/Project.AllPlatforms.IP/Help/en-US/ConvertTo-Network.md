---
external help file: Project.AllPlatforms.IP-help.xml
Module Name: Project.AllPlatforms.IP
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/develop/Modules/Project.AllPlatforms.IP/Help/en-US/ConvertTo-Network.md
schema: 2.0.0
---

# ConvertTo-Network

## SYNOPSIS

Converts IP address formats to a set a known styles.

## SYNTAX

```none
ConvertTo-Network [-IPAddress] <String> [[-SubnetMask] <String>] [<CommonParameters>]
```

## DESCRIPTION

ConvertTo-Network ensures consistent values are recorded from parameters which must handle differing addressing formats.
This Cmdlet allows all other the other functions in this module to offload parameter handling.

## EXAMPLES

### Example 1

```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

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
Accept pipeline input: False
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

### None. You cannot pipe objects to ConvertTo-Network

## OUTPUTS

### TODO: describe outputs

## NOTES

Change log:
	05/03/2016 - Chris Dent - Refactored and simplified.
	14/01/2014 - Chris Dent - Created.
Following changes by metablaster:
- Include licenses and move comment based help outside of functions
- For code to be consistent with project code formatting and symbol casing.
- Rename function to approved verb
- Removed unnecessary position arguments, added default argument values explicitly.

## RELATED LINKS

