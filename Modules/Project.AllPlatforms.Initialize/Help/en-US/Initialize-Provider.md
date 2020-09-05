---
external help file: Project.AllPlatforms.Initialize-help.xml
Module Name: Project.AllPlatforms.Initialize
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/develop/Modules/Project.AllPlatforms.Initialize/Help/en-US/Initialize-Provider.md
schema: 2.0.0
---

# Initialize-Provider

## SYNOPSIS

Test if recommended packages are installed

## SYNTAX

```none
Initialize-Provider [-FullyQualifiedName] <Hashtable> [-Name <String>] [-Location <Uri>] [-Trusted]
 [-InfoMessage <String>] [-Required] [<CommonParameters>]
```

## DESCRIPTION

Test if recommended and up to date packages are installed, if not user is
prompted to install or update them.
Outdated or missing packages can cause strange issues, this function ensures latest packages are
installed and in correct order, taking into account failures that can happen while
installing or updating packages

## EXAMPLES

### EXAMPLE 1

```none
Initialize-Provider @{ ModuleName = "PackageManagement"; ModuleVersion = "1.4.7" } -Repository "powershellgallery.com"
```

## PARAMETERS

### -FullyQualifiedName

Hash table ProviderName, Version representing minimum required module

```yaml
Type: System.Collections.Hashtable
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name

Package source name which to assign to registered provider if registration is needed

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Nuget.org
Accept pipeline input: False
Accept wildcard characters: False
```

### -Location

Repository name from which to download packages such as NuGet,
if repository is not registered user is prompted to register it

```yaml
Type: System.Uri
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Https://api.nuget.org/v3/index.json
Accept pipeline input: False
Accept wildcard characters: False
```

### -Trusted

If the supplied repository needs to be registered Trusted specifies
whether repository is trusted or not.
this parameter is used only if repository is not registered

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

Controls whether the provider initialization must succeed, if initialization fails execution stops,
otherwise only warning is generated

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

### None.

## NOTES

This function main purpose is automated development environment setup to be able to perform quick
setup on multiple computers and virtual operating systems, in cases such as frequent system restores
for the purpose of testing project code for many environment scenarios that end users may have.
It should be used in conjunction with the rest of a module "Project.AllPlatforms.Initialize"

There is no "Repository" parameter here like in Initialize-Module, instead it's called ProviderName
which is supplied in parameter FullyQualifiedName
Before updating PowerShellGet or PackageManagement, you should always install the latest Nuget provider

## RELATED LINKS

