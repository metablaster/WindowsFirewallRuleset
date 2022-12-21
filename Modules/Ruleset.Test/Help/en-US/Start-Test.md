---
external help file: Ruleset.Test-help.xml
Module Name: Ruleset.Test
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Test/Help/en-US/Start-Test.md
schema: 2.0.0
---

# Start-Test

## SYNOPSIS

Start test case

## SYNTAX

```powershell
Start-Test [-Message] <String> [-Expected <String>] [-Command <String>] [-Force] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION

Start-Test writes formatted header block the console for separate test cases.
This function should be called before single test case starts executing.

## EXAMPLES

### EXAMPLE 1

```powershell
Start-Test "some test"
```

Prints formatted header

### EXAMPLE 2

```powershell
Start-Test "some test" -Expected "output 123" -Command "Set-Something"
```

Prints formatted header

### EXAMPLE 3

```powershell
Start-Test "some test" -Force
PS> Function-WhichFails -ErrorVariable TestEV -EA SilentlyContinue
PS> Restore-Test
```

Error is converted to informational message with Restore-Test.
Here TestEV is a global error variable made with -Force switch, -EA SilentlyContinue must
be specified only for module functions.

## PARAMETERS

### -Message

Message to format and print before test case begins.
This message is appended to command being tested and then printed.

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

### -Expected

Expected output of a test.
This value is appended to Message.

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

### -Command

The command which is to be tested, it's inserted into message.
This value overrides default Command parameter specified in Enter-Test.

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

### -Force

Used to test, test cases expected to fail.
When specified a global "TestEV" error variable is created and reused by Restore-Test,
errors generated for test case are silenced and converted to informational message.
However this works only for global functions, see example below for a workaround.

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

### None. You cannot pipe objects to Start-Test

## OUTPUTS

### [string]

## NOTES

TODO: Switch for no new line, some tests will produce redundant new lines, ex.
Format-Table on pipeline
TODO: Doesn't work for starting tests inside dynamic modules
TODO: Write-Information instead of Write-Output

## RELATED LINKS
