---
external help file: Project.Windows.ProgramInfo-help.xml
Module Name: Project.Windows.ProgramInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/develop/Modules/Project.Windows.ProgramInfo/Help/en-US/Get-UserApps.md
schema: 2.0.0
---

# Get-UserApps

## SYNOPSIS

Get store apps for specific user

## SYNTAX

```none
Get-UserApps [-UserName] <String> [[-ComputerName] <String>] [<CommonParameters>]
```

## DESCRIPTION

Search installed store apps in userprofile for specific user account

## EXAMPLES

### EXAMPLE 1

```none
Get-UserApps "USERNAME"
```

## PARAMETERS

### -UserName

User name in form of:
- domain\user_name
- user_name@fqn.domain.tld
- user_name
- SID-string

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

### None. You cannot pipe objects to Get-UserApps

## OUTPUTS

### [Microsoft.Windows.Appx.PackageManager.Commands.AppxPackage] store app information object

## NOTES

TODO: query remote computer not implemented
TODO: multiple computers
TODO: we should probably return custom object to be able to pipe to functions such as Get-AppSID
TODO: see also -AllUsers and other parameters
https://docs.microsoft.com/en-us/powershell/module/appx/get-appxpackage?view=win10-ps

## RELATED LINKS

