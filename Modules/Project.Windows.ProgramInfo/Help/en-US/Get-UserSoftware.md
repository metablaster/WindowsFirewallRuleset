---
external help file: Project.Windows.ProgramInfo-help.xml
Module Name: Project.Windows.ProgramInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/develop/Modules/Project.Windows.ProgramInfo/Help/en-US/Get-UserSoftware.md
schema: 2.0.0
---

# Get-UserSoftware

## SYNOPSIS

Get a list of programs installed by specific user

## SYNTAX

```none
Get-UserSoftware [-UserName] <String> [[-ComputerName] <String>] [<CommonParameters>]
```

## DESCRIPTION

Search installed programs in userprofile for specific user account

## EXAMPLES

### EXAMPLE 1

```none
Get-UserSoftware "USERNAME"
```

## PARAMETERS

### -UserName

User name in form of "USERNAME"

```yaml
Type: System.String
Parameter Sets: (All)
Aliases: User

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ComputerName

NETBIOS Computer name in form of "COMPUTERNAME"

```yaml
Type: System.String
Parameter Sets: (All)
Aliases: Computer, Server, Domain, Host, Machine

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

### [PSCustomObject[]] list of programs for specified user on a target computer

## NOTES

TODO: We should make a query for an array of users, will help to save into variable

## RELATED LINKS
