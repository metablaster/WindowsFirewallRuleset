---
external help file: Ruleset.Logging-help.xml
Module Name: Ruleset.Logging
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Logging/Help/en-US/Write-LogFile.md
schema: 2.0.0
---

# Write-LogFile

## SYNOPSIS

Write a message or hash table to log file

## SYNTAX

### Message

```powershell
Write-LogFile -Message <String[]> [-Path <DirectoryInfo>] [-Tags <String[]>] [-LogName <String>] [-Raw]
 [-Overwrite] [<CommonParameters>]
```

### Hash

```powershell
Write-LogFile -Hash <Object> [-Path <DirectoryInfo>] [-LogName <String>] [-Overwrite] [<CommonParameters>]
```

## DESCRIPTION

Unlike Update-Log function which automatically picks up and logs Write-* streams,
the purpose of this function is to write logs manually.

Each script that uses Write-LogFile should first push a new header to "HeaderStack" variable,
this header will then appear in newly created logs that describes this log.

Before the script exits you should pop header from HeaderStack.

To write new log to different log or location within same script, the HeaderStack should be pushed
a new header, and popped before writing to previous log.

## EXAMPLES

### EXAMPLE 1

```
$HeaderStack.Push("My Header")
PS> Write-LogFile -Path "C:\logs" -LogName "Settings" -Tags "MyTag" -Message "Sample message1", "Sample message 2"
PS> $HeaderStack.Pop() | Out-Null
```

Will write "Sample message" InformationRecord to log C:\logs\Settings_15.12.20.log with a header set to "My Header"

### EXAMPLE 2

```
$HeaderStack.Push("My Header")
PS> [hashtable] $HashResult = Get-SomeHashTable
PS> Write-LogFile -Path "C:\logs" -LogName "Settings" -Tags "MyTag" -Hash $HashResult
PS> $HeaderStack.Pop() | Out-Null
```

Will write entire $HashResult to log C:\logs\Settings_15.12.20.log with a header set to "My Header"

### EXAMPLE 3

```
$HeaderStack.Push("My Header")
PS> Write-LogFile -Path "C:\logs" -LogName "Settings" -Tags "MyTag" -Message "Sample message"
PS> $HeaderStack.Push("Another Header")
PS> Write-LogFile -Path "C:\logs\next" -LogName "Admin" -Tags "NewTag" -Message "Another message"
PS> $HeaderStack.Pop() | Out-Null
PS> $HeaderStack.Pop() | Out-Null
```

Will write "Sample message" InformationRecord to log C:\logs\Settings_15.12.20.log with a header set to "My Header"
Will write "Another message" InformationRecord to log C:\logs\next\Admin_15.12.20.log with a header set to "Another Header"

### EXAMPLE 4

```
$HeaderStack.Push("Raw message overwrite")
PS> Write-LogFile -Message "Raw message overwrite" -LogName "MyRawLog" -Path "C:\logs" -Raw -Overwrite
```

Will write raw message and overwrite existing log file if it exists.

## PARAMETERS

### -Message

One or more messages from which to construct "InformationRecord" and append to log file

```yaml
Type: System.String[]
Parameter Sets: Message
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Hash

Hash table or dictionary which to write to log file

```yaml
Type: System.Object
Parameter Sets: Hash
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Path

Destination directory

```yaml
Type: System.IO.DirectoryInfo
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: $LogsFolder
Accept pipeline input: False
Accept wildcard characters: True
```

### -Tags

One or more optional message tags

```yaml
Type: System.String[]
Parameter Sets: Message
Aliases:

Required: False
Position: Named
Default value: Administrator
Accept pipeline input: False
Accept wildcard characters: False
```

### -LogName

File label that is added to current date for resulting file name

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Admin
Accept pipeline input: False
Accept wildcard characters: False
```

### -Raw

If specified, the message is written directly to log file without any formatting,
by default InformationRecord object is created from the message and written to log file.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: Message
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Overwrite

If specified, the log file is overwritten if it exists.

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

### None. You cannot pipe objects to Write-LogFile

## OUTPUTS

### None. Write-LogFile does not generate any output

## NOTES

Maybe there should be stack of labels and/or tags, but too early to see if this makes sense

## RELATED LINKS
