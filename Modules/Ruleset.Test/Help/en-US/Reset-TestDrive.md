---
external help file: Ruleset.Test-help.xml
Module Name: Ruleset.Test
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Test/Help/en-US/Reset-TestDrive.md
schema: 2.0.0
---

# Reset-TestDrive

## SYNOPSIS

Remove all items from test drive

## SYNTAX

```powershell
Reset-TestDrive [[-Path] <DirectoryInfo>] [[-Retry] <Int32>] [[-Timeout] <Int32>] [-Force]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Test drive is directory where unit tests may output their temporary data.
This function clears test directory leaving only test drive root directory.
If the test drive does not exist new one is created.
For safety reasons, when non default test drive is specified the function will complete operation
only if run as standard user, in which case it prompts for confirmation.

## EXAMPLES

### EXAMPLE 1

```powershell
Reset-TestDrive
```

### EXAMPLE 2

```powershell
Reset-TestDrive "C:\PathTo\TestDrive"
```

### EXAMPLE 3

```powershell
Reset-TestDrive "C:\PathTo\TestDrive" -Retry 5 -Timeout 20000 -Force
```

## PARAMETERS

### -Path

Test drive location.
The default is "TestDrive" directory inside well known test directory in repository.

```yaml
Type: System.IO.DirectoryInfo
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: $DefaultTestDrive
Accept pipeline input: False
Accept wildcard characters: False
```

### -Retry

Specify the number of times this function will repeat an attempt to clear test drive.
This is needed in cases such as when contents are in use by another process.
The default is 2.

```yaml
Type: System.Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: 2
Accept pipeline input: False
Accept wildcard characters: False
```

### -Timeout

The timeout interval (in milliseconds) between each retry attempt.
The default is 1 second.

```yaml
Type: System.Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: 1000
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force

Skip prompting clearing non default test drive.
This parameter has no effect if the function is run as Administrator.

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

### None. You cannot pipe objects to Reset-TestDrive

## OUTPUTS

### None. Reset-TestDrive does not generate any output

## NOTES

TODO: Path supports wildcards

## RELATED LINKS
