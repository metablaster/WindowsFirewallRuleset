---
external help file: Ruleset.Firewall-help.xml
Module Name: Ruleset.Firewall
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Firewall/Help/en-US/Format-Output.md
schema: 2.0.0
---

# Format-Output

## SYNOPSIS

Format firewall rule output for display

## SYNTAX

### None (Default)

```powershell
Format-Output -Rule <CimInstance[]> [<CommonParameters>]
```

### Modify

```powershell
Format-Output -Rule <CimInstance[]> [-Modify] [<CommonParameters>]
```

### Import

```powershell
Format-Output -Rule <CimInstance[]> [-Import] [<CommonParameters>]
```

## DESCRIPTION

Output of Net-NewFirewallRule is large, loading a lot of rules would spam the console
very fast, this function helps to output only relevant, formatted and colored output

## EXAMPLES

### EXAMPLE 1

```powershell
Net-NewFirewallRule ... | Format-Output
```

## PARAMETERS

### -Rule

Firewall rule to format, by default output status represents loading rule

```yaml
Type: Microsoft.Management.Infrastructure.CimInstance[]
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Modify

If specified, output status represents rule modification

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: Modify
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Import

If specified, output status represents importing rule

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: Import
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

### [Microsoft.Management.Infrastructure.CimInstance[]]

## OUTPUTS

### None. Format-Output does not generate any output

## NOTES

None.

## RELATED LINKS
