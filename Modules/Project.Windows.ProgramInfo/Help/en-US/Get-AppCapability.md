---
external help file: Project.Windows.ProgramInfo-help.xml
Module Name: Project.Windows.ProgramInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/develop/Modules/Project.Windows.ProgramInfo/Help/en-US/Get-AppCapability.md
schema: 2.0.0
---

# Get-AppCapability

## SYNOPSIS

Get capabilities of Windows store app

## SYNTAX

```none
Get-AppCapability [-InputObject] <AppxPackage[]> [-User <String>] [-Authority] [-Networking]
 [<CommonParameters>]
```

## DESCRIPTION

Get-AppCapability returns a list of capabilities for an app in one of the following formats:
2.
Account display name
3.
Account full reference name

## EXAMPLES

### EXAMPLE 1

```none
Get-AppxPackage -Name "*ZuneMusic*" | Get-AppCapability
```

Your Internet connection
Your home or work networks
Your music library
Removable storage

### EXAMPLE 2

```none
Get-AppCapability -Authority -InputObject (Get-AppxPackage -Name "*ZuneMusic*") -Networking
```

APPLICATION PACKAGE AUTHORITY\Your Internet connection
APPLICATION PACKAGE AUTHORITY\Your home or work networks

## PARAMETERS

### -InputObject

One or more Windows store apps for which to retrieve capabilities

```yaml
Type: Microsoft.Windows.Appx.PackageManager.Commands.AppxPackage[]
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
is required only if input app is not obtained from main store

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

If specified outputs full reference name

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

If specified the result includes only networking capabilities

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

### [Microsoft.Windows.Appx.PackageManager.Commands.AppxPackage[]]

## OUTPUTS

### [string[]] Capability names or full reference names for capabilities of an app

## NOTES

None.

## RELATED LINKS

[https://docs.microsoft.com/en-us/windows/uwp/packaging/app-capability-declarations](https://docs.microsoft.com/en-us/windows/uwp/packaging/app-capability-declarations)

[https://docs.microsoft.com/en-us/uwp/schemas/appxpackage/uapmanifestschema/generate-package-manifest](https://docs.microsoft.com/en-us/uwp/schemas/appxpackage/uapmanifestschema/generate-package-manifest)



