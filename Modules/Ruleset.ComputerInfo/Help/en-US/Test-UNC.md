---
external help file: Ruleset.ComputerInfo-help.xml
Module Name: Ruleset.ComputerInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ComputerInfo/Help/en-US/Test-UNC.md
schema: 2.0.0
---

# Test-UNC

## SYNOPSIS

Validate UNC path syntax

## SYNTAX

```powershell
Test-UNC [-Name] <String[]> [-Strict] [-Quiet] [<CommonParameters>]
```

## DESCRIPTION

Test if UNC (Universal Naming Convention) path has correct path syntax

## EXAMPLES

### EXAMPLE 1

```powershell
Test-UNC \\SERVER\Share
True
```

### EXAMPLE 2

```powershell
Test-UNC \\SERVER
False
```

### EXAMPLE 3

```powershell
Test-UNC \\DESKTOP-PC\ShareName$
True
```

### EXAMPLE 4

```powershell
Test-UNC \\SERVER-01\Share\Directory DIR\file.exe
True
```

### EXAMPLE 5

```powershell
Test-UNC \SERVER-01\Share\Directory DIR
False
```

## PARAMETERS

### -Name

Universal Naming Convention path

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Strict

If specified, NETBIOS computer name must be all uppercase and must conform to IBM specifications.
By default NETBIOS computer name verification conforms to Microsoft specifications and is case insensitive.

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

### -Quiet

if specified path syntax errors are not shown, only true or false is returned.

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

### [string[]]

## OUTPUTS

### [bool]

## NOTES

A UNC path can be used to access network resources, and MUST be in the format specified by the
Universal Naming Convention.
"\\\\SERVER\Share\filename" are referred to as "pathname components" or "path components".
A valid UNC path MUST contain two or more path components.
"SERVER" is referred to as the "first pathname component", "Share" as the "second pathname component"
The size and valid characters for a path component are defined by the protocol used to access the
resource and the type of resource being accessed.

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ComputerInfo/Help/en-US/Test-UNC.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ComputerInfo/Help/en-US/Test-UNC.md)

[https://docs.microsoft.com/en-us/windows/win32/fileio/naming-a-file](https://docs.microsoft.com/en-us/windows/win32/fileio/naming-a-file)

[https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-dfsc/149a3039-98ce-491a-9268-2f5ddef08192](https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-dfsc/149a3039-98ce-491a-9268-2f5ddef08192)

