---
external help file: Project.Windows.ComputerInfo-help.xml
Module Name: Project.Windows.ComputerInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/develop/Modules/Project.Windows.ComputerInfo/Help/en-US/Get-Broadcast.md
schema: 2.0.0
---

# Get-Broadcast

## SYNOPSIS

Method to get broadcast addresses on local machine

## SYNTAX

### Individual (Default)

```none
Get-Broadcast [-ExcludeHardware] [-IncludeVirtual] [-IncludeHidden] [-IncludeDisconnected] [<CommonParameters>]
```

### All

```none
Get-Broadcast [-IncludeAll] [-ExcludeHardware] [<CommonParameters>]
```

## DESCRIPTION

Return multiple broadcast addresses, for each configured adapter.
This includes both physical and virtual adapters.
Returned broadcast addresses are only for IPv4

## EXAMPLES

### EXAMPLE 1

```none
Get-Broadcast
```

## PARAMETERS

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

### None. You cannot pipe objects to Get-Broadcast

## OUTPUTS

### [IPAddress[]] Array of broadcast addresses

## NOTES

## RELATED LINKS

