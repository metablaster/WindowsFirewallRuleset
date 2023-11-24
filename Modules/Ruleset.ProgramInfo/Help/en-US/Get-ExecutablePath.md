---
external help file: Ruleset.ProgramInfo-help.xml
Module Name: Ruleset.ProgramInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Get-ExecutablePath.md
schema: 2.0.0
---

# Get-ExecutablePath

## SYNOPSIS

Get a list of install locations for executable files

## SYNTAX

```powershell
Get-ExecutablePath [[-Domain] <String>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION

Returns a table of installed programs, with executable name, installation path,
registry path and child registry key name for target computer

## EXAMPLES

### EXAMPLE 1

```powershell
Get-ExecutablePath
```

### EXAMPLE 2

```powershell
Get-ExecutablePath "COMPUTERNAME"
```

## PARAMETERS

### -Domain

Computer name which to check

```yaml
Type: System.String
Parameter Sets: (All)
Aliases: ComputerName, CN

Required: False
Position: 1
Default value: [System.Environment]::MachineName
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProgressAction

{{ Fill ProgressAction Description }}

```yaml
Type: System.Management.Automation.ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You cannot pipe objects to Get-ExecutablePath

## OUTPUTS

### [PSCustomObject] list of executables, their installation path and additional information

## NOTES

TODO: Name parameter accepting wildcard, why not getting specifics out?

## RELATED LINKS
