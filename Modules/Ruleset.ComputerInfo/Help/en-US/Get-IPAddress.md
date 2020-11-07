---
external help file: Ruleset.ComputerInfo-help.xml
Module Name: Ruleset.ComputerInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ComputerInfo/Help/en-US/Get-IPAddress.md
schema: 2.0.0
---

# Get-IPAddress

## SYNOPSIS

Method to get list of IP addresses on local machine

## SYNTAX

### Individual (Default)

```none
Get-IPAddress [[-AddressFamily] <String>] [-ExcludeHardware] [-IncludeVirtual] [-IncludeHidden]
 [-IncludeDisconnected] [<CommonParameters>]
```

### All

```none
Get-IPAddress [[-AddressFamily] <String>] [-ExcludeHardware] [-IncludeAll] [<CommonParameters>]
```

## DESCRIPTION

Returns list of IPAddress objects for all configured adapters.
This could include both physical and virtual adapters.

## EXAMPLES

### EXAMPLE 1

```none
Get-IPAddress "IPv4"
```

### EXAMPLE 2

```none
Get-IPAddress "IPv6"
```

## PARAMETERS

### -AddressFamily

IP version for which to obtain address, IPv4 or IPv6

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExcludeHardware

{{ Fill ExcludeHardware Description }}

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeAll

Include all possible adapter types present on target computer

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: All
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeVirtual

Whether to include virtual adapters

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: Individual
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeHidden

Whether to include hidden adapters

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: Individual
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeDisconnected

Whether to include disconnected

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: Individual
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You cannot pipe objects to Get-IPAddress

## OUTPUTS

### [IPAddress[]] Array of IP addresses and warning message if no adapter connected

## NOTES

None.

## RELATED LINKS
