---
external help file: WindowsCompatibility-help.xml
Module Name: WindowsCompatibility
online version:
schema: 2.0.0
---

# Get-WinModule

## SYNOPSIS

Get a list of the available modules from the compatibility session

## SYNTAX

```
Get-WinModule [[-Name] <String[]>] [-ComputerName <String>] [-ConfigurationName <String>]
 [-Credential <PSCredential>] [-Full] [<CommonParameters>]
```

## DESCRIPTION

Get a list of the available modules from the compatibility session.

By default, when executing, the current compatibility session is used,
or, in the case where there is no existing session,
a new default session will be created.
This behavior can be overridden using the additional parameters on this command.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-WinModule *PNP*
```

```none
Name      Version Description
----      ------- -----------
PnpDevice 1.0.0.0
```

This example looks for modules in the compatibility session with the string 'PNP' in their name.

## PARAMETERS

### -ComputerName

If you don't want to use the default compatibility session,
use this parameter to specify the name of the computer on which to create the compatibility session.
(Defaults to 'localhost')

```yaml
Type: String
Parameter Sets: (All)
Aliases: cn

Required: False
Position: Named
Default value: localhost
Accept pipeline input: False
Accept wildcard characters: False
```

### -ConfigurationName

Specifies the configuration to connect to when creating the compatibility session
(Defaults to 'Microsoft.PowerShell')

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Microsoft.PowerShell
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential

The credential to use when creating the compatibility session using the target machine/configuration

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Full

If specified, the complete deserialized module object will be returned instead of the abbreviated form returned by default.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name

Pattern to filter module names by.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: *
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### System.Management.Automation.PSObject

## NOTES

## RELATED LINKS
