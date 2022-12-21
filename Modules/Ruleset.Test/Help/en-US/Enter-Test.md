---
external help file: Ruleset.Test-help.xml
Module Name: Ruleset.Test
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Test/Help/en-US/Enter-Test.md
schema: 2.0.0
---

# Enter-Test

## SYNOPSIS

Initialize unit test

## SYNTAX

```powershell
Enter-Test [[-Command] <String>] [-Private] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Enter-Test initializes unit test
Must be called before first test case in single unit test and in pair with Exit-Test

## EXAMPLES

### EXAMPLE 1

```powershell
Enter-Test
```

### EXAMPLE 2

```powershell
Enter-Test -Command "Get-Something"
```

### EXAMPLE 3

```powershell
Enter-Test -Private
```

## PARAMETERS

### -Command

Optionally specify the command which is to be tested.
This value is used by Start-Test function by default which is shown in formatted output unless
overridden with Start-Test.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Private

Should be specified to test private module functions

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

### None. You cannot pipe objects to Enter-Test

## OUTPUTS

### None. Enter-Test does not generate any output

## NOTES

HACK: Using -Private switch will not work as expected if private function depends on
or calls other module variables or public module functions, see Edit-Table for example

## RELATED LINKS
