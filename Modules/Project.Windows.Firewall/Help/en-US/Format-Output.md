---
external help file: Project.Windows.Firewall-help.xml
Module Name: Project.Windows.Firewall
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/develop/Modules/Project.Windows.Firewall/Help/en-US/Format-Output.md
schema: 2.0.0
---

# Format-Output

## SYNOPSIS

Format firewall rule output for display

## SYNTAX

```none
Format-Output [-Rule] <CimInstance> [[-Label] <String>] [<CommonParameters>]
```

## DESCRIPTION

Output of Net-NewFirewallRule is large, loading a lot of rules would spam the console
very fast, this function helps to output only relevant content.

## EXAMPLES

### EXAMPLE 1

```none
Net-NewFirewallRule ... | Format-Output
```

## PARAMETERS

### -Rule

Firewall rule to format

```yaml
Type: Microsoft.Management.Infrastructure.CimInstance
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Label

Optional new label to replace default one

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: Load Rule
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### Microsoft.Management.Infrastructure.CimInstance Firewall rule to format

## OUTPUTS

### None. Formatted and colored output

## NOTES

None.

## RELATED LINKS

