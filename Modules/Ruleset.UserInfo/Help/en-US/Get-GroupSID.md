---
external help file: Ruleset.UserInfo-help.xml
Module Name: Ruleset.UserInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.UserInfo/Help/en-US/Get-GroupSID.md
schema: 2.0.0
---

# Get-GroupSID

## SYNOPSIS

Get SID of user groups on local or remote computers

## SYNTAX

### Domain (Default)

```powershell
Get-GroupSID [-Group] <String[]> [-Domain <String>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### CimSession

```powershell
Get-GroupSID [-Group] <String[]> [-CimSession <CimSession>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION

Get SID's for single or multiple user groups on a target computer

## EXAMPLES

### EXAMPLE 1

```powershell
Get-GroupSID "USERNAME" -Domain "COMPUTERNAME"
```

### EXAMPLE 2

```powershell
Get-GroupSID @("USERNAME1", "USERNAME2")
```

### EXAMPLE 3

```powershell
Get-GroupSID "USERNAME" -CimSession (New-CimSession)
```

## PARAMETERS

### -Group

Array of user groups or single group name

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases: UserGroup

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Domain

Computer name which to query for group users

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

### -ProgressAction

{{ Fill ProgressAction Description }}

```yaml
Type: System.Management.Automation.ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [string[]] One or more group names

## OUTPUTS

### [PSCustomObject]

## NOTES

None.

## RELATED LINKS
