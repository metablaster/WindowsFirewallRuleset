---
external help file: Project.Windows.ProgramInfo-help.xml
Module Name: Project.Windows.ProgramInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/develop/Modules/Project.Windows.ProgramInfo/Help/en-US/Get-SQLManagementStudio.md
schema: 2.0.0
---

# Get-SQLManagementStudio

## SYNOPSIS

Get installed Microsoft SQL Server Management Studios

## SYNTAX

```none
Get-SQLManagementStudio [[-ComputerName] <String>] [<CommonParameters>]
```

## DESCRIPTION

TODO: add description

## EXAMPLES

### EXAMPLE 1

```none
Get-SQLManagementStudio COMPUTERNAME
```

RegKey ComputerName Version      InstallLocation
	------ ------------ -------      -----------
	18     COMPUTERNAME   15.0.18206.0 %ProgramFiles(x86)%\Microsoft SQL Server Management Studio 18

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

### None. You cannot pipe objects to Get-SQLManagementStudio

## OUTPUTS

### [PSCustomObject[]] for installed Microsoft SQL Server Management Studio's

## NOTES

None.

## RELATED LINKS

