---
external help file: Ruleset.Remote-help.xml
Module Name: Ruleset.Remote
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Disconnect-Computer.md
schema: 2.0.0
---

# Disconnect-Computer

## SYNOPSIS

Disconnect remote computer

## SYNTAX

```powershell
Disconnect-Computer [-Domain] <String> [<CommonParameters>]
```

## DESCRIPTION

Disconnect remote computer previously connected with Connect-Computer.
This procedure releases any sessions established with remote host and
removes resources created during a session.

## EXAMPLES

### EXAMPLE 1

```powershell
Disconnect-Computer
```

## PARAMETERS

### -Domain

Computer name which to disconnect

```yaml
Type: System.String
Parameter Sets: (All)
Aliases: ComputerName, CN

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You cannot pipe objects to Disconnect-Computer

## OUTPUTS

### None. Disconnect-Computer does not generate any output

## NOTES

TODO: If there are multiple connections, remove only specific ones
TODO: This function should be called at the end of each script since individual scripts may be run,
implementation needed to prevent disconnection when Deploy-Firewall runs.

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Disconnect-Computer.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Disconnect-Computer.md)

[https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_remote_disconnected_sessions](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_remote_disconnected_sessions)
