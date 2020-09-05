---
external help file: Project.Windows.Firewall-help.xml
Module Name: Project.Windows.Firewall
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/develop/Modules/Project.Windows.Firewall/Help/en-US/Export-FirewallRules.md
schema: 2.0.0
---

# Export-FirewallRules

## SYNOPSIS

Exports firewall rules to a CSV or JSON file.

## SYNTAX

```none
Export-FirewallRules [[-PolicyStore] <String>] [[-Folder] <String>] [[-FileName] <String>]
 [[-DisplayName] <String>] [[-DisplayGroup] <String>] [-JSON] [-Inbound] [-Outbound] [-Enabled] [-Disabled]
 [-Block] [-Allow] [-Append] [<CommonParameters>]
```

## DESCRIPTION

Exports firewall rules to a CSV or JSON file.
Only local GPO rules are exported by default.
CSV files are semicolon separated (Beware!
Excel is not friendly to CSV files).
All rules are exported by default, you can filter with parameter -Name, -Inbound, -Outbound,
-Enabled, -Disabled, -Allow and -Block.
If the export file already exists it's content will be replaced by default.

## EXAMPLES

### EXAMPLE 1

```none
Export-FirewallRules
Exports all firewall rules to the CSV file FirewallRules.csv in the current directory.
```

### EXAMPLE 2

```none
Export-FirewallRules -Inbound -Allow
Exports all inbound and allowing firewall rules to the CSV file FirewallRules.csv in the current directory.
```

### EXAMPLE 3

```none
Export-FirewallRules snmp* SNMPRules.json -json
Exports all SNMP firewall rules to the JSON file SNMPRules.json.
```

## PARAMETERS

### -PolicyStore

Policy store from which to export rules, default is local GPO.
For more information about stores see:
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Readme/FirewallParameters.md

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: [System.Environment]::MachineName
Accept pipeline input: False
Accept wildcard characters: False
```

### -Folder

Path into which to save file

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: .
Accept pipeline input: False
Accept wildcard characters: False
```

### -FileName

Output file, default is JSON format

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: FirewallRules
Accept pipeline input: False
Accept wildcard characters: False
```

### -DisplayName

Display name of the rules to be processed.
Wildcard character * is allowed.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: *
Accept pipeline input: False
Accept wildcard characters: False
```

### -DisplayGroup

Display group of the rules to be processed.
Wildcard character * is allowed.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
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

### -Append

Append exported rules to existing file instead of replacing

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

## OUTPUTS

### System.Void

## NOTES

Author: Markus Scholtes
Version: 1.02
Build date: 2020/02/15

Changes by metablaster - August 2020:
1.
Applied formatting and code style according to project rules
2.
Added switch to optionally append instead of replacing output file
3.
Separated functions into their own scope
4.
Added function to decode string into multi line
5.
Added parameter to target specific policy store
6.
Added parameter to let specify directory, and crate it if it doesn't exist
7.
Added more output streams for debug, verbose and info
8.
Added parameter to export according to rule group
9.
Changed minor flow and logic of execution
10.
Make output formatted and colored
11.
Added progress bar
TODO: export to excel

## RELATED LINKS

