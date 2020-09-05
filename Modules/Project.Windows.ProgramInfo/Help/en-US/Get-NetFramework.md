---
external help file: Project.Windows.ProgramInfo-help.xml
Module Name: Project.Windows.ProgramInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/develop/Modules/Project.Windows.ProgramInfo/Help/en-US/Get-NetFramework.md
schema: 2.0.0
---

# Get-NetFramework

## SYNOPSIS

Get installed NET Frameworks

## SYNTAX

```none
Get-NetFramework [[-ComputerName] <String>] [<CommonParameters>]
```

## DESCRIPTION

Get-NetFramework will return all NET frameworks installed regardless if
installation directory exists or not, since some versions are built in

## EXAMPLES

### EXAMPLE 1

```none
Get-NetFramework COMPUTERNAME
```

## PARAMETERS

### -ComputerName

Computer name for which to list installed installed framework

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

### None. You cannot pipe objects to Get-NetFramework

## OUTPUTS

### [PSCustomObject[]] for installed NET Frameworks and install paths

## NOTES

None.

## RELATED LINKS

