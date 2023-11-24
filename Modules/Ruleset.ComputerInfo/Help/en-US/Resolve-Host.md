---
external help file: Ruleset.ComputerInfo-help.xml
Module Name: Ruleset.ComputerInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ComputerInfo/Help/en-US/Resolve-Host.md
schema: 2.0.0
---

# Resolve-Host

## SYNOPSIS

Resolve host to IP or IP to host

## SYNTAX

### Physical (Default)

```powershell
Resolve-Host [-AddressFamily <String>] [-Physical] [-Connected] [-ProgressAction <ActionPreference>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

### Host

```powershell
Resolve-Host -Domain <String[]> [-FlushDNS] [-AddressFamily <String>] [-ProgressAction <ActionPreference>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

### IP

```powershell
Resolve-Host -IPAddress <IPAddress[]> [-FlushDNS] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### Virtual

```powershell
Resolve-Host [-AddressFamily <String>] [-Virtual] [-Connected] [-ProgressAction <ActionPreference>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Resolve host name to IP address or IP address to host name.
For localhost process virtual or hidden, connected or disconnected adapter address.
By default only physical adapters are processed

## EXAMPLES

### EXAMPLE 1

```powershell
Resolve-Host -AddressFamily IPv4 -IPAddress "40.112.72.205"
```

### EXAMPLE 2

```powershell
Resolve-Host -FlushDNS -Domain "microsoft.com"
```

### EXAMPLE 3

```powershell
Resolve-Host -AddressFamily IPv4 -Connected
```

## PARAMETERS

### -Domain

Target host name which to resolve to IP address

```yaml
Type: System.String[]
Parameter Sets: Host
Aliases: ComputerName, CN

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -IPAddress

Target IP which to resolve to host name

```yaml
Type: System.Net.IPAddress[]
Parameter Sets: IP
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -FlushDNS

Flush DNS resolver cache before resolving IP or host name

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: Host, IP
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -AddressFamily

Obtain IP address for the specified IP version

```yaml
Type: System.String
Parameter Sets: Physical, Host, Virtual
Aliases: IPVersion

Required: False
Position: Named
Default value: Any
Accept pipeline input: False
Accept wildcard characters: False
```

### -Physical

Resolve local host name to IP of any physical adapter

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

Resolve local host name to IP of any virtual adapter

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

### -Connected

If specified, only interfaces connected to network are considered

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: Physical, Virtual
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf

Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm

Prompts you for confirmation before running the cmdlet.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
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

### [IPAddress[]]

### [string[]]

## OUTPUTS

### [PSCustomObject]

## NOTES

TODO: Single IP is selected for result, maybe we should return all IP addresses
TODO: AddressFamily could be 2 switches, -IPv4 and IPv6

## RELATED LINKS
