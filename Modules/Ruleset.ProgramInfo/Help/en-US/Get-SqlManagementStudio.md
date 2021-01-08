---
external help file: Ruleset.ProgramInfo-help.xml
Module Name: Ruleset.ProgramInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Get-SqlManagementStudio.md
schema: 2.0.0
---

# Get-SqlManagementStudio

## SYNOPSIS

Get installed Microsoft SQL Server Management Studios

## SYNTAX

```powershell
Get-SqlManagementStudio [[-Domain] <String>] [<CommonParameters>]
```

## DESCRIPTION

Get all instances of installed Microsoft SQL Server Management Studios from local
or remote machine.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-SqlManagementStudio SERVER01
```

Domain       Name                                       InstallLocation
------       ----                                       ---------------
SERVER01     Microsoft SQL Server Management Studio     %ProgramFiles(x86)%\Microsoft SQL Server Management Studio 18

## PARAMETERS

### -Domain

Computer name for which to list installed installed framework

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

### None. You cannot pipe objects to Get-SqlManagementStudio

## OUTPUTS

### [PSCustomObject] for installed Microsoft SQL Server Management Studio's

## NOTES

None.

## RELATED LINKS
