---
external help file: Ruleset.ProgramInfo-help.xml
Module Name: Ruleset.ProgramInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Get-SystemApps.md
schema: 2.0.0
---

# Get-SystemApps

## SYNOPSIS

Get store apps installed system wide

## SYNTAX

```powershell
Get-SystemApps [[-Name] <String>] [-User] <String> [[-Domain] <String>] [<CommonParameters>]
```

## DESCRIPTION

Search system wide installed store apps, those installed for all users or shipped with system.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-SystemApps "User" -Domain "Server01"
```

### EXAMPLE 2

```powershell
Get-SystemApps "Administrator"
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
Position: 2
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
Position: 3
Default value: [System.Environment]::MachineName
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You cannot pipe objects to Get-SystemApps

## OUTPUTS

### [Microsoft.Windows.Appx.PackageManager.Commands.AppxPackage] store app information object

### [object] In Windows PowerShell

### [Deserialized.Microsoft.Windows.Appx.PackageManager.Commands.AppxPackage] In PowerShell Core

## NOTES

TODO: Query remote computer not implemented
TODO: Multiple computers
TODO: We should probably return custom object to be able to pipe to functions such as Get-AppSID
TODO: Format.ps1xml not applied in Windows PowerShell

## RELATED LINKS
