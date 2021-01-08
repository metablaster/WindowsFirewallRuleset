---
external help file: Ruleset.ComputerInfo-help.xml
Module Name: Ruleset.ComputerInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ComputerInfo/Help/en-US/Resolve-Host.md
schema: 2.0.0
---

# Resolve-Host

## SYNOPSIS

Resolve host or IP

## SYNTAX

### Physical (Default)

```powershell
Resolve-Host [-AddressFamily <String>] [-Physical] [-Hidden] [-Connected] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### Host

```powershell
Resolve-Host -Domain <String[]> [-FlushDNS] [-AddressFamily <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### IP

```powershell
Resolve-Host -IPAddress <IPAddress[]> [-FlushDNS] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Virtual

```powershell
Resolve-Host [-AddressFamily <String>] [-Virtual] [-Hidden] [-Connected] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION

Resolve host to IP or an IP to host.
For localhost select virtual, hidden or connected adapters.

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
Resolve-Host -LocalHost -AddressFamily IPv4 -Connected
```

## PARAMETERS

### -Domain

Target host name which to resolve to an IP address.

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

Target IP which to resolve to host name.

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

Obtain IP address specified IP version

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

Resolve local host name to an IP of a physical adapter

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

Resolve local host name to an IP of a virtual adapter

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
Parameter Sets: Physical, Virtual
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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [IPAddress[]]

### [string[]]

## OUTPUTS

### [PSCustomObject]

## NOTES

TODO: Single IP is selected for result, maybe we should return all IP addresses

## RELATED LINKS
