---
external help file: Project.Windows.ProgramInfo-help.xml
Module Name: Project.Windows.ProgramInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/develop/Modules/Project.Windows.ProgramInfo/Help/en-US/Get-OneDrive.md
schema: 2.0.0
---

# Get-OneDrive

## SYNOPSIS

Get One Drive information for specific user

## SYNTAX

```none
Get-OneDrive [-UserName] <String> [[-ComputerName] <String>] [<CommonParameters>]
```

## DESCRIPTION

Search installed One Drive instance in userprofile for specific user account

## EXAMPLES

### EXAMPLE 1

```none
Get-OneDrive "USERNAME"
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

### [PSCustomObject[]] One Drive program info for specified user on a target computer

## NOTES

TODO: We should make a query for an array of users, will help to save into variable,
this is duplicate comment of Get-UserSoftware
TODO: The logic of this function should probably be part of Get-UserSoftware, it is unknown
if OneDrive can be installed for all users too.

## RELATED LINKS

