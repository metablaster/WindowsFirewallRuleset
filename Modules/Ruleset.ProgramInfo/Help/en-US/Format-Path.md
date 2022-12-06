---
external help file: Ruleset.ProgramInfo-help.xml
Module Name: Ruleset.ProgramInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Format-Path.md
schema: 2.0.0
---

# Format-Path

## SYNOPSIS

Format file system path and fix syntax errors

## SYNTAX

```powershell
Format-Path [[-LiteralPath] <String[]>] [<CommonParameters>]
```

## DESCRIPTION

Most path syntax errors are fixed however the path is never resolved or tested for existence.
For example, relative path will stay relative and if the path location does not exist it is not created.

Various paths drilled out of registry can be invalid and those specified manuallay may contain typos,
this algorithm will attempt to correct these problems, in addition to providing consistent path output.

If possible portion of the path is converted into system environment variable to shorten the length of a path.
Formatted paths will also help sorting rules in firewall GUI based on path.
Only file system paths are supported.

## EXAMPLES

### EXAMPLE 1

```powershell
Format-Path "C:\Program Files\WindowsPowerShell"
%ProgramFiles%\WindowsPowerShell
```

### EXAMPLE 2

```powershell
Format-Path "%SystemDrive%\Windows\System32"
%SystemRoot%\System32
```

### EXAMPLE 3

```powershell
Format-Path ..\dir//.\...
..\dir\.\..
```

### EXAMPLE 4

```powershell
Format-Path ~/\Direcotry//file.exe
~\Direcotry\file.exe
```

### EXAMPLE 5

```powershell
Format-Path '"C:\ProgramData\Git"'
%ALLUSERSPROFILE%\Git
```

## PARAMETERS

### -LiteralPath

File system path to format, can have environment variables, or it may contain redundant or invalid characters.

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [string[]] File path to format

## OUTPUTS

### [string] formatted path, includes environment variables, stripped off of bad characters

## NOTES

TODO: This should proably be in utility module, it's here since only this module uses this function.

## RELATED LINKS
