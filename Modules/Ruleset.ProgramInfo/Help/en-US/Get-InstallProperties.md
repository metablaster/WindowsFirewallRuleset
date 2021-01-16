---
external help file: Ruleset.ProgramInfo-help.xml
Module Name: Ruleset.ProgramInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Get-InstallProperties.md
schema: 2.0.0
---

# Get-InstallProperties

## SYNOPSIS

Search system wide program install properties

## SYNTAX

```powershell
Get-InstallProperties [[-Domain] <String>] [<CommonParameters>]
```

## DESCRIPTION

Search separate location in the registry for programs installed for all users.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-InstallProperties
```

### EXAMPLE 2

```powershell
Get-InstallProperties "COMPUTERNAME"
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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You cannot pipe objects to Get-InstallProperties

## OUTPUTS

### [PSCustomObject] list of programs installed for all users

## NOTES

TODO: Should be renamed to something that best describes target registry key

## RELATED LINKS
