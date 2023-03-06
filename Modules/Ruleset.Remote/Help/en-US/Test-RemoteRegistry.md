---
external help file: Ruleset.Remote-help.xml
Module Name: Ruleset.Remote
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Test-RemoteRegistry.md
schema: 2.0.0
---

# Test-RemoteRegistry

## SYNOPSIS

Test remote registry service

## SYNTAX

```powershell
Test-RemoteRegistry [-Domain <String>] [-Quiet] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Test-RemoteRegistry tests for functioning remote registry

## EXAMPLES

### EXAMPLE 1

```powershell
Test-RemoteRegistry -Domain Server01
```

### EXAMPLE 2

```powershell
Test-RemoteRegistry -Domain Server01 -Quiet
```

## PARAMETERS

### -Domain

Remote computer name against which remote registry is to be tested

```yaml
Type: System.String
Parameter Sets: (All)
Aliases: ComputerName, CN

Required: False
Position: Named
Default value: [System.Environment]::MachineName
Accept pipeline input: False
Accept wildcard characters: False
```

### -Quiet

If specified, no warning is shown, only true or false is returned

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

### None. You cannot pipe objects to Test-RemoteRegistry

## OUTPUTS

### [bool]

## NOTES

TODO: Need to test if there is authentication with PSDrive

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Test-RemoteRegistry.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Test-RemoteRegistry.md)
