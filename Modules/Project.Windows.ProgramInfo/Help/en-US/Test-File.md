---
external help file: Project.Windows.ProgramInfo-help.xml
Module Name: Project.Windows.ProgramInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/develop/Modules/Project.Windows.ProgramInfo/Help/en-US/Test-File.md
schema: 2.0.0
---

# Test-File

## SYNOPSIS

Check if file such as an *.exe exists

## SYNTAX

```none
Test-File [-FilePath] <String> [<CommonParameters>]
```

## DESCRIPTION

In addition to Test-Path of file, message and stack trace is shown

## EXAMPLES

### EXAMPLE 1

```none
Test-File "C:\Users\User\AppData\Local\Google\Chrome\Application\chrome.exe"
```

## PARAMETERS

### -FilePath

path to file

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

### None. You cannot pipe objects to Test-File

## OUTPUTS

### None. Warning message if file not found

## NOTES

TODO: We should attempt to fix the path if invalid here!
TODO: We should return true or false and conditionally load rule

## RELATED LINKS

