---
external help file: Ruleset.Utility-help.xml
Module Name: Ruleset.Utility
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Confirm-FileEncoding.md
schema: 2.0.0
---

# Confirm-FileEncoding

## SYNOPSIS

Verify file is encoded as expected

## SYNTAX

### Path (Default)

```powershell
Confirm-FileEncoding [-Path] <FileInfo[]> [-Encoding <String[]>] [-Binary] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### Literal

```powershell
Confirm-FileEncoding -LiteralPath <FileInfo[]> [-Encoding <String[]>] [-Binary] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION

Confirm-FileEncoding verifies target file is encoded as expected.
Unexpected encoding may give bad data resulting is unexpected behavior

## EXAMPLES

### EXAMPLE 1

```powershell
Confirm-FileEncoding C:\SomeFile.txt -Encoding utf16
```

## PARAMETERS

### -Path

Path to the file which is to be checked.
Wildcard characters are permitted.

```yaml
Type: System.IO.FileInfo[]
Parameter Sets: Path
Aliases: FilePath

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: True
```

### -LiteralPath

Specifies a path to one or more file locations.
The value of LiteralPath is used exactly as it is typed.
No characters are interpreted as wildcards

```yaml
Type: System.IO.FileInfo[]
Parameter Sets: Literal
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Encoding

Expected encoding, for PS Core the default is "utf8NoBOM" or "ascii",
for PS Desktop the default is "utf8" or "ascii"

The acceptable values for this parameter are as follows:

ascii: Encoding for the ASCII (7-bit) character set.
bigendianunicode: UTF-16 format using the big-endian byte order.
bigendianutf32: UTF-32 format using the big-endian byte order.
oem: The default encoding for MS-DOS and console programs.
unicode: UTF-16 format using the little-endian byte order.
utf7: UTF-7 format.
utf8: UTF-8 format.
utf32: UTF-32 format.

The following values are valid for Core edition only:

utf8BOM: UTF-8 format with Byte Order Mark (BOM)
utf8NoBOM: UTF-8 format without Byte Order Mark (BOM)

The following values are valid For Desktop edition only:

byte: A sequence of bytes.
default: Encoding that corresponds to the system's active code page (usually ANSI).
string: Same as Unicode.
unknown: Same as Unicode.

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Binary

If specified, binary files are left alone.
By default binary files are detected as having wrong encoding.

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

### -WhatIf

Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm

Prompts you for confirmation before running the cmdlet.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [System.IO.FileInfo[]] One or more paths to file to check

## OUTPUTS

### None. Confirm-FileEncoding does not generate any output

## NOTES

None.

## RELATED LINKS
