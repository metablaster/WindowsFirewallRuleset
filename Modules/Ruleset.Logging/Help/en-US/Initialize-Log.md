---
external help file: Ruleset.Logging-help.xml
Module Name: Ruleset.Logging
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Logging/Help/en-US/Initialize-Log.md
schema: 2.0.0
---

# Initialize-Log

## SYNOPSIS

Generates a log file name for Update-Log function

## SYNTAX

```none
Initialize-Log [-Folder] <String> -Label <String> [-Header <String>] [<CommonParameters>]
```

## DESCRIPTION

Generates a log file name composed of current date and appends to requested label and path.
The function checks if the path to log file exists, if not it creates directory but not log file.

## EXAMPLES

### EXAMPLE 1

```none
Initialize-Log "C:\Logs" -Label "Warning"
```

Warning_25.02.20.log

## PARAMETERS

### -Folder

Path to directory where to save logs

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

### -Label

File label which precedes file date, ex.
Warning or Error

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Header

If specified, this header message will be at the top of a log file.
This parameter is ignored for existing log files

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You cannot pipe objects to Initialize-Log

## OUTPUTS

### [string] Full path to log file name

## NOTES

None.

## RELATED LINKS
