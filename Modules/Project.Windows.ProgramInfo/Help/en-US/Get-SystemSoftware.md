---
external help file: Project.Windows.ProgramInfo-help.xml
Module Name: Project.Windows.ProgramInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/develop/Modules/Project.Windows.ProgramInfo/Help/en-US/Get-SystemSoftware.md
schema: 2.0.0
---

# Get-SystemSoftware

## SYNOPSIS
Search installed programs for all users, system wide

## SYNTAX

```
Get-SystemSoftware [[-ComputerName] <String>] [<CommonParameters>]
```

## DESCRIPTION
TODO: add description

## EXAMPLES

### EXAMPLE 1
```
Get-SystemSoftware "COMPUTERNAME"
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

### None. You cannot pipe objects to Get-SystemSoftware
## OUTPUTS

### [PSCustomObject[]] list of programs installed for all users
## NOTES
We should return empty PSCustomObject if test computer fails

## RELATED LINKS
