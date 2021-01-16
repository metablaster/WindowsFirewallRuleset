---
external help file: Ruleset.ComputerInfo-help.xml
Module Name: Ruleset.ComputerInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ComputerInfo/Help/en-US/Get-InterfaceBroadcast.md
schema: 2.0.0
---

# Get-InterfaceBroadcast

## SYNOPSIS

Get interface broadcast address

## SYNTAX

### None (Default)

```powershell
Get-InterfaceBroadcast [-Hidden] [<CommonParameters>]
```

### Physical

```powershell
Get-InterfaceBroadcast [-Physical] [-Hidden] [<CommonParameters>]
```

### Virtual

```powershell
Get-InterfaceBroadcast [-Virtual] [-Hidden] [<CommonParameters>]
```

## DESCRIPTION

Get broadcast addresses, for specified network interfaces.
Returned broadcast addresses are IPv4 and only for adapters connected to network.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-InterfaceBroadcast -Physical
```

### EXAMPLE 2

```powershell
Get-InterfaceBroadcast -Virtual -Hidden
```

## PARAMETERS

### -Physical

If specified, include only physical adapters

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: Physical
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Virtual

If specified, include only virtual adapters

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: Virtual
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Hidden

If specified, only hidden interfaces are included

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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You cannot pipe objects to Get-InterfaceBroadcast

## OUTPUTS

### [string] Broadcast addresses

## NOTES

None.

## RELATED LINKS
