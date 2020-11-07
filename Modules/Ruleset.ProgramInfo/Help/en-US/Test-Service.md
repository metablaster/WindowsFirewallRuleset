---
external help file: Ruleset.ProgramInfo-help.xml
Module Name: Ruleset.ProgramInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Test-Service.md
schema: 2.0.0
---

# Test-Service

## SYNOPSIS

Check if service exists on system

## SYNTAX

```none
Test-Service [-Service] <String> [<CommonParameters>]
```

## DESCRIPTION

Check if service exists on system, if not show warning message

## EXAMPLES

### EXAMPLE 1

```none
Test-Service dnscache
```

## PARAMETERS

### -Service

Service name (not display name)

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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You cannot pipe objects to Test-Service

## OUTPUTS

### None. Warning and info message if service not found

## NOTES

None.

## RELATED LINKS
