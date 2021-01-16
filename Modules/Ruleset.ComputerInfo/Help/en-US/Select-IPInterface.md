---
external help file: Ruleset.ComputerInfo-help.xml
Module Name: Ruleset.ComputerInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ComputerInfo/Help/en-US/Select-IPInterface.md
schema: 2.0.0
---

# Select-IPInterface

## SYNOPSIS

Select IP configuration for specified network adapters

## SYNTAX

### None (Default)

```powershell
Select-IPInterface [-AddressFamily <String>] [-Hidden] [-Connected] [-CompartmentId <Int32>] [-Detailed]
 [<CommonParameters>]
```

### Physical

```powershell
Select-IPInterface [-AddressFamily <String>] [-Physical] [-Hidden] [-Connected] [-CompartmentId <Int32>]
 [-Detailed] [<CommonParameters>]
```

### Virtual

```powershell
Select-IPInterface [-AddressFamily <String>] [-Virtual] [-Hidden] [-Connected] [-CompartmentId <Int32>]
 [-Detailed] [<CommonParameters>]
```

## DESCRIPTION

Get a list of network adapter IP configuration for specified adapters.
Conditionally select virtual, hidden or connected adapters.
This may include adapters on all or specific compartments.

## EXAMPLES

### EXAMPLE 1

```powershell
Select-IPInterface -AddressFamily IPv4 -Connected -Detailed
```

### EXAMPLE 2

```powershell
Select-IPInterface -AddressFamily IPv6 -Virtual
```

## PARAMETERS

### -AddressFamily

Obtain interfaces configured for specific IP version

```yaml
Type: System.String
Parameter Sets: (All)
Aliases: IPVersion

Required: False
Position: Named
Default value: Any
Accept pipeline input: False
Accept wildcard characters: False
```

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

### -Connected

If specified, only interfaces connected to network are returned

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

### -CompartmentId

Specifies an identifier for network compartment in the protocol stack.
By default, the function gets Net IP configuration in all compartments.

```yaml
Type: System.Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -Detailed

Indicates that the function retrieves additional interface and computer configuration information,
including the computer name, link layer address, network profile, MTU length, and DHCP status.

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

### None. You cannot pipe objects to Select-IPInterface

## OUTPUTS

### "NetIPConfiguration" [PSCustomObject] or error message if no adapter configured

## NOTES

None.

## RELATED LINKS
