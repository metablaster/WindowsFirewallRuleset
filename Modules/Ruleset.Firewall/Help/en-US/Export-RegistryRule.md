---
external help file: Ruleset.Firewall-help.xml
Module Name: Ruleset.Firewall
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Firewall/Help/en-US/Export-RegistryRule.md
schema: 2.0.0
---

# Export-RegistryRule

## SYNOPSIS

Exports firewall rules to a CSV or JSON file from registry

## SYNTAX

```powershell
Export-RegistryRule [-Domain <String>] -Path <DirectoryInfo> [-FileName <String>] [-DisplayName <String>]
 [-DisplayGroup <String>] [-JSON] [-Inbound] [-Outbound] [-Enabled] [-Disabled] [-Allow] [-Block] [-Append]
 [-Force] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION

Export-RegistryRule exports firewall rules to a CSV or JSON file directly from registry.
Only local GPO rules are exported by default.
CSV files are semicolon separated.
All rules are exported by default, you can filter with parameter -Name, -Inbound, -Outbound,
-Enabled, -Disabled, -Allow and -Block.
If the export file already exists it's content will be replaced by default.

## EXAMPLES

### EXAMPLE 1

```powershell
Export-RegistryRule
```

Exports all firewall rules to the CSV file FirewallRules.csv in the current directory.

### EXAMPLE 2

```powershell
Export-RegistryRule -Inbound -Allow
```

Exports all inbound and allowing firewall rules to the CSV file FirewallRules.csv in the current directory.

### EXAMPLE 3

```powershell
Export-RegistryRule -DisplayGroup ICMP* ICMPRules.json -JSON
```

Exports all ICMP firewall rules to the JSON file ICMPRules.json.

## PARAMETERS

### -Domain

Computer name from which rules are to be exported

```yaml
Type: System.String
Parameter Sets: (All)
Aliases: ComputerName, CN

Required: False
Position: Named
Default value: [System.Environment]::MachineName
Accept pipeline input: False
Accept wildcard characters: False
```

### -Path

Directory location into which to save file.
Wildcard characters are supported.

```yaml
Type: System.IO.DirectoryInfo
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: True
```

### -FileName

Output file, default is CSV format

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: FirewallRules
Accept pipeline input: False
Accept wildcard characters: False
```

### -DisplayName

Display name of the rules to be processed.
Wildcard character * is allowed.
DisplayName is case sensitive.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: *
Accept pipeline input: False
Accept wildcard characters: False
```

### -DisplayGroup

Display group of the rules to be processed.
Wildcard character * is allowed.
DisplayGroup is case sensitive.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: *
Accept pipeline input: False
Accept wildcard characters: False
```

### -JSON

Output in JSON instead of CSV format

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

### -Inbound

Export inbound rules

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

### -Outbound

Export outbound rules

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

### -Enabled

Export enabled rules

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

### -Disabled

Export disabled rules

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

### -Allow

Export allowing rules

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

### -Block

Export blocking rules

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

### -Append

Append exported rules to existing file.
By default file of same name is replaced with new content

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

### None. You cannot pipe objects to Export-RegistryRule

## OUTPUTS

### None. Export-RegistryRule does not generate any output

## NOTES

TODO: Export to excel
Excel is not friendly to CSV files
TODO: In one case no export file was made (with Backup-Firewall.ps1), rerunning again worked.
TODO: We should probably handle duplicate rule name entires, ex.
replace or error,
because if file with duplicates is imported it will cause removal of duplicate rules.
TODO: Export CP firewall
NOTE: Exporting to REG makes no sense because reg file can't be simply imported or executed

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Firewall/Help/en-US/Export-RegistryRule.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Firewall/Help/en-US/Export-RegistryRule.md)

[https://github.com/MScholtes/Firewall-Manager](https://github.com/MScholtes/Firewall-Manager)
