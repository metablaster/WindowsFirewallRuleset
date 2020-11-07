---
external help file: Ruleset.ComputerInfo-help.xml
Module Name: Ruleset.ComputerInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ComputerInfo/Help/en-US/Get-ConfiguredAdapter.md
schema: 2.0.0
---

# Get-ConfiguredAdapter

## SYNOPSIS

Method to get configured adapters

## SYNTAX

### Individual (Default)

```none
Get-ConfiguredAdapter [[-AddressFamily] <String>] [-ExcludeHardware] [-IncludeVirtual] [-IncludeHidden]
 [-IncludeDisconnected] [<CommonParameters>]
```

### All

```none
Get-ConfiguredAdapter [[-AddressFamily] <String>] [-ExcludeHardware] [-IncludeAll] [<CommonParameters>]
```

## DESCRIPTION

Return list of all configured adapters and their configuration.
Applies to adapters which have an IP assigned regardless if connected to network.
This conditionally includes virtual and hidden adapters such as Hyper-V adapters on all compartments.

## EXAMPLES

### EXAMPLE 1

```none
Get-ConfiguredAdapter "IPv4"
```

### EXAMPLE 2

```none
Get-ConfiguredAdapter "IPv6"
```

## PARAMETERS

### -AddressFamily

IP version for which to obtain adapters, IPv4 or IPv6

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

Exclude hardware/physical network adapters

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

### None. You cannot pipe objects to Get-ConfiguredAdapter

## OUTPUTS

### [System.Net.NetIPConfiguration] or error message if no adapter configured

## NOTES

TODO: Loopback interface is missing in the output

## RELATED LINKS
