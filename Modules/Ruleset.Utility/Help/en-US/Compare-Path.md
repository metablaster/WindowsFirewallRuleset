---
external help file: Ruleset.Utility-help.xml
Module Name: Ruleset.Utility
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Compare-Path.md
schema: 2.0.0
---

# Compare-Path

## SYNOPSIS

Compare 2 paths for equality or similarity

## SYNTAX

```powershell
Compare-Path [-Path] <String> [-ReferencePath] <String> [-Loose] [-CaseSensitive] [<CommonParameters>]
```

## DESCRIPTION

Compare-Path depending on parameters either checks if 2 paths lead to same location
taking into account environment variables, relative path locations and wildcards
or it checks if 2 paths are similar which depends on wildcards contained in the input

## EXAMPLES

### EXAMPLE 1

```powershell
Compare-Path "%SystemDrive%\Windows" "C:\Win*" -Loose
True
```

### EXAMPLE 2

```powershell
Compare-Path "%SystemDrive%\Win*\System32\en-US\.." "C:\Wind*\System3?\" -CaseSensitive
True
```

### EXAMPLE 3

```powershell
Compare-Path "%SystemDrive%\" "D:\"
False
```

## PARAMETERS

### -Path

The path which to compare against the reference path

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: True
```

### -ReferencePath

The path against which to compare

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Loose

if specified perform "loose" comparison:
Does not attempt to resolve input paths, and respects wildcards all of which happens
after input paths have been expanded off environment variables

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

### -CaseSensitive

If specified performs case sensitive comparison

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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You cannot pipe objects to Compare-Path

## OUTPUTS

### [bool]

## NOTES

None.

## RELATED LINKS
