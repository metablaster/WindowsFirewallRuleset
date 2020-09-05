---
external help file: Project.Windows.ProgramInfo-help.xml
Module Name: Project.Windows.ProgramInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/develop/Modules/Project.Windows.ProgramInfo/Help/en-US/Test-Environment.md
schema: 2.0.0
---

# Test-Environment

## SYNOPSIS
Test if path is valid for firewall rule

## SYNTAX

```
Test-Environment [[-FilePath] <String>] [<CommonParameters>]
```

## DESCRIPTION
Same as Test-Path but expands system environment variables, and checks if path is compatible
for firewall rules

## EXAMPLES

### EXAMPLE 1
```
Test-Environment %SystemDrive%
```

## PARAMETERS

### -FilePath
Path to folder, Allows null or empty since input may come from other commandlets which can return empty or null

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You cannot pipe objects to Test-Environment
## OUTPUTS

### [bool] true if path exists, false otherwise
## NOTES
None.

## RELATED LINKS
