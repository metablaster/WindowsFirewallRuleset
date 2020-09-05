---
external help file: Project.AllPlatforms.Initialize-help.xml
Module Name: Project.AllPlatforms.Initialize
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/develop/Modules/Project.AllPlatforms.Initialize/Help/en-US/Initialize-Project.md
schema: 2.0.0
---

# Initialize-Project

## SYNOPSIS

Check system requirements for this project

## SYNTAX

### NoProject (Default)

```none
Initialize-Project [-NoProjectCheck] [<CommonParameters>]
```

### Project

```none
Initialize-Project [-NoModulesCheck] [-NoServicesCheck] [-Abort] [<CommonParameters>]
```

## DESCRIPTION

Initialize-Project is designed for "Windows Firewall Ruleset", it first prints a short watermark,
tests for OS, PowerShell version and edition, Administrator mode, .NET Framework version, checks if
required system services are started and recommended modules installed.
If not the function may exit and stop executing scripts.

## EXAMPLES

### EXAMPLE 1

```none
Initialize-Project
Performs default requirements and recommendations checks managed by global settings,
Error or warning message is shown if check failed, environment info otherwise.
```

### EXAMPLE 2

```none
Initialize-Project -NoModulesCheck
Performs default requirements and recommendations checks managed by global settings,
except installed modules are not validated.
Error or warning message is shown if check failed, environment info otherwise.
```

## PARAMETERS

### -NoProjectCheck

If supplied, checking for project requirements and recommendations will not be performed,
This is equivalent to function that does nothing.
Note that this parameter is managed by project settings

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: NoProject
Aliases:

Required: False
Position: Named
Default value: !$ProjectCheck
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoModulesCheck

If supplied, checking for required and recommended module updates will not be performed.
Note that this parameter is managed by project settings

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: Project
Aliases:

Required: False
Position: Named
Default value: !$ModulesCheck
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoServicesCheck

If supplied, checking if required system services are running will not be performed.
Note that this parameter is managed by project settings

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: Project
Aliases:

Required: False
Position: Named
Default value: !$ServicesCheck
Accept pipeline input: False
Accept wildcard characters: False
```

### -Abort

If specified exit is called on failure instead of return

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: Project
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

### None. You cannot pipe objects to Initialize-Project

## OUTPUTS

### None.

## NOTES

This function main purpose is automated development environment setup to be able to perform quick
setup on multiple computers and virtual operating systems, in cases such as frequent system restores
for the purpose of testing project code for many environment scenarios that end users may have.
It should be used in conjunction with the rest of a module "Project.AllPlatforms.Initialize"

TODO: learn repo dir automatically (using git?)
TODO: we don't use logs in this module
TODO: checking remote systems not implemented
TODO: Any modules in standard user paths will override system wide modules

## RELATED LINKS

