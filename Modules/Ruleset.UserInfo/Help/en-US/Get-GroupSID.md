---
external help file: Ruleset.UserInfo-help.xml
Module Name: Ruleset.UserInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.UserInfo/Help/en-US/Get-GroupSID.md
schema: 2.0.0
---

# Get-GroupSID

## SYNOPSIS

Get SID of user groups for given computer

## SYNTAX

```powershell
Get-GroupSID [-UserGroups] <String[]> [-ComputerName <String>] [-CIM] [<CommonParameters>]
```

## DESCRIPTION

Get SID's for single or multiple user groups on a target computer

## EXAMPLES

### EXAMPLE 1

```powershell
Get-GroupSID "USERNAME" -Machine "COMPUTERNAME"
```

### EXAMPLE 2

```powershell
Get-GroupSID @("USERNAME1", "USERNAME2") -CIM
```

## PARAMETERS

### -UserGroups

Array of user groups or single group name

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases: Group

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -ComputerName

Computer name which to query for group users

```yaml
Type: System.String
Parameter Sets: (All)
Aliases: Computer, Server, Domain, Host, Machine

Required: False
Position: Named
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

### [string[]] One or more group names

## OUTPUTS

### [string] SID's (security identifiers)

## NOTES

CIM switch is not supported on PowerShell Core, meaning contacting remote computers
is supported only on Windows PowerShell
TODO: plural parameter

## RELATED LINKS
