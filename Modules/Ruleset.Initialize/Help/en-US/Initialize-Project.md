---
external help file: Ruleset.Initialize-help.xml
Module Name: Ruleset.Initialize
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Initialize/Help/en-US/Initialize-Project.md
schema: 2.0.0
---

# Initialize-Project

## SYNOPSIS

Check system requirements for this project

## SYNTAX

```none
Initialize-Project [-Abort] [<CommonParameters>]
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

### -Abort

If specified exit is called on failure instead of return

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

### None. You cannot pipe objects to Initialize-Project

## OUTPUTS

### None. Initialize-Project does not generate any output

## NOTES

This function main purpose is automated development environment setup to be able to perform quick
setup on multiple computers and virtual operating systems, in cases such as frequent system restores
for the purpose of testing project code for many environment scenarios that end users may have.
It should be used in conjunction with the rest of a module "Ruleset.Initialize"

TODO: learn repo dir automatically (using git?)
TODO: we don't use logs in this module
TODO: checking remote systems not implemented
TODO: Any modules in standard user paths will override system wide modules

## RELATED LINKS
