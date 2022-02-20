---
external help file: Ruleset.Remote-help.xml
Module Name: Ruleset.Remote
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Enable-RemoteRegistry.md
schema: 2.0.0
---

# Enable-RemoteRegistry

## SYNOPSIS

Enable remote registry

## SYNTAX

```powershell
Enable-RemoteRegistry [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Starts the RemoteRegistry service and adds required firewall rules
which enables remote users to modify registry settings on this computer and conversely.

## EXAMPLES

### EXAMPLE 1

```powershell
Enable-RemoteRegistry
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

### None. You cannot pipe objects to Enable-RemoteRegistry

## OUTPUTS

### None. Enable-RemoteRegistry does not generate any output

## NOTES

For remote registry to work, both client and server must enable remote registry service,
must enable File and Printer sharing and Network Discovery for both inbound and outbound,
and must operate on private profile if either one is workstation machine.

In addition to make it work in PS, administrative authentication must be done by opening a share
to server by client computer by using New-PSDrive

## RELATED LINKS
