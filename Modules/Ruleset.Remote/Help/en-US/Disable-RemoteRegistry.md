---
external help file: Ruleset.Remote-help.xml
Module Name: Ruleset.Remote
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Disable-RemoteRegistry.md
schema: 2.0.0
---

# Disable-RemoteRegistry

## SYNOPSIS

Disable remote registry

## SYNTAX

```powershell
Disable-RemoteRegistry [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Disable-RemoteRegistry stops the RemoteRegistry service but does not remove firewall rules
previously configured by Enable-RemoteRegistry function

## EXAMPLES

### EXAMPLE 1

```powershell
Disable-RemoteRegistry
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

### None. You cannot pipe objects to Disable-RemoteRegistry

## OUTPUTS

### None. Disable-RemoteRegistry does not generate any output

## NOTES

TODO: Does not revert firewall rules because previous status is unknown

## RELATED LINKS
