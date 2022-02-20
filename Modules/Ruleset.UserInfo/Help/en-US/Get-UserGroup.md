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

### Domain (Default)

```powershell
Get-UserGroup [-Domain <String[]>] [<CommonParameters>]
```

### CimSession

```powershell
Get-UserGroup [-CimSession <CimSession>] [<CommonParameters>]
```

## DESCRIPTION

Get a list of all available user groups on target computers

## EXAMPLES

### EXAMPLE 1

```powershell
Get-UserGroup "ServerPC"
```

### EXAMPLE 2

```powershell
Get-UserGroup @(DESKTOP, LAPTOP)
```

### EXAMPLE 3

```powershell
Get-UserGroup -CimSession (New-CimSession)
```

## PARAMETERS

### -Domain

One or more computers which to query for user groups

```yaml
Type: System.String[]
Parameter Sets: Domain
Aliases: ComputerName, CN

Required: False
Position: Named
Default value: [System.Environment]::MachineName
Accept pipeline input: False
Accept wildcard characters: False
```

### -CimSession

Specifies the CIM session to use

```yaml
Type: Microsoft.Management.Infrastructure.CimSession
Parameter Sets: CimSession
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

### None. You cannot pipe objects to Get-UserGroup

## OUTPUTS

### [PSCustomObject] User groups on target computers

## NOTES

None.

## RELATED LINKS
