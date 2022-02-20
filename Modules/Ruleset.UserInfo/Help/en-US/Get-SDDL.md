---
external help file: Ruleset.UserInfo-help.xml
Module Name: Ruleset.UserInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.UserInfo/Help/en-US/Get-SDDL.md
schema: 2.0.0
---

# Get-SDDL

## SYNOPSIS

Get SDDL string of a user, group or from path

## SYNTAX

### Domain (Default)

```powershell
Get-SDDL [-User <String[]>] [-Group <String[]>] [-Domain <String>] [-Merge] [<CommonParameters>]
```

### CimSession

```powershell
Get-SDDL [-User <String[]>] [-Group <String[]>] [-CimSession <CimSession>] [-Merge] [<CommonParameters>]
```

## DESCRIPTION

Get SDDL string for single or multiple user names and/or user groups, file system or registry
locations on a single target computer

## EXAMPLES

### EXAMPLE 1

```powershell
Get-SDDL -User USERNAME -Domain COMPUTERNAME
```

### EXAMPLE 2

```powershell
Get-SDDL -Group @("Users", "Administrators") -Merge
```

### EXAMPLE 3

```powershell
Get-SDDL -Domain "NT AUTHORITY" -User "System"
```

## PARAMETERS

### -User

One or more users for which to obtain SDDL string

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases: UserName

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Group

One or more user groups for which to obtain SDDL string

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases: UserGroup

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Domain

Single domain or computer such as remote computer name or builtin computer domain

```yaml
Type: System.String
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

### -Merge

If specified, combines resultant SDDL strings into one

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

### None. You cannot pipe objects to Get-SDDL

## OUTPUTS

### [string]

## NOTES

TODO: Mandatory parameter is impossible to make

## RELATED LINKS
