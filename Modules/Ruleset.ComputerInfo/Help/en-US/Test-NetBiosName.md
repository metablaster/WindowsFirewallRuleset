---
external help file: Ruleset.ComputerInfo-help.xml
Module Name: Ruleset.ComputerInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ComputerInfo/Help/en-US/Test-NetBiosName.md
schema: 2.0.0
---

# Test-NetBiosName

## SYNOPSIS

Validate NETBIOS name syntax

## SYNTAX

```powershell
Test-NetBiosName [-Name] <String[]> [-Strict] [-Quiet] [<CommonParameters>]
```

## DESCRIPTION

Test if NETBIOS computer name has correct syntax

## EXAMPLES

### EXAMPLE 1

```powershell
Test-NetBiosName "*SERVER"
False
```

### EXAMPLE 2

```powershell
Test-NetBiosName "-SERVER-01" -Quiet
True
```

### EXAMPLE 3

```powershell
Test-NetBiosName "-Server-01" -Strict
False
```

## PARAMETERS

### -Name

Computer NETBIOS name which is to be checked

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

If specified, name must be all uppercase and must conform to IBM specifications.
By default verification conforms to Microsoft specifications and is case insensitive.

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

if specified name syntax errors are not shown, only true or false is returned.

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

NetBIOS names are always converted to uppercase when sent to other
systems, and may consist of any character, except:
- Any character less than a space (0x20)
- the characters " .
/ \ \[ \] : | \< \> + = ; ,
The name should not start with an asterisk (*)

Microsoft allows the dot, while IBM does not
Space character may work on Windows system as well even though it's not allowed, it may be useful
for domains such as NT AUTHORITY\NETWORK SERVICE
Important to understand is, the choice of name used by a higher-layer protocol or application is up
to that protocol or application and not NetBIOS.

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ComputerInfo/Help/en-US/Test-NetBiosName.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ComputerInfo/Help/en-US/Test-NetBiosName.md)

[https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-nbte/6f06fa0e-1dc4-4c41-accb-355aaf20546d](https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-nbte/6f06fa0e-1dc4-4c41-accb-355aaf20546d)

