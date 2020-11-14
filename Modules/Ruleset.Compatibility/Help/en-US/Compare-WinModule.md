---
external help file: WindowsCompatibility-help.xml
Module Name: WindowsCompatibility
online version:
schema: 2.0.0
---

# Compare-WinModule

## SYNOPSIS

Compare the set of modules for this version of PowerShell against those available in the compatibility session.

## SYNTAX

```
Compare-WinModule [[-Name] <String[]>] [-ComputerName <String>] [-ConfigurationName <String>]
 [-Credential <PSCredential>] [<CommonParameters>]
```

## DESCRIPTION

Compare the set of modules for this version of PowerShell against those available in the compatibility session.

## EXAMPLES

### EXAMPLE 1

```powershell
Compare-WinModule
```

This will return a list of all of the modules available in the compatibility session
that are not currently available in the PowerShell Core environment.

### EXAMPLE 2

```powershell
Compare-WinModule A*
```

This will return a list of all of the compatibility session modules matching the wildcard pattern 'A*'.

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

Specifies the configuration to connect to when creating the compatibility session.
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

If needed, use this parameter to specify credentials for the compatibility session.

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

Specifies the names or name patterns of for the modules to compare.
Wildcard characters are permitted.

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
