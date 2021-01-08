---
external help file: Ruleset.ProgramInfo-help.xml
Module Name: Ruleset.ProgramInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Test-Service.md
schema: 2.0.0
---

# Test-Service

## SYNOPSIS

Check if system service exists and is trusted

## SYNTAX

```powershell
Test-Service [-Name] <String[]> [-Force] [<CommonParameters>]
```

## DESCRIPTION

Test-Service verifies specified Windows services exists.
The service is then verified to confirm it's digitaly signed and that signature is valid.
If the service can't be found or verified, an error is genrated.

## EXAMPLES

### EXAMPLE 1

```powershell
Test-Service dnscache
```

### EXAMPLE 2

```
@("msiserver", "Spooler", "WSearch") | Test-Service
```

## PARAMETERS

### -Name

Service short name (not display name)

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases: ServiceName

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: True
```

### -Force

If specified, lack of digital signature or signature mismatch produces a warning
instead of an error resulting in passed test.

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

TODO: Implement accept ServiceController object, should be called InputObject, a good design needed,
however it doesn't make much sense since the function is to test existence of a service too.

## RELATED LINKS
