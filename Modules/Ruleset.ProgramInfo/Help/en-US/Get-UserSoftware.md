---
external help file: Ruleset.ProgramInfo-help.xml
Module Name: Ruleset.ProgramInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Get-UserSoftware.md
schema: 2.0.0
---

# Get-UserSoftware

## SYNOPSIS

Get a list of programs installed by specific user

## SYNTAX

```powershell
Get-UserSoftware [-User] <String> [[-Domain] <String>] [<CommonParameters>]
```

## DESCRIPTION

Search installed programs in userprofile for specific user account

## EXAMPLES

### EXAMPLE 1

```powershell
Get-UserSoftware "User"
```

### EXAMPLE 2

```powershell
Get-UserSoftware "User" -Domain "Server01"
```

## PARAMETERS

### -User

User name in form of "USERNAME"

```yaml
Type: System.String
Parameter Sets: (All)
Aliases: UserName

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Domain

NETBIOS Computer name in form of "COMPUTERNAME"

```yaml
Type: System.String
Parameter Sets: (All)
Aliases: ComputerName, CN

Required: False
Position: 2
Default value: [System.Environment]::MachineName
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You cannot pipe objects to Get-UserSoftware

## OUTPUTS

### [PSCustomObject] list of programs for specified user on a target computer

## NOTES

TODO: We should make a query for an array of users, will help to save into variable

## RELATED LINKS
