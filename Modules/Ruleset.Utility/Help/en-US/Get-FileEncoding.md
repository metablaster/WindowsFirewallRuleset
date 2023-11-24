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
Get-FileEncoding [-Path] <FileInfo> [[-Encoding] <Object>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION

Gets the encoding of a file, if the encoding can't be determined, ex.
the file
contains unicode charaters but no BOM, then the default encoding is assumed which
can be specified trough Encoding parameter.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-FileEncoding .\utf8BOM.txt
utf8BOM
```

### EXAMPLE 2

```powershell
Get-FileEncoding .\utf-16LE.txt
unicode
```

### EXAMPLE 3

```powershell
Get-FileEncoding .\ascii.txt
ascii
```

### EXAMPLE 4

```powershell
Get-FileEncoding C:\WINDOWS\regedit.exe
binary
```

## PARAMETERS

### -Path

The path of the file to get the encoding of

```yaml
Type: System.IO.FileInfo
Parameter Sets: (All)
Aliases: FilePath

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: True
```

### -Encoding

Default encoding to assume for non ASCII files without BOM.
This encoding is also used to read file if needed.
This parameter can be either a string identifying an encoding that is used by PowerShell commandlets
such as "utf8" or System.Text.Encoding object.
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

### -ProgressAction

{{ Fill ProgressAction Description }}

```yaml
Type: System.Management.Automation.ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
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

TODO: Encoding parameter should also accept code page or encoding name, Encoding class has
static functions to convert.
TODO: Parameter to specify output as \[System.Text.Encoding\] instead of default \[string\]
TODO: utf8 file reported as ascii in Windows PowerShell

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Get-FileEncoding.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Get-FileEncoding.md)

[https://docs.microsoft.com/en-us/dotnet/api/system.text.encoding](https://docs.microsoft.com/en-us/dotnet/api/system.text.encoding)

[https://docs.microsoft.com/en-us/dotnet/api/microsoft.powershell.commands.filesystemcmdletproviderencoding](https://docs.microsoft.com/en-us/dotnet/api/microsoft.powershell.commands.filesystemcmdletproviderencoding)
