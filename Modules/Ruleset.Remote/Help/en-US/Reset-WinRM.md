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
Reset-WinRM [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Reset-WinRM resets WinRM configuration to system defaults.
PS remoting is disabled and WinRM service is reset to defaults,
default firewall rules are disabled and WinRM service is stopped and set to manual.

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

### None. You cannot pipe objects to Reset-WinRM

## OUTPUTS

### None. Reset-WinRM does not generate any output

## NOTES

HACK: Set-WSManInstance fails in PS Core with "Invalid ResourceURI format" error
TODO: Need to reset changes done by Enable-RemoteRegistry, separate function is desired
TODO: Restoring old setup not implemented
TODO: Implement -NoServiceRestart parameter if applicable so that only configuration is affected
TODO: Parameter which will allow resetting to custom settings in addition to factory reset
TODO: Somewhere it asks for confirmation to start WinRM service, to repro reset in Windows Powershell
and then again in Core

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Reset-WinRM.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Reset-WinRM.md)
