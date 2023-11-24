---
external help file: Ruleset.Firewall-help.xml
Module Name: Ruleset.Firewall
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Firewall/Help/en-US/Format-RuleOutput.md
schema: 2.0.0
---

# Format-RuleOutput

## SYNOPSIS

Format output of the Net-NewFirewallRule commandlet

## SYNTAX

```powershell
Format-RuleOutput [-Rule] <CimInstance[]> [-Label <String>] [-ForegroundColor <ConsoleColor>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION

Output of Net-NewFirewallRule is large, loading a lot of rules would spam the console
very fast, this function helps to output only relevant, formatted and colored output

## EXAMPLES

### EXAMPLE 1

```powershell
Net-NewFirewallRule ... | Format-RuleOutput
```

### EXAMPLE 2

```powershell
Net-NewFirewallRule ... | Format-RuleOutput -ForegroundColor Red -Label Modify
```

## PARAMETERS

### -Rule

Firewall rule to format, by default output status represents loading rule

```yaml
Type: Microsoft.Management.Infrastructure.CimInstance[]
Parameter Sets: (All)
Aliases: InputObject

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Label

Specify action on how to format rule processing, acceptable values are:
Load, Modify, Import and Export.
The default value is "Load" which represent loading rule into firewall.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Load
Accept pipeline input: False
Accept wildcard characters: False
```

### -ForegroundColor

Optionally specify text color of the output.
For acceptable color values see link section
The default is Cyan.

```yaml
Type: System.ConsoleColor
Parameter Sets: (All)
Aliases:
Accepted values: Black, DarkBlue, DarkGreen, DarkCyan, DarkRed, DarkMagenta, DarkYellow, Gray, DarkGray, Blue, Green, Cyan, Red, Magenta, Yellow, White

Required: False
Position: Named
Default value: Cyan
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

### [Microsoft.Management.Infrastructure.CimInstance[]]

## OUTPUTS

### [string] colored version

## NOTES

TODO: For force loaded rules it should say: "Force Load Rule:"
TODO: Implementation needed to format rules which are not CimInstance see,
Remove-FirewallRule and Export-RegistryRule

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Firewall/Help/en-US/Format-RuleOutput.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Firewall/Help/en-US/Format-RuleOutput.md)

[https://learn.microsoft.com/en-us/dotnet/api/system.consolecolor](https://learn.microsoft.com/en-us/dotnet/api/system.consolecolor)
