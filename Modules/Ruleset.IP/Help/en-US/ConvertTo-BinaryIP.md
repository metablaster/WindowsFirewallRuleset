---
external help file: Ruleset.IP-help.xml
Module Name: Ruleset.IP
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.IP/Help/en-US/ConvertTo-BinaryIP.md
schema: 2.0.0
---

# ConvertTo-BinaryIP

## SYNOPSIS

Converts a Decimal IP address into a binary format

## SYNTAX

```powershell
ConvertTo-BinaryIP [-IPAddress] <IPAddress> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION

ConvertTo-BinaryIP uses System.Convert to switch between decimal and binary format.
The output from this function is dotted binary.

## EXAMPLES

### EXAMPLE 1

```powershell
ConvertTo-BinaryIP 1.2.3.4
```

Convert an IP address to a binary format.

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

### [IPAddress] Decimal IP address

## OUTPUTS

### [string] Dotted binary IP address

## NOTES

Modifications by metablaster year 2019, 2020:

- Include licenses and move comment based help outside of functions
- For code to be consistent with project code formatting and symbol casing.
- Removed unnecessary position arguments, added default argument values explicitly.

January 2021:

- Added parameter debugging stream

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.IP/Help/en-US/ConvertTo-BinaryIP.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.IP/Help/en-US/ConvertTo-BinaryIP.md)

[https://github.com/indented-automation/Indented.Net.IP](https://github.com/indented-automation/Indented.Net.IP)
