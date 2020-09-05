---
external help file: Project.Windows.ProgramInfo-help.xml
Module Name: Project.Windows.ProgramInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/develop/Modules/Project.Windows.ProgramInfo/Help/en-US/Get-SystemApps.md
schema: 2.0.0
---

# Get-SystemApps

## SYNOPSIS

Get store apps installed system wide

## SYNTAX

```none
Get-SystemApps [[-ComputerName] <String>] [<CommonParameters>]
```

## DESCRIPTION

Search system wide installed store apps

## EXAMPLES

### EXAMPLE 1

```none
Get-SystemApps "COMPUTERNAME"
```

## PARAMETERS

### -ComputerName

NETBIOS Computer name in form of "COMPUTERNAME"

```yaml
Type: System.String
Parameter Sets: (All)
Aliases: Computer, Server, Domain, Host, Machine

Required: False
Position: 1
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

## NOTES

TODO: query remote computer not implemented
TODO: multiple computers
TODO: we should probably return custom object to be able to pipe to functions such as Get-AppSID
TODO: it is possible to add -User parameter, what's the purpose?
see also StoreApps.ps1

## RELATED LINKS

