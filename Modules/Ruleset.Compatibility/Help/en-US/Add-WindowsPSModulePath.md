---
external help file: Ruleset.Compatibility-help.xml
Module Name: Ruleset.Compatibility
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Compatibility/Help/en-US/Add-WindowsPSModulePath.md
schema: 2.0.0
---

# Add-WindowsPSModulePath

## SYNOPSIS

Appends the existing Windows PowerShell PSModulePath to existing PSModulePath

## SYNTAX

```powershell
Add-WindowsPSModulePath [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

If the current PSModulePath does not contain the Windows PowerShell PSModulePath,
it will be appended to the end.

## EXAMPLES

### EXAMPLE 1

```powershell
Add-WindowsPSModulePath
PS> Import-Module Hyper-V
```

### EXAMPLE 2

```powershell
Add-WindowsPSModulePath
PS> Get-Module -ListAvailable
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

### None. You cannot pipe objects to Add-WindowsPSModulePath

## OUTPUTS

### None. Add-WindowsPSModulePath does not generate any output

## NOTES

Following modifications by metablaster November 2020:
- Added comment based help based on original comments
- Code formatting according to the rest of project design
- Added HelpURI link to project location

## RELATED LINKS

[https://github.com/PowerShell/WindowsCompatibility](https://github.com/PowerShell/WindowsCompatibility)
