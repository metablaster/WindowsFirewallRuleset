---
external help file: Ruleset.Firewall-help.xml
Module Name: Ruleset.Firewall
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Firewall/Help/en-US/Export-FirewallSetting.md
schema: 2.0.0
---

# Export-FirewallSetting

## SYNOPSIS

Export firewall settings and profile setup to file

## SYNTAX

```powershell
Export-FirewallSetting [[-Domain] <String>] [-Path] <DirectoryInfo> [[-FileName] <String>] [-Force]
 [<CommonParameters>]
```

## DESCRIPTION

Export-FirewallSetting exports all firewall settings to file excluding firewall rules

## EXAMPLES

### EXAMPLE 1

```powershell
Export-FirewallSetting
```

### EXAMPLE 2

```powershell
Export-FirewallSetting -Path "C:\DirectoryName\filename.json" -Force
```

## PARAMETERS

### -Domain

Computer name from which firewall settings are to be exported

```yaml
Type: System.String
Parameter Sets: (All)
Aliases: ComputerName, CN

Required: False
Position: 1
Default value: [System.Environment]::MachineName
Accept pipeline input: False
Accept wildcard characters: False
```

### -Path

Path into which to save file.
Wildcard characters are supported.

```yaml
Type: System.IO.DirectoryInfo
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: True
```

### -FileName

Output file name, json format

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: FirewallSettings.json
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force

If specified does not prompt to replace existing file.

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

### None. You cannot pipe objects to Export-FirewallSetting

## OUTPUTS

### None. Export-FirewallSetting does not generate any output

## NOTES

None.

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Firewall/Help/en-US/Export-FirewallSetting.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Firewall/Help/en-US/Export-FirewallSetting.md)
