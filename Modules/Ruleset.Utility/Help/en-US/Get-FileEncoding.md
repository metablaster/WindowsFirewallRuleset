---
external help file: Ruleset.Utility-help.xml
Module Name: Ruleset.Utility
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Get-FileEncoding.md
schema: 2.0.0
---

# Get-FileEncoding

## SYNOPSIS

Gets the encoding of a file

## SYNTAX

```powershell
Get-FileEncoding [-Path] <FileInfo> [[-Encoding] <Object>] [<CommonParameters>]
```

## DESCRIPTION

Gets the encoding of a file, if the encoding can't be determined, ex.
the file
contains unicode charaters but no BOM, then by default UTF-8 is assumed.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-FileEncoding .\utf8BOM.txt
utf-8 with BOM
```

### EXAMPLE 2

```powershell
Get-FileEncoding .\utf32.txt
utf-32
```

### EXAMPLE 3

```powershell
Get-FileEncoding .\utf32.txt
utf-32
```

## PARAMETERS

### -Path

The path of the file to get the encoding of

```yaml
Type: System.IO.FileInfo
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: True
```

### -Encoding

Default encoding for non ASCII files.
The default is set by global variable, UTF8 no BOM for Core or UTF8 with BOM for Desktop edition

```yaml
Type: System.Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: $DefaultEncoding
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You cannot pipe objects to Get-FileEncoding

## OUTPUTS

### [string]

## NOTES

TODO: utf-16LE detected as utf-16 with BOM
TODO: Enumerate file encodings and implement parameter validation

## RELATED LINKS
