---
external help file: Ruleset.Utility-help.xml
Module Name: Ruleset.Utility
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Get-TypeName.md
schema: 2.0.0
---

# Get-TypeName

## SYNOPSIS

Returns .NET return type name for input object

## SYNTAX

### Object

```none
Get-TypeName [[-InputObject] <Object[]>] [-Accelerator] [<CommonParameters>]
```

### Command

```none
Get-TypeName -Command <String> [-Accelerator] [<CommonParameters>]
```

### Name

```none
Get-TypeName -Name <String> [-Accelerator] [<CommonParameters>]
```

## DESCRIPTION

Unlike Get-Member commandlet returns only type name, and if
there are multiple type names chooses unique ones only.

## EXAMPLES

### EXAMPLE 1

```none
Get-Process | Get-TypeName
```

## PARAMETERS

### -InputObject

Target object for which to retrieve type name

```yaml
Type: System.Object[]
Parameter Sets: Object
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Command

Commandlet or function name for which to retrieve OutputType attribute value
The command name can be specified either as "FUNCTIONNAME" or just FUNCTIONNAME

```yaml
Type: System.String
Parameter Sets: Command
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name

Translate full type name to accelerator or accelerator to full typename.
By default converts acceleartors to full typenames.
No conversion is done if resultant type already is of desired format.
The name of a type can be specified either as a "typename" or [typename] syntax

```yaml
Type: System.String
Parameter Sets: Name
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Accelerator

When used converts resultant full typename to accelerator.
Otherwise if specified with 'Name' parameter, converts resultant accelerator to full name.
No conversion is done if resultant type already is of desired format.

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

### [System.Object]

## OUTPUTS

### [string]

## NOTES

Original code link: https://github.com/gravejester/Communary.PASM
TODO: need better checking for input, on pipeline.

Modifications by metablaster year 2020:
Added check when object is null
Added comment based help
Removed unneeded parentheses
Added input type to parameter

## RELATED LINKS
