---
external help file: Ruleset.Firewall-help.xml
Module Name: Ruleset.Firewall
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Firewall/Help/en-US/Import-FirewallRules.md
schema: 2.0.0
---

# Import-FirewallRules

## SYNOPSIS

Imports firewall rules from a CSV or JSON file.

## SYNTAX

```powershell
Import-FirewallRules [-PolicyStore <String>] [-Folder <String>] [-FileName <String>] [-JSON]
 [<CommonParameters>]
```

## DESCRIPTION

Imports firewall rules generated with Export-FirewallRules, CSV or JSON file.
CSV files have to be separated with semicolons.
Existing rules with same name will be overwritten.

## EXAMPLES

### EXAMPLE 1

```powershell
Import-FirewallRules
```

Imports all firewall rules in the CSV file FirewallRules.csv
If no file is specified, FirewallRules .csv or .json in the current directory is searched.

### EXAMPLE 2

```powershell
Import-FirewallRules -FileName WmiRules -JSON
```

Imports all firewall rules from the JSON file WmiRules

## PARAMETERS

### -PolicyStore

Policy store into which to import rules, default is local GPO.

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

Path to directory where exported rules file is located

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

Input file

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

Input from JSON instead of CSV format

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

### None. You cannot pipe objects to Import-FirewallRules

## OUTPUTS

### None. Import-FirewallRules does not generate any output

## NOTES

Author: Markus Scholtes
Version: 1.02
Build date: 2020/02/15

Following modifications by metablaster August 2020:
1.
Applied formatting and code style according to project rules
2.
Added parameter to target specific policy store
3.
Separated functions into their own scope
4.
Added function to decode string into multi line
5.
Added parameter to let specify directory
6.
Added more output streams for debug, verbose and info
7.
Changed minor flow and logic of execution
8.
Make output formatted and colored
9.
Added progress bar

## RELATED LINKS
