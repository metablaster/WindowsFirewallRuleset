---
external help file: Ruleset.ProgramInfo-help.xml
Module Name: Ruleset.ProgramInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Test-FileSystemPath.md
schema: 2.0.0
---

# Test-FileSystemPath

## SYNOPSIS

Test existence of a file system path and validate path syntax

## SYNTAX

### None (Default)

```powershell
Test-FileSystemPath [-LiteralPath] <String> [-PathType <String>] [-Firewall] [-UserProfile]
 [<CommonParameters>]
```

### Strict

```powershell
Test-FileSystemPath [-LiteralPath] <String> [-PathType <String>] [-Firewall] [-UserProfile] [-Strict]
 [<CommonParameters>]
```

### Quiet

```powershell
Test-FileSystemPath [-LiteralPath] <String> [-PathType <String>] [-Firewall] [-UserProfile] [-Quiet]
 [<CommonParameters>]
```

## DESCRIPTION

Test-FileSystemPath checks file system path syntax by verifying environment variables and reporting
unresolved wildcard pattern or bad characters.
The path is then tested to confirm it points to an existing and valid location.

Optionally you can check if the path is compatible for firewall rules or if the path leads to user profile.
All of which can be limited to either container or leaf path type.

## EXAMPLES

### EXAMPLE 1

```powershell
Test-FileSystemPath "%Windir%"
```

True, The path is valid, and it exists

### EXAMPLE 2

```powershell
Test-FileSystemPath "'%Windir%\System32'"
```

False, Invalid path syntax

### EXAMPLE 3

```powershell
Test-FileSystemPath "%HOME%\AppData\Local\MicrosoftEdge" -Firewall -UserProfile
```

False, the path contains environment variable that leads to userprofile and will not work for firewall

### EXAMPLE 4

```powershell
Test-FileSystemPath "%SystemDrive%\Users\USERNAME\AppData\Local\MicrosoftEdge" -Firewall -UserProfile
```

True, the path leads to userprofile, is good for firewall rule and it exists

### EXAMPLE 5

```powershell
Test-FileSystemPath "%LOCALAPPDATA%\MicrosoftEdge" -UserProfile
```

True, the path lead to user profile, and it exists

## PARAMETERS

### -LiteralPath

Path to directory or file which to test.
Allows null or empty since it may come from commandlets which may return empty string or null

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

The type of path to test, can be one of the following:
1.
File - The path is path to file
2.
Directory - The path is path to directory
3.
Any - The path is either path to file or directory, this is default

```yaml
Type: System.String
Parameter Sets: (All)
Aliases: Type

Required: False
Position: Named
Default value: Any
Accept pipeline input: False
Accept wildcard characters: False
```

### -Firewall

Ensures path is valid for firewall rule.
When specified, for path to be reported as valid it must be compatible for firewall

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

Checks if the path leads to user profile.
When specified, for path to be reported as valid it must lead to user profile.

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

### -Strict

If specified, this function produces errors instead of warnings

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: Strict
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Quiet

If specified, no information, warning or error message is shown, only true or false is returned

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: Quiet
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

### None. You cannot pipe objects to Test-FileSystemPath

## OUTPUTS

### [bool] true if path exists, false otherwise

## NOTES

The result of this function should be used only to verify paths for external usage, not as input to
commandles which don't recognize system environment variables.
This function is needed in cases where the path may be a modified version of an already formatted or
verified path such as in rule scripts or to verify manually edited installation table.
TODO: This should proably be part of Utility or ComputerInfo module, it's here since only this module uses this function.

## RELATED LINKS
