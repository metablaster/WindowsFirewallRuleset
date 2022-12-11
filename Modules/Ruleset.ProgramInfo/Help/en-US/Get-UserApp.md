---
external help file: Ruleset.ProgramInfo-help.xml
Module Name: Ruleset.ProgramInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Get-UserApp.md
schema: 2.0.0
---

# Get-UserApp

## SYNOPSIS

Get store apps for specific user

## SYNTAX

### Domain (Default)

```powershell
Get-UserApp [[-Name] <String>] -User <String> [-Domain <String>] [-Credential <PSCredential>]
 [<CommonParameters>]
```

### Session

```powershell
Get-UserApp [[-Name] <String>] -User <String> [-Session <PSSession>] [<CommonParameters>]
```

## DESCRIPTION

Search installed store apps in userprofile for specific user account

## EXAMPLES

### EXAMPLE 1

```powershell
Get-UserApp "User" -Domain "Server01"
```

### EXAMPLE 2

```powershell
Get-UserApp "Administrator"
```

## PARAMETERS

### -Name

Specifies the name of a particular package.
If specified, function returns results for this package only.
Wildcards are permitted.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: *
Accept pipeline input: False
Accept wildcard characters: True
```

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
Position: Named
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

### None. You cannot pipe objects to Get-UserApp

## OUTPUTS

### [Microsoft.Windows.Appx.PackageManager.Commands.AppxPackage] store app information object

### [object] if using PowerShell Core which outputs deserialized object

### [Deserialized.Microsoft.Windows.Appx.PackageManager.Commands.AppxPackage]

## NOTES

TODO: We should probably return custom object to be able to pipe to functions such as Get-AppSID
TODO: See also -AllUsers and other parameters in related links
TODO: Format.ps1xml not applied in Windows PowerShell

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Get-UserApp.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Get-UserApp.md)

[https://docs.microsoft.com/en-us/powershell/module/appx/get-appxpackage](https://docs.microsoft.com/en-us/powershell/module/appx/get-appxpackage)
