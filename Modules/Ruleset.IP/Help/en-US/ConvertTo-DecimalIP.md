---
external help file: Ruleset.IP-help.xml
Module Name: Ruleset.IP
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.IP/Help/en-US/ConvertTo-DecimalIP.md
schema: 2.0.0
---

# ConvertTo-DecimalIP

## SYNOPSIS

Converts a Decimal IP address into a 32-bit unsigned integer

## SYNTAX

```powershell
ConvertTo-DecimalIP [-IPAddress] <IPAddress> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION

ConvertTo-DecimalIP takes a decimal IP,
uses a shift operation on each octet and returns a single UInt32 value.

## EXAMPLES

### EXAMPLE 1

```powershell
ConvertTo-DecimalIP 1.2.3.4
```

Converts an IP address to an unsigned 32-bit integer value.

## PARAMETERS

### -IPAddress

An IP Address to convert.

```yaml
Type: System.Net.IPAddress
Parameter Sets: (All)
Aliases:

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

### [IPAddress] A decimal IP address

## OUTPUTS

### [uint32] 32-bit unsigned integer value

## NOTES

Modifications by metablaster year 2019, 2020:

- Include licenses and move comment based help outside of functions
- For code to be consistent with project code formatting and symbol casing.
- Removed unnecessary position arguments, added default argument values explicitly.

January 2021:

- Added parameter debugging stream

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.IP/Help/en-US/ConvertTo-DecimalIP.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.IP/Help/en-US/ConvertTo-DecimalIP.md)

[https://github.com/indented-automation/Indented.Net.IP](https://github.com/indented-automation/Indented.Net.IP)
