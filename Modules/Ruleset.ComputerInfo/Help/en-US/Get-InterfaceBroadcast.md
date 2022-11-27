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
Get-InterfaceBroadcast [-Physical] [-Virtual] [-Visible] [-Hidden] [<CommonParameters>]
```

### Domain

```powershell
Get-InterfaceBroadcast [-Domain <String>] [-Credential <PSCredential>] [-Physical] [-Virtual] [-Visible]
 [-Hidden] [<CommonParameters>]
```

### Session

```powershell
Get-InterfaceBroadcast [-Session <PSSession>] [-Physical] [-Virtual] [-Visible] [-Hidden] [<CommonParameters>]
```

## DESCRIPTION

Get broadcast addresses for either physical or virtual network interfaces.
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

### -Domain

Computer name which to query

```yaml
Type: System.String
Parameter Sets: Domain
Aliases: ComputerName, CN

Required: False
Position: Named
Default value: [System.Environment]::MachineName
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential

Specifies the credential object to use for authentication

```yaml
Type: System.Management.Automation.PSCredential
Parameter Sets: Domain
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Session

Specifies the PS session to use

```yaml
Type: System.Management.Automation.Runspaces.PSSession
Parameter Sets: Session
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Physical

If specified, include only physical adapters

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

### -Virtual

If specified, include only virtual adapters.
By default only physical adapters are reported

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

### -Visible

If specified, only visible interfaces are included

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
