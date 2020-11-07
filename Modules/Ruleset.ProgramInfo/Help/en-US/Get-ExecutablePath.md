---
external help file: Ruleset.ProgramInfo-help.xml
Module Name: Ruleset.ProgramInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Get-ExecutablePath.md
schema: 2.0.0
---

# Get-ExecutablePath

## SYNOPSIS

Get list of install locations for executables and executable names

## SYNTAX

```none
Get-ExecutablePath [[-ComputerName] <String>] [<CommonParameters>]
```

## DESCRIPTION

Returns a table of installed programs, with executable name, installation path,
registry path and child registry key name for target computer

## EXAMPLES

### EXAMPLE 1

```none
Get-ExecutablePath "COMPUTERNAME"
```

## PARAMETERS

### -ComputerName

Computer name which to check

```yaml
Type: System.String
Parameter Sets: (All)
Aliases: Computer, Server, Domain, Host, Machine

Required: False
Position: 1
Default value: [System.Environment]::MachineName
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You cannot pipe objects to Get-ExecutablePath

## OUTPUTS

### [PSCustomObject[]] list of executables, their installation path and additional information

## NOTES

None.

## RELATED LINKS
