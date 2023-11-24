---
external help file: Ruleset.Test-help.xml
Module Name: Ruleset.Test
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Test/Help/en-US/Test-Output.md
schema: 2.0.0
---

# Test-Output

## SYNOPSIS

Verify TypeName and OutputType are referring to same type

## SYNTAX

```powershell
Test-Output [-InputObject] <Object[]> -Command <String> [-Force] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION

This test case is to ensure object output typename is referring to
same type as at least one of the types described by the OutputType attribute.
Comparison is case sensitive for the matching typename part.
TypeName and OutputType including equality test is printed to console

## EXAMPLES

### EXAMPLE 1

```powershell
$Result = Some-Function
PS> Test-Output $Result -Command Some-Function
```

### EXAMPLE 2

```powershell
Some-Function | Test-Output -Command Some-Function
```

## PARAMETERS

### -Command

Commandlet or function name for which to retrieve OutputType attribute
values for comparison with InputObject

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force

If specified, the function doesn't check if either InputObject or OutputType attribute of
tested command is a .NET type.
This is useful only for PSCustomObject types defined with PSTypeName.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -InputObject

.NET object which some function returned

```yaml
Type: System.Object[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -ProgressAction

{{ Fill ProgressAction Description }}

```yaml
Type: System.Management.Automation.ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Object[]

## OUTPUTS

### System.String

## NOTES

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Test/Help/en-US/Test-Output.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Test/Help/en-US/Test-Output.md)
