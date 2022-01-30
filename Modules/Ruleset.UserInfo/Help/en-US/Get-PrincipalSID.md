---
external help file: Ruleset.UserInfo-help.xml
Module Name: Ruleset.UserInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.UserInfo/Help/en-US/Get-PrincipalSID.md
schema: 2.0.0
---

# Get-PrincipalSID

## SYNOPSIS

Get SID for specified user account

## SYNTAX

```powershell
Get-PrincipalSID [-User] <String[]> [-Domain <String>] [-CIM] [<CommonParameters>]
```

## DESCRIPTION

Get SID's for single or multiple user names on a target computer

## EXAMPLES

### EXAMPLE 1

```powershell
Get-PrincipalSID "User" -Server "Server01"
```

### EXAMPLE 2

```powershell
Get-PrincipalSID @("USERNAME1", "USERNAME2") -CIM
```

## PARAMETERS

### -User

One or more user names

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases: UserName

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Domain

Target computer on which to perform query

```yaml
Type: System.String
Parameter Sets: (All)
Aliases: ComputerName, CN

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

### [string[]] One or more user names

## OUTPUTS

### [string] SID's (security identifiers)

## NOTES

None.

## RELATED LINKS
