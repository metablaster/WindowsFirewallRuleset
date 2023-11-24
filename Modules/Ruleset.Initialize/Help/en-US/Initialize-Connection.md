---
external help file: Ruleset.Initialize-help.xml
Module Name: Ruleset.Initialize
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Initialize/Help/en-US/Initialize-Connection.md
schema: 2.0.0
---

# Initialize-Connection

## SYNOPSIS

Initialize connection for firewall deployment

## SYNTAX

```powershell
Initialize-Connection [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Initialize-Connection configures PowerShell for remote firewall deployment.
CIM session, PS session, remote registry etc.

## EXAMPLES

### EXAMPLE 1

```powershell
Initialize-Connection
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

### None. You cannot pipe objects to Initialize-Connection

## OUTPUTS

### None. Initialize-Connection does not generate any output

## NOTES

None.

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Initialize/Help/en-US/Initialize-Connection.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Initialize/Help/en-US/Initialize-Connection.md)
