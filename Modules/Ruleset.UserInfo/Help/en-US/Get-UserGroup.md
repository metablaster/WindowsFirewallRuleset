---
external help file: Ruleset.UserInfo-help.xml
Module Name: Ruleset.UserInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.UserInfo/Help/en-US/Get-UserGroup.md
schema: 2.0.0
---

# Get-UserGroup

## SYNOPSIS

Get user groups on target computers

## SYNTAX

```none
Get-UserGroup [[-ComputerNames] <String[]>] [-CIM] [<CommonParameters>]
```

## DESCRIPTION

Get a list of all available user groups on target computers

## EXAMPLES

### EXAMPLE 1

```none
Get-UserGroup "ServerPC"
```

### EXAMPLE 2

```none
Get-UserGroup @(DESKTOP, LAPTOP) -CIM
```

## PARAMETERS

### -ComputerNames

One or more computers which to query for user groups

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases: Computer, Server, Domain, Host, Machine

Required: False
Position: 1
Default value: [System.Environment]::MachineName
Accept pipeline input: False
Accept wildcard characters: False
```

### -CIM

Whether to contact CIM server (required for remote computers)

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [string[]] array of computer names

## OUTPUTS

### [PSCustomObject[]] array of user groups on target computers

## NOTES

CIM switch is not supported on PowerShell Core, meaning contacting remote computers
is supported only on Windows PowerShell

## RELATED LINKS
