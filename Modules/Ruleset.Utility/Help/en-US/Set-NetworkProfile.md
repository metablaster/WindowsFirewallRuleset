---
external help file: Ruleset.Utility-help.xml
Module Name: Ruleset.Utility
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Set-NetworkProfile.md
schema: 2.0.0
---

# Set-NetworkProfile

## SYNOPSIS

Set network profile for physical network interfaces

## SYNTAX

```powershell
Set-NetworkProfile [[-NetworkCategory] <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Set network profile for each physical/hardware network interfaces
Recommended is "Public" profile for maximum security, unless "Private" is needed

## EXAMPLES

### EXAMPLE 1

```powershell
Set-NetworkProfile
```

## PARAMETERS

### -NetworkCategory

Specify network category which to apply to all NIC's.
If not specified, you're prompted for each NIC individually

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
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

### None. You cannot pipe objects to Set-NetworkProfile

## OUTPUTS

### None. Set-NetworkProfile does not generate any output

## NOTES

HACK: It looks like option to change network profile in settings app will be gone after using this
function in an elevated prompt

## RELATED LINKS
