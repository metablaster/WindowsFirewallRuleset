---
external help file: Ruleset.ProgramInfo-help.xml
Module Name: Ruleset.ProgramInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Get-AppCapability.md
schema: 2.0.0
---

# Get-AppCapability

## SYNOPSIS

Get Windows store app capabilities

## SYNTAX

```powershell
Get-AppCapability [-InputObject] <Object[]> [-User <String>] [-Authority] [-Networking] [<CommonParameters>]
```

## DESCRIPTION

Get-AppCapability returns a list of capabilities for an app in one of the following formats:
1.
Principal display name
2.
Principal full reference name

## EXAMPLES

### EXAMPLE 1

```powershell
Get-AppxPackage -Name "*ZuneMusic*" | Get-AppCapability
```

Your Internet connection
Your home or work networks
Your music library
Removable storage

### EXAMPLE 2

```powershell
Get-AppCapability -Authority -InputObject (Get-AppxPackage -Name "*ZuneMusic*") -Networking
```

APPLICATION PACKAGE AUTHORITY\Your Internet connection
APPLICATION PACKAGE AUTHORITY\Your home or work networks

## PARAMETERS

### -InputObject

One or more Windows store apps for which to retrieve capabilities

```yaml
Type: System.Object[]
Parameter Sets: (All)
Aliases: App, StoreApp

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -User

Specify user name for which to query app capabilities, this parameter
is required only if input app is not obtained from the main store

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Authority

If specified, outputs full reference name.
By default only capability display name is returned.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Networking

If specified, the result includes only networking capabilities

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [object[]] Deserialized object on PowerShell Core 7.1+, otherwise

### [Microsoft.Windows.Appx.PackageManager.Commands.AppxPackage[]]

## OUTPUTS

### [string] Capability names or full reference names for capabilities of an app

## NOTES

TODO: According to unit test there are some capabilities not implemented here
TODO: Need better descriptive parameter name for -Authority switch

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Get-AppCapability.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Get-AppCapability.md)

[https://docs.microsoft.com/en-us/windows/uwp/packaging/app-capability-declarations](https://docs.microsoft.com/en-us/windows/uwp/packaging/app-capability-declarations)

[https://docs.microsoft.com/en-us/uwp/schemas/appxpackage/uapmanifestschema/generate-package-manifest](https://docs.microsoft.com/en-us/uwp/schemas/appxpackage/uapmanifestschema/generate-package-manifest)

[https://docs.microsoft.com/en-us/uwp/schemas/appxpackage/appxmanifestschema/element-capability](https://docs.microsoft.com/en-us/uwp/schemas/appxpackage/appxmanifestschema/element-capability)

[https://docs.microsoft.com/en-us/uwp/schemas/appxpackage/uapmanifestschema/element-capability](https://docs.microsoft.com/en-us/uwp/schemas/appxpackage/uapmanifestschema/element-capability)
