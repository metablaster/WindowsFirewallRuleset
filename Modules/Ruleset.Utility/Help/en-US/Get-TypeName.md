---
external help file: Ruleset.Utility-help.xml
Module Name: Ruleset.Utility
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Get-TypeName.md
schema: 2.0.0
---

# Get-TypeName

## SYNOPSIS

Get commandlet output typename, OutputType attribute or convert to/from type accelerator

## SYNTAX

### Object

```powershell
Get-TypeName [[-InputObject] <Object[]>] [-Accelerator] [-Force] [<CommonParameters>]
```

### Command

```powershell
Get-TypeName -Command <String> [-Accelerator] [-Force] [<CommonParameters>]
```

### Name

```powershell
Get-TypeName -Name <String> [-Accelerator] [<CommonParameters>]
```

## DESCRIPTION

Get-TypeName is a multipurpose type name getter, behavior of the function depends on
parameter set being used.
It can get type name of an object, OutputType attribute of a function or it could
convert type name to accelerator and vice versa (accelerator to full name).
By default the function works only for .NET types but you can force it handle user
defined PSCustomObject's

## EXAMPLES

### EXAMPLE 1

```powershell
Get-TypeName (Get-Process)
```

System.Diagnostics.Process

### EXAMPLE 2

```powershell
Get-TypeName -Command Get-Process
```

System.Diagnostics.ProcessModule
System.Diagnostics.FileVersionInfo
System.Diagnostics.Process

### EXAMPLE 3

```powershell
Get-TypeName -Name [switch]
```

System.Management.Automation.SwitchParameter

### EXAMPLE 4

```powershell
([System.Environment]::MachineName) | Get-TypeName -Accelerator
```

string

### EXAMPLE 5

```powershell
Generate-Types | Get-TypeName | DealWith-TypeNames
```

Sends typename for each input object down the pipeline

## PARAMETERS

### -InputObject

Target object for which to retrieve output typenames.
This is the actual output of some commandlet or function when passed to Get-TypeName,
either via pipeline or trough parameter.

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
The name of a type can be specified either as a "typename" or \[typename\] syntax.
Type specified must be .NET type.

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
Otherwise If specified, with "Name" parameter, converts resultant accelerator to full name.
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

### -Force

If specified, the function doesn't check if type name is .NET type.
This is useful only for PSCustomObject types defined with PSTypeName.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: Object, Command
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

### [object[]]

## OUTPUTS

### [string]

## NOTES

There may be multiple accelerators for same type, for example:
Get-TypeName -Name \[System.Management.Automation.PSObject\] -Accelerator
It's possible to rework function to get the exact type if this is desired see begin block
TODO: Will not work to detect .NET types for formatted output, see Get-FormatData
TODO: Will not work for non .NET types because we have no use of it, but should be implemented,
see Get-TypeName unit test

## RELATED LINKS
