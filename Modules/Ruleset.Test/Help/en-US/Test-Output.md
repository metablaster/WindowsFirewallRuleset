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
Test-Output [-InputObject] <Object[]> -Command <String> [<CommonParameters>]
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

### -InputObject

The actual .NET type that some function returns

```yaml
Type: System.Object[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Command

Commandlet or function name for which to retrieve OutputType attribute values.

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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [object[]]

## OUTPUTS

### None. Test-Output does not generate any output

## NOTES

TODO: InputObject should be returned if pipeline is used

## RELATED LINKS
