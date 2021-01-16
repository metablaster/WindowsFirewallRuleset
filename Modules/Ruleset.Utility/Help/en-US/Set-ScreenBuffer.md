---
external help file: Ruleset.Utility-help.xml
Module Name: Ruleset.Utility
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Set-ScreenBuffer.md
schema: 2.0.0
---

# Set-ScreenBuffer

## SYNOPSIS

Set vertical screen buffer to recommended value

## SYNTAX

```powershell
Set-ScreenBuffer [[-Height] <UInt16>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Set-ScreenBuffer sets screenbuffer for current powershell session.
In some cases, depending on project settings a user might need larger buffer
to preserve all the output in the console for review and scroll back.

## EXAMPLES

### EXAMPLE 1

```powershell
Set-ScreenBuffer
```

## PARAMETERS

### -Height

New screen buffer height

```yaml
Type: System.UInt16
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: 3000
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

### None. You cannot pipe objects to Set-ScreenBuffer

## OUTPUTS

### None. Set-ScreenBuffer does not generate any output

## NOTES

TODO: A parameter to restore previous value may be useful

## RELATED LINKS
