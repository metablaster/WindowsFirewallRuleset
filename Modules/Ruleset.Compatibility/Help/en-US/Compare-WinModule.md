---
external help file: Ruleset.Compatibility-help.xml
Module Name: Ruleset.Compatibility
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Compatibility/Help/en-US/Compare-WinModule.md
schema: 2.0.0
---

# Compare-WinModule

## SYNOPSIS

Compare the set of modules against those in the compatibility session

## SYNTAX

```powershell
Compare-WinModule [[-Name] <String[]>] [-Domain <String>] [-ConfigurationName <String>]
 [-Credential <PSCredential>] [<CommonParameters>]
```

## DESCRIPTION

Compare the set of modules for this version of PowerShell against those available
in the compatibility session.

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

This will return a list of all of the compatibility session modules matching the wildcard pattern "A*".

## PARAMETERS

### -Name

Specifies the names or name patterns of for the modules to compare.
Wildcard characters are supported.

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: *
Accept pipeline input: False
Accept wildcard characters: True
```

### -Domain

If you don't want to use the default compatibility session, use this parameter to
specify the name of the computer on which to create the compatibility session.

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

If needed, use this parameter to specify credentials for the compatibility session

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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You cannot pipe objects to Compare-WinModule

## OUTPUTS

### [PSObject]

## NOTES

The Following modifications by metablaster November 2020:

- Added comment based help based on original comments
- Code formatting according to the rest of project design
- Added HelpURI link to project location

January 2021:

- Added parameter debugging stream

December 2022:

- Change OutputType to System.Management.Automation.PSCustomObject from PSObject

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Compatibility/Help/en-US/Compare-WinModule.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Compatibility/Help/en-US/Compare-WinModule.md)

[https://github.com/PowerShell/WindowsCompatibility](https://github.com/PowerShell/WindowsCompatibility)
