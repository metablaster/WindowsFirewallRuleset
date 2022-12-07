---
external help file: Ruleset.PolicyFileEditor-help.xml
Module Name: Ruleset.PolicyFileEditor
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.PolicyFileEditor/Help/en-US/Update-GptIniVersion.md
schema: 2.0.0
---

# Update-GptIniVersion

## SYNOPSIS

Increments the version counter in a gpt.ini file.

## SYNTAX

```powershell
Update-GptIniVersion [-Path] <String> [-PolicyType] <String[]> [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Increments the version counter in a gpt.ini file.

## EXAMPLES

### EXAMPLE 1

```powershell
Update-GptIniVersion -Path $env:SystemRoot\system32\GroupPolicy\gpt.ini -PolicyType Machine
```

Increments the Machine version counter of the local GPO.

### EXAMPLE 2

```powershell
Update-GptIniVersion -Path $env:SystemRoot\system32\GroupPolicy\gpt.ini -PolicyType User
```

Increments the User version counter of the local GPO.

### EXAMPLE 3

```powershell
Update-GptIniVersion -Path $env:SystemRoot\system32\GroupPolicy\gpt.ini -PolicyType Machine, User
```

Increments both the Machine and User version counters of the local GPO.

## PARAMETERS

### -Path

Path to the gpt.ini file that is to be modified.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PolicyType

Can be set to either 'Machine', 'User', or both.
This affects how the value of the Version number in the ini file is changed.

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
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

### None. You cannot pipe objects to Update-GptIniVersion

## OUTPUTS

### None. Update-GptIniVersion does not generate output

## NOTES

A gpt.ini file contains only a single Version value.
However, this represents two separate counters, for machine and user versions.
The high 16 bits of the value are the User counter, and the low 16 bits are the Machine counter.
For example (on PowerShell 3.0 and later), the Version value when the Machine counter is set to 3
and the User counter is set to 5 can be found by evaluating this expression: (5 -shl 16) -bor 3,
which will show up as decimal value 327683 in the INI file.

## RELATED LINKS
