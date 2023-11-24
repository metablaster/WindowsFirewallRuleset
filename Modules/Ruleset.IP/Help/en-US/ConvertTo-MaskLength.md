---
external help file: Ruleset.IP-help.xml
Module Name: Ruleset.IP
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.IP/Help/en-US/ConvertTo-MaskLength.md
schema: 2.0.0
---

# ConvertTo-MaskLength

## SYNOPSIS

Convert a dotted-decimal subnet mask to a mask length

## SYNTAX

```powershell
ConvertTo-MaskLength [-SubnetMask] <IPAddress> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION

A count of the number of 1's in a binary string.

## EXAMPLES

### EXAMPLE 1

```powershell
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

### [IPAddress] A dotted-decimal subnet mask

## OUTPUTS

### [string] Subnet mask length

## NOTES

Modifications by metablaster year 2019, 2020:

- Include licenses and move comment based help outside of functions
- For code to be consistent with project code formatting and symbol casing.
- Removed unnecessary position arguments, added default argument values explicitly.

January 2021:

- Added parameter debugging stream

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.IP/Help/en-US/ConvertTo-MaskLength.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.IP/Help/en-US/ConvertTo-MaskLength.md)

[https://github.com/indented-automation/Indented.Net.IP](https://github.com/indented-automation/Indented.Net.IP)
