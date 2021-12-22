---
external help file: Ruleset.Remote-help.xml
Module Name: Ruleset.Remote
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Show-WinRMConfig.md
schema: 2.0.0
---

# Show-WinRMConfig

## SYNOPSIS

Show WinRM service configuration

## SYNTAX

```powershell
Show-WinRMConfig [-Server] [-Client] [-Detailed] [<CommonParameters>]
```

## DESCRIPTION

Various commands such as "winrm get winrm/config" will show all the data but will also include
containers, WSMan provider is also not universal, and you need to run different commands to get
desired results or values from sub containers.

Some of the WinRM options are advanced and not easily discoverable or often used, as such these
can cause isssues hard to debug due to WinRM service misconfiguration.

This scripts does all this, by harvesting all important and relevant information and
excludes\includes containers by specifying few switches, all of which is then sorted so that it
can be compared with other working configurations to quickly discover problems.

## EXAMPLES

### EXAMPLE 1

```powershell
Show-WinRMConfig
```

Without any switches it will show only status of the WinRM service and status of firewall rules

### EXAMPLE 2

```powershell
Show-WinRMConfig -Server -Detailed
```

### EXAMPLE 3

```powershell
Show-WinRMConfig -Client
```

## PARAMETERS

### -Server

Display WinRM server configuration.
This includes configuration that is essential to accept remote commands.

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

### -Client

Display WinRM client configuration.
This includes configuration that is essential to send remote commands.

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

### -Detailed

Display additional WinRM configuration not handled by -Server and -Client switches.

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

### None. You cannot pipe objects to Show-WinRMConfig

## OUTPUTS

### [System.Xml.XmlElement]

### [Selected.System.Xml.XmlElement]

### [Microsoft.WSMan.Management.WSManConfigLeafElement]

## NOTES

None.

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Show-WinRMConfig.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Show-WinRMConfig.md)

[https://docs.microsoft.com/en-us/powershell/module/microsoft.wsman.management](https://docs.microsoft.com/en-us/powershell/module/microsoft.wsman.management)

[winrm get winrm/config]()
