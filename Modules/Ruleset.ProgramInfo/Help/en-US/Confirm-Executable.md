---
external help file: Ruleset.ProgramInfo-help.xml
Module Name: Ruleset.ProgramInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Confirm-Executable.md
schema: 2.0.0
---

# Confirm-Executable

## SYNOPSIS

Check if file such as an *.exe exists

## SYNTAX

```powershell
Confirm-Executable [-FilePath] <String> [<CommonParameters>]
```

## DESCRIPTION

In addition to Test-Path of file, message and stack trace is shown and
warning message if file not found

## EXAMPLES

### EXAMPLE 1

```powershell
Confirm-Executable "C:\Users\USERNAME\AppData\Local\Google\Chrome\Application\chrome.exe"
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

### None. You cannot pipe objects to Confirm-Executable

## OUTPUTS

### None. Confirm-Executable does not generate any output

## NOTES

TODO: We should attempt to fix the path if invalid here!
TODO: We should return true or false and conditionally load rule
TODO: This should probably be renamed to Test-Executable to make it less likely part of utility module

## RELATED LINKS
