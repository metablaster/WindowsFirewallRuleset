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

```none
Get-SystemApps [-UserName] <String> [[-ComputerName] <String>] [<CommonParameters>]
```

## DESCRIPTION

Search system wide installed store apps

## EXAMPLES

### EXAMPLE 1

```none
Get-SystemApps "COMPUTERNAME"
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

### None. You cannot pipe objects to Get-SystemApps

## OUTPUTS

### [Microsoft.Windows.Appx.PackageManager.Commands.AppxPackage] store app information object

### [Object] if using PowerShell Core which outputs deserialized object:

### [Deserialized.Microsoft.Windows.Appx.PackageManager.Commands.AppxPackage]

## NOTES

TODO: query remote computer not implemented
TODO: multiple computers
TODO: we should probably return custom object to be able to pipe to functions such as Get-AppSID
TODO: it is possible to add -User parameter, what's the purpose?
see also StoreApps.ps1

## RELATED LINKS
