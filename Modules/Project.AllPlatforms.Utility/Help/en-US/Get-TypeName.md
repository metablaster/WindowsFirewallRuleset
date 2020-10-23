---
external help file: Project.AllPlatforms.Utility-help.xml
Module Name: Project.AllPlatforms.Utility
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/develop/Modules/Project.AllPlatforms.Utility/Help/en-US/Get-TypeName.md
schema: 2.0.0
---

# Get-TypeName

## SYNOPSIS

Returns .NET return type name for input object

## SYNTAX

```none
Get-TypeName [-InputObject] <Object> [<CommonParameters>]
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
Type: System.Object
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Object Any .NET object

## OUTPUTS

### [string] type name or null

## NOTES

Original code link: https://github.com/gravejester/Communary.PASM
TODO: need better checking for input, on pipeline.

Modifications by metablaster year 2020:
Added check when object is null
Added comment based help
Removed unneeded parentheses
Added input type to parameter

## RELATED LINKS
