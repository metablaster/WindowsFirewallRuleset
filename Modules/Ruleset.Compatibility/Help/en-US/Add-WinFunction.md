---
external help file: WindowsCompatibility-help.xml
Module Name: WindowsCompatibility
online version:
schema: 2.0.0
---

# Add-WinFunction

## SYNOPSIS

This command defines a global function that always runs in the compatibility session.

## SYNTAX

```
Add-WinFunction [-Name] <String> [-ScriptBlock] <ScriptBlock> [-ComputerName <String>]
 [-ConfigurationName <String>] [-Credential <PSCredential>] [<CommonParameters>]
```

## DESCRIPTION

This command defines a global function that always runs in the compatibility session,
returning serialized data to the calling session.
Parameters can be specified using the 'param' statement but only positional parameters are supported.

By default, when executing, the current compatibility session is used,
or, in the case where there is no existing session, a new default session will be created.
This behavior can be overridden using the additional parameters on the command.

## EXAMPLES

### EXAMPLE 1

```powershell
Add-WinFunction myFunction {param ($n) "Hi $n!"; $PSVersionTable.PSEdition }
myFunction Bill
```

```
Hi Bill!
Desktop
```

This example defines a function called 'myFunction' with 1 parameter.
When invoked it will print a message then return the PSVersion table from the compatibility session.

## PARAMETERS

### -ComputerName

If you don't want to use the default compatibility session,
use this parameter to specify the name of the computer on which to create the compatibility session.
(Defaults to 'localhost')

```yaml
Type: String
Parameter Sets: (All)
Aliases: Cn

Required: False
Position: Named
Default value: localhost
Accept pipeline input: False
Accept wildcard characters: False
```

### -ConfigurationName

Specifies the configuration to connect to when creating the compatibility session.
(Defaults to 'Microsoft.PowerShell')

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 'Microsoft.PowerShell
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential

The credential to use when creating the compatibility session
using the target machine/configuration

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

### -Name

The name of the function to define.

```yaml
Type: String
Parameter Sets: (All)
Aliases: FunctionName

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ScriptBlock

ScriptBlock to use as the body of the function.

```yaml
Type: ScriptBlock
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### System.Void

## NOTES

## RELATED LINKS
