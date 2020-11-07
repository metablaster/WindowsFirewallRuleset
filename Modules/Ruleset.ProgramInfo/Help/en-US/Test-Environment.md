---
external help file: Ruleset.ProgramInfo-help.xml
Module Name: Ruleset.ProgramInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Test-Environment.md
schema: 2.0.0
---

# Test-Environment

## SYNOPSIS

Test if path is valid for firewall rule

## SYNTAX

```none
Test-Environment [-Path] <String> [-PathType <String>] [-Firewall] [-UserProfile] [<CommonParameters>]
```

## DESCRIPTION

Same as Test-Path but expands system environment variables, and checks if path is compatible
for firewall rules

## EXAMPLES

### EXAMPLE 1

```none
Test-Environment %SystemDrive%
```

## PARAMETERS

### -Path

Path to folder, Allows null or empty since input may come from other commandlets which
can return empty or null

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

### -PathType

A type of path to test, can be one of the following:
1. Leaf -The path is file or registry entry
2. Container - the path is container such as folder or registry key
3. Any - Either Leaf or Container

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Container
Accept pipeline input: False
Accept wildcard characters: False
```

### -Firewall

Ensures the path is valid for firewall rule

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

### -UserProfile

Checks if the path leads to user profile

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

### None. You cannot pipe objects to Test-Environment

## OUTPUTS

### [bool] true if path exists, false otherwise

## NOTES

None.

## RELATED LINKS
