---
external help file: Project.Windows.ComputerInfo-help.xml
Module Name: Project.Windows.ComputerInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/develop/Modules/Project.Windows.ComputerInfo/Help/en-US/ConvertFrom-OSBuild.md
schema: 2.0.0
---

# ConvertFrom-OSBuild

## SYNOPSIS
Convert from OS build number to OS version

## SYNTAX

```
ConvertFrom-OSBuild [-Build] <String> [<CommonParameters>]
```

## DESCRIPTION
Convert from OS build number to OS version associated with build.
Note that "OS version" is not the same as "OS release version"

## EXAMPLES

### EXAMPLE 1
```
ConvertFrom-OSBuild 18363.1049
1909
```

## PARAMETERS

### -Build
Operating system build number

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None, you can't p to ConvertFrom-OSBuild
## OUTPUTS

### None.
## NOTES
None.

## RELATED LINKS
