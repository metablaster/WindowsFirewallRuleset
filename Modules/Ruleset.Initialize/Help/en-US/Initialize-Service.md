---
external help file: Ruleset.Initialize-help.xml
Module Name: Ruleset.Initialize
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Initialize/Help/en-US/Initialize-Service.md
schema: 2.0.0
---

# Initialize-Service

## SYNOPSIS

Check if required system services are started

## SYNTAX

```none
Initialize-Service [-Services] <String[]> [<CommonParameters>]
```

## DESCRIPTION

Test if required system services are started, if not all services on which target service depends
are started before starting requested service and setting it to automatic startup.
Some services are essential for correct firewall and network functioning,
without essential services project code may result in errors hard to debug

## EXAMPLES

### EXAMPLE 1

```none
Initialize-Service @("lmhosts", "LanmanWorkstation", "LanmanServer")
$true if all input services are started successfully $false otherwise
```

### EXAMPLE 2

```none
Initialize-Service "WinRM"
$true if WinRM service was started $false otherwise
```

## PARAMETERS

### -Services

An array of services to start

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [string[]] One or more service short names to check

## OUTPUTS

### [bool]

## NOTES

This function main purpose is automated development environment setup to be able to perform quick
setup on multiple computers and virtual operating systems, in cases such as frequent system restores
for the purpose of testing project code for many environment scenarios that end users may have.
It should be used in conjunction with the rest of a module "Ruleset.Initialize"

\[System.ServiceProcess.ServiceController\[\]\]

## RELATED LINKS
