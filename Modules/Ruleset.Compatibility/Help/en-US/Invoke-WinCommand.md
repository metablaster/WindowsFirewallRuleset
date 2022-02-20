---
external help file: Ruleset.Compatibility-help.xml
Module Name: Ruleset.Compatibility
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Compatibility/Help/en-US/Invoke-WinCommand.md
schema: 2.0.0
---

# Invoke-WinCommand

## SYNOPSIS

Invoke a ScriptBlock that runs in the compatibility runspace

## SYNTAX

```powershell
Invoke-WinCommand [-ScriptBlock] <ScriptBlock> [-Domain <String>] [-ConfigurationName <String>]
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
Invoke-WinCommand { param ($name) "Hello $name, how are you?"; $PSVersionTable.PSVersion } Jeffrey
```

Hello Jeffrey, how are you?
Major  Minor  Build  Revision PSComputerName
-----  -----  -----  -------- --------------
5      1      17134  1        localhost

In this example, we're invoking a ScriptBlock with 1 parameter in the compatibility session.
This ScriptBlock will simply print a message and then return the version number of the compatibility session.

### EXAMPLE 2

```powershell
Invoke-WinCommand {Get-EventLog -Log Application -New 10 }
```

This examples invokes Get-EventLog in the compatibility session,
returning the 10 newest events in the application log.

## PARAMETERS

### -ScriptBlock

The scriptblock to invoke in the compatibility session

```yaml
Type: System.Management.Automation.ScriptBlock
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Domain

If you don't want to use the default compatibility session, use this parameter to specify the name
of the computer on which to create the compatibility session.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases: ComputerName, CN

Required: False
Position: Named
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

The credential to use when connecting to the compatibility session.

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

### -ArgumentList

Arguments to pass to the scriptblock

```yaml
Type: System.Object[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You cannot pipe objects to Invoke-WinCommand

## OUTPUTS

### [PSObject]

## NOTES

OutputType can't be declared because output may be anything

Following modifications by metablaster November 2020:

- Added comment based help based on original comments
- Code formatting according to the rest of project design
- Added HelpURI link to project location

January 2021:

- Replace cast to \[void\] with Out-Null
- Added parameter debugging stream

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Compatibility/Help/en-US/Invoke-WinCommand.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Compatibility/Help/en-US/Invoke-WinCommand.md)

[https://github.com/PowerShell/WindowsCompatibility](https://github.com/PowerShell/WindowsCompatibility)
