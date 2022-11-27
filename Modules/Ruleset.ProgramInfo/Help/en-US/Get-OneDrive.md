---
external help file: Ruleset.ProgramInfo-help.xml
Module Name: Ruleset.ProgramInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Get-OneDrive.md
schema: 2.0.0
---

# Get-OneDrive

## SYNOPSIS

Get One Drive information for specific user

## SYNTAX

### Domain (Default)

```powershell
Get-OneDrive [-User] <String> [-Domain <String>] [-Credential <PSCredential>] [<CommonParameters>]
```

### Session

```powershell
Get-OneDrive [-User] <String> [-CimSession <CimSession>] [-Session <PSSession>] [<CommonParameters>]
```

## DESCRIPTION

Search installed One Drive instance in userprofile for specific user account

## EXAMPLES

### EXAMPLE 1

```powershell
Get-OneDrive "USERNAME"
```

### EXAMPLE 2

```powershell
Get-OneDrive "USERNAME" -Domain "Server01"
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
Parameter Sets: Domain
Aliases: ComputerName, CN

Required: False
Position: Named
Default value: [System.Environment]::MachineName
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential

Specifies the credential object to use for authentication

```yaml
Type: System.Management.Automation.PSCredential
Parameter Sets: Domain
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CimSession

Specifies the CIM session to use

```yaml
Type: Microsoft.Management.Infrastructure.CimSession
Parameter Sets: Session
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Session

Specifies the PS session to use

```yaml
Type: System.Management.Automation.Runspaces.PSSession
Parameter Sets: Session
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

### None. You cannot pipe objects to Get-OneDrive

## OUTPUTS

### [PSCustomObject] OneDrive program info for specified user on a target computer

## NOTES

TODO: We should make a query for an array of users, will help to save into variable,
this is duplicate comment of Get-UserSoftware
TODO: The logic of this function should probably be part of Get-UserSoftware, it is unknown
if OneDrive can be installed for all users too.

## RELATED LINKS
