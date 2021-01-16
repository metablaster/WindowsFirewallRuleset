---
external help file: Ruleset.Compatibility-help.xml
Module Name: Ruleset.Compatibility
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Compatibility/Help/en-US/Initialize-WinSession.md
schema: 2.0.0
---

# Initialize-WinSession

## SYNOPSIS

Initialize the connection to the compatibility session

## SYNTAX

```powershell
Initialize-WinSession [[-Domain] <String>] [-ConfigurationName <String>] [-Credential <PSCredential>]
 [-PassThru] [<CommonParameters>]
```

## DESCRIPTION

Initialize the connection to the compatibility session.
By default the compatibility session will be created on the localhost using the "Microsoft.PowerShell" configuration.
On subsequent calls, if a session matching the current specification is found,
it will be returned rather than creating a new session.
If a matching session is found, but can't be used,
it will be closed and a new session will be retrieved.

This command is called by the other commands in this module so you will rarely call this command directly.

## EXAMPLES

### EXAMPLE 1

```powershell
Initialize-WinSession
```

Initialize the default compatibility session.

### EXAMPLE 2

```powershell
Initialize-WinSession -Domain localhost -ConfigurationName Microsoft.PowerShell
```

Initialize the compatibility session with a specific computer name and configuration

## PARAMETERS

### -Domain

If you don't want to use the default compatibility session, use this parameter to specify the name
of the computer on which to create the compatibility session.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases: ComputerName, CN

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ConfigurationName

Specifies the configuration to connect to when creating the compatibility session
(Defaults to "Microsoft.PowerShell")

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential

The credential to use when connecting to the target machine/configuration

```yaml
Type: System.Management.Automation.PSCredential
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PassThru

If present, the specified session object will be returned

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

### None. You cannot pipe objects to Initialize-WinSession

## OUTPUTS

### [System.Management.Automation.Runspaces.PSSession]

## NOTES

Following modifications by metablaster November 2020:

- Added comment based help based on original comments
- Code formatting according to the rest of project design
- Added HelpURI link to project location

January 2021:

- Added parameter debugging stream

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Compatibility/Help/en-US/Initialize-WinSession.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Compatibility/Help/en-US/Initialize-WinSession.md)

[https://github.com/PowerShell/WindowsCompatibility](https://github.com/PowerShell/WindowsCompatibility)
