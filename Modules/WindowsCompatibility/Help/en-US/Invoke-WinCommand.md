---
external help file: WindowsCompatibility-help.xml
Module Name: WindowsCompatibility
online version:
schema: 2.0.0
---

# Invoke-WinCommand

## SYNOPSIS

Invoke a ScriptBlock that runs in the compatibility runspace.

## SYNTAX

```
Invoke-WinCommand [-ScriptBlock] <ScriptBlock> [-ComputerName <String>] [-ConfigurationName <String>]
 [-Credential <PSCredential>] [-ArgumentList <Object[]>] [<CommonParameters>]
```

## DESCRIPTION

This command takes a ScriptBlock and invokes it in the compatibility session.
Parameters can be passed using the -ArgumentList parameter.

By default, when executing, the current compatibility session is used,
or, in the case where there is no existing session, a new default session will be created.
This behavior can be overridden using the additional parameters on the command.

## EXAMPLES

### EXAMPLE 1

```powershell
Invoke-WinCommand {param ($name) "Hello $name, how are you?"; $PSVersionTable.PSVersion} Jeffrey
```

```none
Hello Jeffrey, how are you?
Major  Minor  Build  Revision PSComputerName
-----  -----  -----  -------- --------------
5      1      17134  1        localhost
```

In this example, we're invoking a ScriptBlock with 1 parameter in the compatibility session.
This ScriptBlock will simply print a message and then return the version number of the compatibility session.

### EXAMPLE 2

```powershell
Invoke-WinCommand {Get-EventLog -Log Application -New 10 }
```

This examples invokes Get-EventLog in the compatibility session,
returning the 10 newest events in the application log.

## PARAMETERS

### -ArgumentList

Arguments to pass to the ScriptBlock.

```yaml
Type: Object[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

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

The credential to use when connecting to the compatibility session.

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

### -ScriptBlock

The ScriptBlock to invoke in the compatibility session.

```yaml
Type: ScriptBlock
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
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
