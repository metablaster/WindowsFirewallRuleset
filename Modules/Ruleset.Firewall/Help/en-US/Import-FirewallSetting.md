---
external help file: Ruleset.Firewall-help.xml
Module Name: Ruleset.Firewall
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Firewall/Help/en-US/Import-FirewallSetting.md
schema: 2.0.0
---

# Import-FirewallSetting

## SYNOPSIS

Import firewall settings and profile setup to file

## SYNTAX

```powershell
Import-FirewallSetting [-Path] <DirectoryInfo> [[-FileName] <String>] [<CommonParameters>]
```

## DESCRIPTION

Import-FirewallSetting imports all firewall settings from file previously exported by
Export-FirewallSetting

## EXAMPLES

### EXAMPLE 1

```powershell
Import-FirewallSetting
```

## PARAMETERS

### -Path

Path to directory where the exported settings file is located.
Wildcard characters are supported.

```yaml
Type: System.IO.DirectoryInfo
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: True
```

### -FileName

Input file

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: FirewallSettings
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You cannot pipe objects to Import-FirewallSetting

## OUTPUTS

### None. Import-FirewallSetting does not generate any output

## NOTES

None.

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Firewall/Help/en-US/Import-FirewallSetting.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Firewall/Help/en-US/Import-FirewallSetting.md)
