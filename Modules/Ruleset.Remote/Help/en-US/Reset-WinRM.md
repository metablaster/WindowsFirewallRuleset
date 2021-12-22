---
external help file: Ruleset.Remote-help.xml
Module Name: Ruleset.Remote
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Reset-WinRM.md
schema: 2.0.0
---

# Reset-WinRM

## SYNOPSIS

Reset WinRM and PS remoting configuration

## SYNTAX

```powershell
Reset-WinRM [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Reset-WinRM resets WinRM configuration to either system defaults or to previous settings
that were exported by Export-WinRM.
In addition PS remoting is disabled or restored and reset to PowerShell defaults, default firewall rules
are removed and WinRM service is stopped and disabled.

## EXAMPLES

### EXAMPLE 1

```powershell
Reset-WinRM
```

## PARAMETERS

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

### None. You cannot pipe objects to Reset-WinRM

## OUTPUTS

### None. Reset-WinRM does not generate any output

## NOTES

HACK: Set-WSManInstance fails in PS Core with "Invalid ResourceURI format" error

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Reset-WinRM.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Reset-WinRM.md)
