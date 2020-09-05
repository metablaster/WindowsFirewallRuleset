---
external help file: Project.Windows.Firewall-help.xml
Module Name: Project.Windows.Firewall
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/develop/Modules/Project.Windows.Firewall/Help/en-US/Find-RulePrincipal.md
schema: 2.0.0
---

# Find-RulePrincipal

## SYNOPSIS

Get all firewall rules with LocalUser value

## SYNTAX

```none
Find-RulePrincipal [-Empty] [<CommonParameters>]
```

## DESCRIPTION

Get all rules which are either missing or not missing LocalUser value
Rules which are missing LocalUser are considered weak and need to be updated
This operation is slow, intended for debugging.

## EXAMPLES

### EXAMPLE 1

```none
Find-RulePrincipal -Empty
```

## PARAMETERS

### -Empty

If specified returns rules with no local user value
Otherwise only rules with local user are returned

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

### None. You cannot pipe objects to Find-RulePrincipal

## OUTPUTS

### None.

## NOTES

TODO: This needs improvement to export matching rules to JSON

## RELATED LINKS

