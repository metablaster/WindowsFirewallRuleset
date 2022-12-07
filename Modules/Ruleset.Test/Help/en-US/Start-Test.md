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
Start-Test [-Message] <String> [-Expected <String>] [-Command <String>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION

Start-Test writes output to host to separate test cases.
Formatted message block is shown in the console.
This function must be called before single test case starts executing

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

The command which is to be tested.
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

TODO: switch for no new line, some tests will produce redundant new lines, ex.
Format-Table in pipeline
TODO: Doesn't work starting tests inside dynamic modules
TODO: Write-Information instead of Write-Output

## RELATED LINKS
