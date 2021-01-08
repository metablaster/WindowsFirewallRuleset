---
external help file: Ruleset.Utility-help.xml
Module Name: Ruleset.Utility
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Resolve-FileSystemPath.md
schema: 2.0.0
---

# Resolve-FileSystemPath

## SYNOPSIS

Resolve wildcard directory or file location

## SYNTAX

```powershell
Resolve-FileSystemPath [-Path] <String> [-File] [-Create] [<CommonParameters>]
```

## DESCRIPTION

Ensure directory or file name wildcard pattern resolves to single location.
Unlike Resolve-Path which accepts and produces paths supported by any PowerShell provider,
this function accepts only file system paths, and produces either \[System.IO.DirectoryInfo\] or
\[System.IO.FileInfo\]
Also unlike Resolve-Path the resultant path object is returned even if target file system item
does not exist, as long as portion of the specified path is resolved and as long as new path
doesn't resolve to multiple locations.

## EXAMPLES

### EXAMPLE 1

```powershell
Resolve-FileSystemPath "C:\Win\Sys?em3*"
```

Resolves to "C:\Windows\System32" and returns System.IO.DirectoryInfo object

### EXAMPLE 2

```powershell
Resolve-FileSystemPath "..\..\MyFile" -File -Create
```

Creates file "MyFile" 2 directories back if it doesn't exist and returns System.IO.FileInfo object

## PARAMETERS

### -Path

Directory or file location to target file system item.
Wildcard characters and relative paths are supported.

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

### -File

If specified \[System.IO.FileInfo\] object is created instead of \[System.IO.DirectoryInfo\]

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

### -Create

If specified, target directory or file is created if it doesn't exist

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

### None. You cannot pipe objects to Resolve-FileSystemPath

## OUTPUTS

### [System.IO.DirectoryInfo]

### [System.IO.FileInfo]

## NOTES

TODO: Implement -Relative parameter, see Resolve-Path
TODO: This function needs improvements according to the rest of *FileSystem* functions

## RELATED LINKS
