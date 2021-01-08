---
external help file: Ruleset.ProgramInfo-help.xml
Module Name: Ruleset.ProgramInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Get-UserApps.md
schema: 2.0.0
---

# Get-UserApps

## SYNOPSIS

Get store apps for specific user

## SYNTAX

```powershell
Get-UserApps [-User] <String> [[-Domain] <String>] [<CommonParameters>]
```

## DESCRIPTION

Search installed store apps in userprofile for specific user account

## EXAMPLES

### EXAMPLE 1

```powershell
Get-UserApps "User" -Domain "Server01"
```

### EXAMPLE 2

```powershell
Get-UserApps "Administrator"
```

## PARAMETERS

### -User

User name in form of:

- domain\user_name
- user_name@fqn.domain.tld
- user_name
- SID-string

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

### None. You cannot pipe objects to Get-UserApps

## OUTPUTS

### [Microsoft.Windows.Appx.PackageManager.Commands.AppxPackage] store app information object

### [object] if using PowerShell Core which outputs deserialized object:

### [Deserialized.Microsoft.Windows.Appx.PackageManager.Commands.AppxPackage]

## NOTES

TODO: query remote computer not implemented
TODO: multiple domains
TODO: we should probably return custom object to be able to pipe to functions such as Get-AppSID
TODO: see also -AllUsers and other parameters in related links

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Get-UserApps.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Get-UserApps.md)

[https://docs.microsoft.com/en-us/powershell/module/appx/get-appxpackage?view=win10-ps](https://docs.microsoft.com/en-us/powershell/module/appx/get-appxpackage?view=win10-ps)
