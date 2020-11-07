---
external help file: Ruleset.ProgramInfo-help.xml
Module Name: Ruleset.ProgramInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Test-Installation.md
schema: 2.0.0
---

# Test-Installation

## SYNOPSIS

Test if given installation directory is valid

## SYNTAX

```none
Test-Installation [-Program] <String> [-FilePath] <PSReference> [<CommonParameters>]
```

## DESCRIPTION

Test if given installation directory is valid and if not this method will search the
system for valid path and return it via reference parameter

## EXAMPLES

### EXAMPLE 1

```
$MyProgram = "%ProgramFiles(x86)%\Microsoft Office\root\Office16"
Test-Installation "Office" ([ref] $MyProgram)
```

## PARAMETERS

### -Program

Predefined program name for which to search

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

### -FilePath

Reference to variable which holds a path to program (excluding executable)

```yaml
Type: System.Management.Automation.PSReference
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You cannot pipe objects to Test-Installation

## OUTPUTS

### [bool] true if path is ok or found false otherwise,

### via reference, if test OK same path, if not try to update path, else given path back is not modified

## NOTES

TODO: temporarily using ComputerName parameter

## RELATED LINKS
