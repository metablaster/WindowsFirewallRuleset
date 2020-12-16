---
external help file: Ruleset.Firewall-help.xml
Module Name: Ruleset.Firewall
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Firewall/Help/en-US/Remove-FirewallRules.md
schema: 2.0.0
---

# Remove-FirewallRules

## SYNOPSIS

Removes firewall rules according to a list in a CSV or JSON file.

## SYNTAX

```powershell
Remove-FirewallRules [-PolicyStore <String>] [-Folder <String>] [-FileName <String>] [-JSON] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Removes firewall rules according to a with Export-FirewallRules generated list in a CSV or JSON file.
CSV files have to be separated with semicolons.
Only the field Name or - if Name is missing - DisplayName
is used, all other fields can be omitted

## EXAMPLES

### EXAMPLE 1

```powershell
Remove-FirewallRules
```

Removes all firewall rules according to a list in the CSV file FirewallRules.csv in the current directory.

### EXAMPLE 2

```powershell
Remove-FirewallRules WmiRules.json -JSON
```

Removes all firewall rules according to the list in the JSON file WmiRules.json.

## PARAMETERS

### -PolicyStore

Policy store from which remove rules, default is local GPO.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: [System.Environment]::MachineName
Accept pipeline input: False
Accept wildcard characters: False
```

### -Folder

Folder in which file is located

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: .
Accept pipeline input: False
Accept wildcard characters: False
```

### -FileName

File name according to which to delete rules

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

### -JSON

Input file in JSON instead of CSV format

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

### None. You cannot pipe objects to Remove-FirewallRules

## OUTPUTS

### None. Remove-FirewallRules does not generate any output

## NOTES

Author: Markus Scholtes
Version: 1.02
Build date: 2020/02/15

Changes by metablaster - August 2020:
1.
Applied formatting and code style according to project rules
2.
Added parameter to target specific policy store
3.
Added parameter to let specify directory
4.
Added more output streams for debug, verbose and info
5.
Make output formatted and colored
6.
Changed minor flow of execution
TODO: implement removing rules not according to file

## RELATED LINKS
