---
external help file: Ruleset.ProgramInfo-help.xml
Module Name: Ruleset.ProgramInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Test-Environment.md
schema: 2.0.0
---

# Test-Environment

## SYNOPSIS

Test if a path is valid with additional checks

## SYNTAX

```powershell
Test-Environment [-Path] <String> [-PathType <String>] [-Firewall] [-UserProfile] [<CommonParameters>]
```

## DESCRIPTION

Similar to Test-Path but expands environment variables and performs additional checks if desired:
1.
check if input path is compatible for firewall rules.
2.
check if the path leads to user profile
Both of which can be limited to either container or leaf path type.

## EXAMPLES

### EXAMPLE 1

```powershell
Test-Environment "%Windir%"
```

True, The path is valid, and it exists

### EXAMPLE 2

```powershell
Test-Environment "'%Windir%\System32'"
```

False, Invalid path syntax

### EXAMPLE 3

```powershell
Test-Environment "%HOME%\AppData\Local\MicrosoftEdge" -Firewall -UserProfile
```

False, the path leads to userprofile but will not work for firewall rule

### EXAMPLE 4

```powershell
Test-Environment "%SystemDrive%\Users\USERNAME\AppData\Local\MicrosoftEdge" -Firewall -UserProfile
```

True, the path leads to userprofile and is good for firewall rule, and it exists

### EXAMPLE 5

```powershell
Test-Environment "%LOCALAPPDATA%\MicrosoftEdge" -UserProfile
```

True, the path lead to user profile, and it exists

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
1.
Leaf -The path is file or registry entry
2.
Container - the path is container such as folder or registry key
3.
Any - Either Leaf or Container

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

TODO: This should proably be part of utility module,
it's here since only this module uses this function.
This function should be used only to verify paths for external usage, not for commandles which
don't expand system environment variables.

## RELATED LINKS
