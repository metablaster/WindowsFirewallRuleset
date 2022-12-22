---
external help file: Ruleset.Initialize-help.xml
Module Name: Ruleset.Initialize
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Initialize/Help/en-US/Initialize-Provider.md
schema: 2.0.0
---

# Initialize-Provider

## SYNOPSIS

Update or install specified package providers

## SYNTAX

### None (Default)

```powershell
Initialize-Provider -ProviderName <String> -RequiredVersion <Version> [-InfoMessage <String>] [-Required]
 [-Scope <String>] [-Force] [<CommonParameters>]
```

### UseProvider

```powershell
Initialize-Provider -ProviderName <String> -RequiredVersion <Version> -UseProvider <String> [-Source <Uri>]
 [-InfoMessage <String>] [-Required] [-Scope <String>] [-Force] [<CommonParameters>]
```

## DESCRIPTION

Initialize-Provider tests if specified package provider is installed and is up to date,
if not user is prompted to install or update it.
Outdated or missing package providers can cause strange issues, this function ensures that
specified package provider is installed, taking into account failures which can happen while
installing or updating package providers.

## EXAMPLES

### EXAMPLE 1

```powershell
Initialize-Provider -ProviderName NuGet -RequiredVersion 2.8.5 -Required
```

### EXAMPLE 2

```powershell
Initialize-Provider -ProviderName NuGet -RequiredVersion 2.8.5 -Required `
-UseProvider NuGet -Location https://www.nuget.org/api/v2
```

## PARAMETERS

### -ProviderName

Specifies a package provider name which to install or update.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -RequiredVersion

Specifies the exact version of the package provider which to install or update.

```yaml
Type: System.Version
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UseProvider

Existing provider to use to install or update provider specified by -ProviderName parameter.
This parameter is used only if Find-PackageProvider fails, in which case Find-Package is used.
This provider is used to register package source specified by -Location if it isn't already
registered.
Acceptable values are: Bootstrap, NuGet or PowerShellGet.
The default value is PowerShellGet.

```yaml
Type: System.String
Parameter Sets: UseProvider
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Source

Specifies a web location of a package management source.

```yaml
Type: System.Uri
Parameter Sets: UseProvider
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -InfoMessage

Optional information displayable to user for choice help message

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Accept operation
Accept pipeline input: False
Accept wildcard characters: False
```

### -Required

Controls whether the provider initialization must succeed, if initialization fails execution stops
and false is returned, otherwise a warning is generated and true is returned.

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

### -Scope

Specifies the installation scope of the provider.
The acceptable values for this parameter are:

AllUsers: $env:ProgramFiles\PackageManagement\ProviderAssemblies.
CurrentUser: $env:LOCALAPPDATA\PackageManagement\ProviderAssemblies.

The default value is AllUsers.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: AllUsers
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force

{{ Fill Force Description }}

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

### None. You cannot pipe objects to Initialize-Provider

## OUTPUTS

### [bool]

## NOTES

This function main purpose is automated development environment setup to be able to perform quick
setup on multiple computers and virtual operating systems, in cases such as frequent system restores
for the purpose of testing project code for many environment scenarios that end users may have.
It should be used in conjunction with the rest of a module "Ruleset.Initialize"

TODO: -Force parameter not implemented because for most commandlets used in this function this
implies -ForceBootstrap which is not desired, few commandlets could make use of -Force

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Initialize/Help/en-US/Initialize-Provider.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Initialize/Help/en-US/Initialize-Provider.md)

[https://learn.microsoft.com/en-us/powershell/module/packagemanagement](https://learn.microsoft.com/en-us/powershell/module/packagemanagement)

[https://learn.microsoft.com/en-us/powershell/scripting/gallery/how-to/getting-support/bootstrapping-nuget](https://learn.microsoft.com/en-us/powershell/scripting/gallery/how-to/getting-support/bootstrapping-nuget)

[https://learn.microsoft.com/en-us/powershell/scripting/gallery/installing-psget](https://learn.microsoft.com/en-us/powershell/scripting/gallery/installing-psget)

[https://github.com/OneGet/oneget/issues/472](https://github.com/OneGet/oneget/issues/472)

[https://github.com/OneGet/oneget/issues/360](https://github.com/OneGet/oneget/issues/360)
