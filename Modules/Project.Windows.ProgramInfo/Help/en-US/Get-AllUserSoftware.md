---
external help file: Project.Windows.ProgramInfo-help.xml
Module Name: Project.Windows.ProgramInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Project.Windows.ProgramInfo/Help/en-US/Get-AllUserSoftware.md
schema: 2.0.0
---

# Get-AllUserSoftware

## SYNOPSIS

Search program install properties for all users, system wide

## SYNTAX

```none
Get-AllUserSoftware [[-ComputerName] <String>] [<CommonParameters>]
```

## DESCRIPTION

TODO: add description

## EXAMPLES

### EXAMPLE 1

```none
Get-AllUserSoftware "COMPUTERNAME"
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

### None. You cannot pipe objects to Get-AllUserSoftware

## OUTPUTS

### [PSCustomObject[]] list of programs installed for all users

## NOTES

TODO: should be renamed into Get-InstallProperties

## RELATED LINKS
