---
external help file: Ruleset.ComputerInfo-help.xml
Module Name: Ruleset.ComputerInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ComputerInfo/Help/en-US/Get-InterfaceAlias.md
schema: 2.0.0
---

# Get-InterfaceAlias

## SYNOPSIS

Retrieve a aliases of configured network adapters

## SYNTAX

### Individual (Default)

```powershell
Get-InterfaceAlias [[-AddressFamily] <String>] [-WildCardOption <WildcardOptions>] [-ExcludeHardware]
 [-IncludeVirtual] [-IncludeHidden] [-IncludeDisconnected] [<CommonParameters>]
```

### All

```powershell
Get-InterfaceAlias [[-AddressFamily] <String>] [-WildCardOption <WildcardOptions>] [-ExcludeHardware]
 [-IncludeAll] [<CommonParameters>]
```

## DESCRIPTION

Return list of interface aliases of all configured adapters.
Applies to adapters which have an IP assigned regardless if connected to network.
This may include virtual adapters as well such as Hyper-V adapters on all compartments.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-InterfaceAlias "IPv4"
```

### EXAMPLE 2

```powershell
Get-InterfaceAlias "IPv6"
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

### -WildCardOption

TODO: describe parameter

```yaml
Type: System.Management.Automation.WildcardOptions
Parameter Sets: (All)
Aliases:
Accepted values: None, Compiled, IgnoreCase, CultureInvariant

Required: False
Position: Named
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

### None. You cannot pipe objects to Get-InterfaceAlias

## OUTPUTS

### [System.Management.Automation.WildcardPattern]

## NOTES

None.
TODO: There is another function with the same name in Scripts folder
TODO: shorter parameter names: Virtual, All, Hidden, Hardware

## RELATED LINKS
