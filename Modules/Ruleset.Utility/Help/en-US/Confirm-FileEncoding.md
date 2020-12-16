---
external help file: Ruleset.Utility-help.xml
Module Name: Ruleset.Utility
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Confirm-FileEncoding.md
schema: 2.0.0
---

# Confirm-FileEncoding

## SYNOPSIS

Verify file is correctly encoded

## SYNTAX

```powershell
Confirm-FileEncoding [-FilePath] <String[]> [[-Encoding] <String[]>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Confirm-FileEncoding verifies target file is encoded as expected.
Wrong encoding may return bad data resulting is unexpected behavior

## EXAMPLES

### EXAMPLE 1

```powershell
Confirm-FileEncoding C:\SomeFile.txt utf16
```

## PARAMETERS

### -FilePath

Path to the file which to check

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Encoding

Expected encoding

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: @("utf-8", "us-ascii")
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

### [string] One or more paths to file to check

## OUTPUTS

### None. Confirm-FileEncoding does not generate any output

## NOTES

None.

## RELATED LINKS
